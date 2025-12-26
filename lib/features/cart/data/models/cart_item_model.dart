import 'package:json_annotation/json_annotation.dart';

part 'cart_item_model.g.dart';

@JsonSerializable()
class CartItemModel {
  final int id;
  @JsonKey(name: 'product_id')
  final int productId;
  final int quantity;
  final String title;
  final String price; // API sends price as String often in cart list per docs
  final String image;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.title,
    required this.price,
    required this.image,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  double get priceAsDouble => double.tryParse(price) ?? 0.0;
}
