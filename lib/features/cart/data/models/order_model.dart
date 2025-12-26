import 'package:json_annotation/json_annotation.dart';
import 'package:my_flutter_app/features/product/data/models/product_model.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'total_price')
  final String totalPrice;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}

@JsonSerializable()
class OrderItemModel {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'product_id')
  final int productId;
  final String title;
  final String image;
  final String price;
  final int quantity;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}
