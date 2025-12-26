import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiClient _apiClient;

  ProductRepositoryImpl(this._apiClient);

  @override
  Future<ProductModel> getProductDetails(int id) async {
    try {
      final response = await _apiClient.dio.get('${ApiEndpoints.products}/$id');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      // Client-side filtering workaround for server 500 error
      final response = await _apiClient.dio.get(ApiEndpoints.products);

      final data = response.data;
      if (data != null && data['products'] != null) {
        final List<dynamic> list = data['products'];
        final allProducts = list.map((e) => ProductModel.fromJson(e)).toList();

        if (query.isEmpty) return allProducts;

        final lowerQuery = query.toLowerCase();
        return allProducts.where((p) {
          return p.title.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByBrand(int brandId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.brands}/$brandId/products',
      );

      final data = response.data;
      if (data != null && data['products'] != null) {
        final List<dynamic> list = data['products'];
        return list.map((e) => ProductModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
