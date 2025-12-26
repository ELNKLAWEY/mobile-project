import '../../data/models/brand_model.dart';
import '../../../product/data/models/product_model.dart';

abstract class HomeRepository {
  Future<List<BrandModel>> getBrands();
  Future<List<ProductModel>> getNewArrivals();
}
