import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retro_route/model/notification_model.dart';
import 'package:retro_route/repository/notification_repo.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>(
        (ref) => NotificationsNotifier(ref));

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchNotifications(String token) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(notificationRepoProvider).getNotifications(token: token);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void replaceNotifications(List<NotificationModel> notifications) {
    state = AsyncValue.data(notifications);
  }
}