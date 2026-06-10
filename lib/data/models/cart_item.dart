import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  final int quantity;
  final String? note;

  const CartItem({
    required this.item,
    required this.quantity,
    this.note,
  });

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      item: item,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  double get total => item.price * quantity;
}
