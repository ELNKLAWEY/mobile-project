import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/cart_repository.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final ApiClient _apiClient;

  CartRepositoryImpl(this._apiClient);

  @override
  Future<List<CartItemModel>> getCart() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.cart);
      // Response: [ { ... }, { ... } ]
      final List<dynamic> list = response.data;
      return list.map((e) => CartItemModel.fromJson(e)).toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<void> addToCart(int productId, int quantity) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.cart,
        data: {'product_id': productId, 'quantity': quantity},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCartItem(int itemId, int quantity) async {
    try {
      await _apiClient.dio.patch(
        '${ApiEndpoints.cart}/$itemId',
        data: {'quantity': quantity},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeCartItem(int itemId) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.cart}/$itemId');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.cart);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> placeOrder(
    String name,
    String phone,
    String address,
    String country,
    String city,
    String paymentMethod,
  ) async {
    try {
      // API Spec: POST /orders
      /*
      {
        "full_name": "...",
        "phone": "...",
        "country": "...",
        "city": "...",
        "address": "...",
        "payment_method": "..."
      }
       */
      await _apiClient.dio.post(
        ApiEndpoints.orders,
        data: {
          'full_name': name,
          'phone': phone,
          'address': address,
          'country': country,
          'city': city,
          'payment_method': paymentMethod,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
