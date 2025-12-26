import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient _apiClient;

  OrderRepositoryImpl(this._apiClient);

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.orders);
      final List<dynamic> data = response.data;
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
