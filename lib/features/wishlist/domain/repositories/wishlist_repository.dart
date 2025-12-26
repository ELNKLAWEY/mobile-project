import '../../../product/data/models/product_model.dart';

abstract class WishlistRepository {
  Future<List<ProductModel>> getWishlist();
  Future<void> addWishlist(int productId);
  Future<void> removeWishlist(int productId);
}
