import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../cart/providers/cart_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((_) => OrderRepository());

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<Order>> {
  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  List<Order> build() => [];

  Future<Order> placeOrder({
    required String restaurantId,
    required String restaurantName,
    required List<CartItem> items,
    required double deliveryFee,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final order = await _repo.placeOrder(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: items,
      deliveryFee: deliveryFee,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
    );
    state = _repo.orders;
    ref.read(cartProvider.notifier).clear();
    return order;
  }

  Future<void> advanceStatus(String orderId) async {
    final order = _repo.orders.firstWhere((o) => o.id == orderId);
    final nextStatus = _nextStatus(order.status);
    if (nextStatus == null) return;
    await _repo.updateStatus(orderId, nextStatus);
    state = _repo.orders;
  }

  OrderStatus? _nextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.received:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.onTheWay;
      case OrderStatus.onTheWay:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }
}
