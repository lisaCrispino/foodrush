import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_chips.dart';
import '../widgets/restaurant_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    SentryService.addBreadcrumb('Tela inicial aberta', category: 'navigation');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final restaurantsAsync = ref.watch(homeRestaurantsProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final cartItems = ref.watch(cartTotalItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            expandedHeight: 0,
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrega em',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      user?.address.split('-').first.trim() ?? 'São Paulo, SP',
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (cartItems > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            cartItems > 9 ? '9+' : '$cartItems',
                            style: const TextStyle(color: AppColors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (q) {
                  ref.read(searchQueryProvider.notifier).state = q;
                  setState(() => _isSearching = q.isNotEmpty);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar restaurantes...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() => _isSearching = false);
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (!_isSearching) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BannerCarousel(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 12),
                child: Text('Categorias', style: AppTextStyles.headlineMedium),
              ),
            ),
            const SliverToBoxAdapter(child: CategoryChips()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 12),
                child: Text('Restaurantes', style: AppTextStyles.headlineMedium),
              ),
            ),
            restaurantsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: _ShimmerCard(),
                  ),
                  childCount: 4,
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Erro ao carregar', style: AppTextStyles.bodyMedium),
                ),
              ),
              data: (restaurants) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: RestaurantCard(
                      restaurant: restaurants[i],
                      onTap: () => context.push('/restaurant/${restaurants[i].id}'),
                    ),
                  ),
                  childCount: restaurants.length,
                ),
              ),
            ),
          ] else ...[
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            searchAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: _ShimmerCard(),
                  ),
                  childCount: 3,
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              data: (results) => results.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            Text('Nenhum resultado encontrado', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: RestaurantCard(
                            restaurant: results[i],
                            onTap: () => context.push('/restaurant/${results[i].id}'),
                          ),
                        ),
                        childCount: results.length,
                      ),
                    ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.white,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
