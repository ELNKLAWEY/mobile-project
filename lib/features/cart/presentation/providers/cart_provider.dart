import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/models/cart_item_model.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(ref.read(apiClientProvider));
});

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>((ref) {
      return CartNotifier(ref.watch(cartRepositoryProvider));
    });

class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchCart();
  }

  Future<void> fetchCart() async {
    try {
      final items = await _repository.getCart();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToCart(int productId, [int quantity = 1]) async {
    try {
      await _repository.addToCart(productId, quantity);
      await fetchCart(); // Refresh cart
    } catch (e) {
      // handle error?
      rethrow;
    }
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    try {
      await _repository.updateCartItem(itemId, quantity);
      await fetchCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      await _repository.removeCartItem(itemId);
      await fetchCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _repository.clearCart();
      state = const AsyncValue.data([]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkout(
    String name,
    String phone,
    String address,
    String country,
    String city,
    String paymentMethod,
  ) async {
    try {
      await _repository.placeOrder(
        name,
        phone,
        address,
        country,
        city,
        paymentMethod,
      );
      // On success, cart is cleared on server usually?
      state = const AsyncValue.data([]);
    } catch (e) {
      rethrow;
    }
  }
}

// Derived provider for subtotal/total
final cartTotalProvider = Provider<double>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.maybeWhen(
    data: (items) => items.fold(
      0.0,
      (sum, item) => sum + (item.priceAsDouble * item.quantity),
    ),
    orElse: () => 0.0,
  );
});

// Derived provider for cart item count (for badge)
final cartItemCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.maybeWhen(
    data: (items) => items.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});
