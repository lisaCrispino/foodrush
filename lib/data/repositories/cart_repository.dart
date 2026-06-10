import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../../core/monitoring/sentry_service.dart';

class CartRepository {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;

  double get subtotal => _items.fold(0, (sum, i) => sum + i.total);

  void addItem(MenuItem item, {String? restaurantName}) {
    if (_restaurantId != null && _restaurantId != item.restaurantId) {
      clearCart();
    }

    _restaurantId = item.restaurantId;
    if (restaurantName != null) _restaurantName = restaurantName;

    final idx = _items.indexWhere((ci) => ci.item.id == item.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    } else {
      _items.add(CartItem(item: item, quantity: 1));
    }

    SentryService.addBreadcrumb(
      'Item adicionado ao carrinho',
      category: 'cart',
      data: {'item': item.name, 'price': item.price, 'restaurant': _restaurantName},
    );
  }

  void removeItem(String itemId) {
    _items.removeWhere((ci) => ci.item.id == itemId);
    if (_items.isEmpty) clearCart();

    SentryService.addBreadcrumb(
      'Item removido do carrinho',
      category: 'cart',
      data: {'itemId': itemId},
    );
  }

  void decreaseItem(String itemId) {
    final idx = _items.indexWhere((ci) => ci.item.id == itemId);
    if (idx < 0) return;

    if (_items[idx].quantity <= 1) {
      removeItem(itemId);
    } else {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity - 1);
    }
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
  }

  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
}
