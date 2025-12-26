import '../../data/models/cart_item_model.dart';
// For address info if needed in order

abstract class CartRepository {
  Future<List<CartItemModel>> getCart();
  Future<void> addToCart(int productId, int quantity);
  Future<void> updateCartItem(
    int itemId,
    int quantity,
  ); // itemId logic? API uses itemId or productId? Specs say PATCH /cart/{item_id}
  Future<void> removeCartItem(int itemId);
  Future<void> clearCart();
  Future<void> placeOrder(
    String name,
    String phone,
    String address,
    String country,
    String city,
    String paymentMethod,
  );
}
