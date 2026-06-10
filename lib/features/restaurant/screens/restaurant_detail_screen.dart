import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../../data/models/menu_item.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/menu_section.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));
    final cartCount = ref.watch(cartTotalItemsProvider);

    SentryService.addBreadcrumb(
      'Restaurante visualizado',
      category: 'navigation',
      data: {'restaurantId': restaurantId},
    );

    return Scaffold(
      body: restaurantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(child: Text('Restaurante não encontrado'));
          }

          void addToCart(MenuItem item) {
            ref.read(cartProvider.notifier).add(item, restaurantName: restaurant.name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} adicionado ao carrinho'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.secondary,
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.white,
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                            onPressed: () => context.push('/cart'),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$cartCount',
                                    style: const TextStyle(color: AppColors.white, fontSize: 9),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    restaurant.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.divider,
                      child: const Icon(Icons.restaurant, size: 80, color: AppColors.textLight),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name, style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 6),
                      Text(restaurant.description, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.star_rounded,
                            color: AppColors.warning,
                            label: restaurant.rating.toStringAsFixed(1),
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.access_time_rounded,
                            color: AppColors.primary,
                            label: restaurant.deliveryTime,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.delivery_dining,
                            color: restaurant.deliveryFee == 0 ? AppColors.success : AppColors.textSecondary,
                            label: restaurant.deliveryFee == 0
                                ? 'Grátis'
                                : 'R\$ ${restaurant.deliveryFee.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(indent: 20, endIndent: 20)),
              menuAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Erro ao carregar cardápio: $e'),
                  ),
                ),
                data: (items) {
                  final sections = <String, List<MenuItem>>{};
                  for (final item in items) {
                    sections.putIfAbsent(item.category, () => []).add(item);
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final key = sections.keys.elementAt(i);
                        return MenuSection(
                          title: key,
                          items: sections[key]!,
                          onAdd: addToCart,
                        );
                      },
                      childCount: sections.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _InfoChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
