import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retro_route/model/orderhistory_model.dart';
import 'package:retro_route/repository/order_repo.dart';

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, AsyncValue<List<Order>>>(
        (ref) => OrderHistoryNotifier(ref));

class OrderHistoryNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final Ref ref;

  OrderHistoryNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchOrders(String token) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(orderRepoProvider).getOrderHistory(token: token);
      state = AsyncValue.data(response.data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}