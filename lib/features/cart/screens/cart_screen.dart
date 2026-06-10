import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../cart/providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    SentryService.addBreadcrumb('Carrinho visualizado', category: 'cart',
        data: {'items': items.length});

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrinho')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text('Seu carrinho está vazio', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Adicione itens para continuar', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Ver restaurantes'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final subtotal = cartNotifier.subtotal;
    final restaurantName = cartNotifier.restaurantName ?? '';
    final deliveryFee = 4.99;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        actions: [
          TextButton(
            onPressed: () {
              cartNotifier.clear();
            },
            child: Text('Limpar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(restaurantName, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CartItemTile(cartItem: item).animate().slideX(begin: -0.1, duration: 250.ms).fadeIn(),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: 'R\$ ${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Taxa de entrega',
                  value: 'R\$ ${deliveryFee.toStringAsFixed(2)}',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total',
                  value: 'R\$ ${total.toStringAsFixed(2)}',
                  bold: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/checkout'),
                  child: Text('Finalizar pedido • R\$ ${total.toStringAsFixed(2)}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.titleLarge
        : AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: bold ? AppColors.primary : null)),
      ],
    );
  }
}
