import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/brand_model.dart';
import '../../../product/data/models/product_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient _apiClient;

  HomeRepositoryImpl(this._apiClient);

  @override
  Future<List<BrandModel>> getBrands() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.brands);
      // Response: [ {id, name...}, ... ] or { "data": [...] }
      // Docs say: Response (200 OK): [ {...}, {...} ] directly list

      final List<dynamic> list = response.data;
      return list.map((e) => BrandModel.fromJson(e)).toList();
    } catch (e) {
      if (e is DioException) {
        // handle
      }
      // Return empty list on error for resiliency? Or throw?
      // Let's throw to handle in UI state error.
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getNewArrivals() async {
    try {
      // For New Arrivals, we can fetch Products with a sort or just all products.
      // Docs: GET /products?page=1&limit=20
      final response = await _apiClient.dio.get(
        ApiEndpoints.products,
        queryParameters: {
          'limit': 10,
          'sort': 'newest',
        }, // Assuming sort supported or just get recent
      );

      // Response: { "products": [...], "pagination": {...} }
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
