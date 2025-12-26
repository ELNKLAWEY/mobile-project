import '../../data/models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders();
}
