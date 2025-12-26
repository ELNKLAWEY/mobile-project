// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  price: ProductModel._priceFromJson(json['price']),
  image: json['image'] as String,
  stock: (json['stock'] as num).toInt(),
  brandId: (json['brand_id'] as num?)?.toInt(),
  brandName: json['brand_name'] as String?,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': ProductModel._priceToJson(instance.price),
      'image': instance.image,
      'stock': instance.stock,
      'brand_id': instance.brandId,
      'brand_name': instance.brandName,
    };
