import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../../core/monitoring/sentry_service.dart';

class OrderRepository {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());

  Future<Order> placeOrder({
    required String restaurantId,
    required String restaurantName,
    required List<CartItem> items,
    required double deliveryFee,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final transaction =
        SentryService.startTransaction('checkout.place_order', 'task');
    final span = transaction.startChild('validate.order');

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (items.isEmpty) throw Exception('Carrinho está vazio');
      if (deliveryAddress.trim().isEmpty) throw Exception('Endereço de entrega obrigatório');

      await span.finish(status: const SpanStatus.ok());
      final saveSpan = transaction.startChild('save.order');

      final subtotal = items.fold(0.0, (s, i) => s + i.total);
      final order = Order(
        id: const Uuid().v4(),
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: subtotal + deliveryFee,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        status: OrderStatus.received,
        createdAt: DateTime.now(),
      );

      _orders.add(order);

      await saveSpan.finish(status: const SpanStatus.ok());

      SentryService.addBreadcrumb(
        'Pedido realizado',
        category: 'order',
        level: SentryLevel.info,
        data: {
          'orderId': order.id,
          'total': order.total,
          'restaurant': restaurantName,
          'items': items.length,
          'paymentMethod': paymentMethod,
        },
      );

      await transaction.finish(status: const SpanStatus.ok());
      return order;
    } catch (e, st) {
      await span.finish(status: const SpanStatus.internalError());
      await transaction.finish(status: const SpanStatus.internalError());
      await SentryService.captureException(e, stackTrace: st, hint: 'placeOrder failed');
      rethrow;
    }
  }

  Future<Order> updateStatus(String orderId, OrderStatus status) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw Exception('Pedido não encontrado');
    _orders[idx] = _orders[idx].copyWith(status: status);

    SentryService.addBreadcrumb(
      'Status do pedido atualizado',
      category: 'order',
      data: {'orderId': orderId, 'status': status.name},
    );

    return _orders[idx];
  }
}
