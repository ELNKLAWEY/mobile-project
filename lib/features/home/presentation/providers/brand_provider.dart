import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/product/data/models/product_model.dart';
import '../../../../features/product/domain/repositories/product_repository.dart';
import '../../../../features/product/data/repositories/product_repository_impl.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// Provider for ProductRepository (if not already global, we can define it here or reuse)
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.read(apiClientProvider));
});

// Family provider to fetch products by brand ID
final productsByBrandProvider = FutureProvider.family<List<ProductModel>, int>((
  ref,
  brandId,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductsByBrand(brandId);
});
