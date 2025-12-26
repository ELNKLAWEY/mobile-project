import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Future<ProductModel> getProductDetails(int id);
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<ProductModel>> getProductsByBrand(int brandId);
}
