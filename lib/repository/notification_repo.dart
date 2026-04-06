import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/notification_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

final notificationRepoProvider = Provider<NotificationRepo>((ref) => NotificationRepo());

class NotificationRepo {
  final _apiServices = NetworkApiServices();

  Future<List<NotificationModel>> getNotifications({required String token}) async {
    try {
      print("notification........... ${AppUrls.getNotifications}");
      final response = await _apiServices.getApi(AppUrls.getNotifications, token);

      final data = response as List<dynamic>;
      return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      log("getNotifications failed", error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> markNotificationAsRead({required String notificationId, required String token}) async {
    try {
      final url = "${AppUrls.baseUrl}/api/v1/notification/$notificationId/read";
      await _apiServices.patchApi({}, url, token);
    } catch (e, stack) {
      log("markNotificationAsRead failed", error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> deleteNotification({required String notificationId, required String token}) async {
    try {
      final url = "${AppUrls.baseUrl}/api/v1/notification/$notificationId";
      await _apiServices.deleteApi(url, token, null);
    } catch (e, stack) {
      log("deleteNotification failed", error: e, stackTrace: stack);
      rethrow;
    }
  }
}