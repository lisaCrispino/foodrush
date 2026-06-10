import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../../data/models/order.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_stepper.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SentryService.addBreadcrumb(
      'Rastreamento de pedido aberto',
      category: 'order',
      data: {'orderId': widget.orderId},
    );
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _timer = Timer.periodic(const Duration(seconds: 6), (_) async {
      final orders = ref.read(ordersProvider);
      final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
      if (order == null) return;

      if (order.status == OrderStatus.delivered) {
        _timer?.cancel();
        return;
      }

      await ref.read(ordersProvider.notifier).advanceStatus(widget.orderId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rastreando pedido')),
        body: const Center(child: Text('Pedido não encontrado')),
      );
    }

    final isDelivered = order.status == OrderStatus.delivered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreando pedido'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text('Início', style: AppTextStyles.labelLarge),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delivery_dining, color: AppColors.white, size: 32),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(end: 1.05, duration: 800.ms),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered ? 'Pedido entregue!' : 'Pedido em andamento',
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.restaurantName,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Status do pedido', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 20),
            OrderStatusStepper(currentStatus: order.status),
            const SizedBox(height: 32),
            Text('Itens do pedido', style: AppTextStyles.headlineMedium),
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
                  ...order.items.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i.quantity}x ${i.item.name}', style: AppTextStyles.bodyLarge),
                          Text('R\$ ${i.total.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.titleLarge),
                      Text(
                        'R\$ ${order.total.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.deliveryAddress, style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
