import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.read(apiClientProvider));
});

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((
  ref,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrders();
});
