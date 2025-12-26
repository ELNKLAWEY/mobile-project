import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final int id;
  final String title;
  final String description;
  @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson)
  final double price;
  final String image;
  final int stock;
  @JsonKey(name: 'brand_id')
  final int? brandId;
  @JsonKey(name: 'brand_name')
  final String? brandName;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.image,
    required this.stock,
    this.brandId,
    this.brandName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  static double _priceFromJson(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return value as double;
    }
  }

  static dynamic _priceToJson(double price) => price.toStringAsFixed(2);
}
