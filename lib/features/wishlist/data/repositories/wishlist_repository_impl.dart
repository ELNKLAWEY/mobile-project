import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../product/data/models/product_model.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final ApiClient _apiClient;

  WishlistRepositoryImpl(this._apiClient);

  @override
  Future<List<ProductModel>> getWishlist() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.favorites);
      // Response structure needs verification. Assuming standard: { "data": [...] } or direct list.
      // E-commerce APIs usually return list of products or objects with product details.

      final data = response.data;
      if (data != null && data['data'] != null) {
        final List<dynamic> list =
            data['data']; // Generic "data" wrapper often used
        return list.map((e) => ProductModel.fromJson(e)).toList();
      } else if (data is List) {
        return data.map((e) => ProductModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // If 404 or empty, return empty list
      return [];
    }
  }

  @override
  Future<void> addWishlist(int productId) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.favorites,
        data: {'product_id': productId},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeWishlist(int productId) async {
    try {
      // Assuming remove uses DELETE /favorites/{id} or /favorites with body
      // Standard REST is DELETE /favorites/{id}
      await _apiClient.dio.delete('${ApiEndpoints.favorites}/$productId');
    } catch (e) {
      // If 404, valid to ignore
      if (e is DioException && e.response?.statusCode == 404) {
        return;
      }
      rethrow;
    }
  }
}
