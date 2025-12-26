import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../../product/data/repositories/product_repository_impl.dart';
import '../../data/models/brand_model.dart';
import '../../../product/data/models/product_model.dart';

// Repositories
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.read(apiClientProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.read(apiClientProvider));
});

// Data Providers
final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getBrands();
});

final newArrivalsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getNewArrivals();
});

final productDetailsProvider = FutureProvider.family<ProductModel, int>((
  ref,
  id,
) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getProductDetails(id);
});

final searchProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final repo = ref.read(productRepositoryProvider);
      return repo.searchProducts(query);
    });
