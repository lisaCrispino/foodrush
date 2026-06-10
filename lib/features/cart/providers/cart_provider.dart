import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/repositories/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((_) => CartRepository());

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

class CartNotifier extends Notifier<List<CartItem>> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  List<CartItem> build() => [];

  void add(MenuItem item, {String? restaurantName}) {
    _repo.addItem(item, restaurantName: restaurantName);
    state = List.from(_repo.items);
  }

  void remove(String itemId) {
    _repo.removeItem(itemId);
    state = List.from(_repo.items);
  }

  void decrease(String itemId) {
    _repo.decreaseItem(itemId);
    state = List.from(_repo.items);
  }

  void clear() {
    _repo.clearCart();
    state = [];
  }

  double get subtotal => _repo.subtotal;
  int get totalItems => _repo.totalItems;
  String? get restaurantId => _repo.restaurantId;
  String? get restaurantName => _repo.restaurantName;
}

final cartTotalItemsProvider = Provider<int>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartRepositoryProvider).totalItems;
});
