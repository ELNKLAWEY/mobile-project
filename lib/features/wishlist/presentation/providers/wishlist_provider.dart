import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../../product/data/models/product_model.dart';
// Note: WishlistRepositoryImpl needs apiClientProvider from AuthFeature or Core

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepositoryImpl(ref.read(apiClientProvider));
});

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, AsyncValue<List<ProductModel>>>((
      ref,
    ) {
      return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
    });

class WishlistNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final WishlistRepository _repository;

  WishlistNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    try {
      final items = await _repository.getWishlist();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleWishlist(ProductModel product) async {
    // Optimistic update
    final currentState = state.value;
    if (currentState == null) return;

    final isLikded = currentState.any((item) => item.id == product.id);
    List<ProductModel> newItems;

    if (isLikded) {
      newItems = currentState.where((item) => item.id != product.id).toList();
    } else {
      newItems = [...currentState, product];
    }
    state = AsyncValue.data(newItems);

    try {
      if (isLikded) {
        await _repository.removeWishlist(product.id);
      } else {
        await _repository.addWishlist(product.id);
      }
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentState);
      // maybe show error
    }
  }

  bool isWishlisted(int productId) {
    return state.maybeWhen(
      data: (items) => items.any((item) => item.id == productId),
      orElse: () => false,
    );
  }
}
