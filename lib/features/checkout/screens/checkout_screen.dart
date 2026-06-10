import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../order/providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'Cartão de crédito';
  bool _loading = false;

  static const _paymentOptions = [
    ('Cartão de crédito', Icons.credit_card),
    ('PIX', Icons.qr_code),
    ('Dinheiro', Icons.money),
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null && user.address.isNotEmpty) {
      _addressCtrl.text = user.address;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      final items = ref.read(cartProvider);

      SentryService.addBreadcrumb(
        'Iniciando finalização de pedido',
        category: 'checkout',
        data: {
          'items': items.length,
          'payment': _paymentMethod,
          'address': _addressCtrl.text,
        },
      );

      final order = await ref.read(ordersProvider.notifier).placeOrder(
            restaurantId: cartNotifier.restaurantId!,
            restaurantName: cartNotifier.restaurantName!,
            items: items,
            deliveryFee: 4.99,
            deliveryAddress: _addressCtrl.text.trim(),
            paymentMethod: _paymentMethod,
          );

      if (!mounted) return;
      context.go('/order/${order.id}');
    } catch (e, st) {
      await SentryService.captureException(e, stackTrace: st, hint: 'checkout placeOrder failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar pedido: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    const deliveryFee = 4.99;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar pedido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Endereço de entrega', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ex: Av. Paulista, 1000 - Bela Vista, São Paulo',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o endereço de entrega';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Forma de pagamento', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            ..._paymentOptions.map(
              (opt) => RadioListTile<String>(
                value: opt.$1,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
                activeColor: AppColors.primary,
                title: Row(
                  children: [
                    Icon(opt.$2, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(opt.$1, style: AppTextStyles.bodyLarge),
                  ],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),
            Text('Resumo do pedido', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  ...items.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i.quantity}x ${i.item.name}', style: AppTextStyles.bodyMedium),
                          Text('R\$ ${i.total.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Taxa de entrega', style: AppTextStyles.bodyMedium),
                      Text('R\$ ${deliveryFee.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.titleLarge),
                      Text(
                        'R\$ ${total.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _placeOrder,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                    )
                  : Text('Confirmar pedido • R\$ ${total.toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }
}
