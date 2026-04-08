import 'dart:convert';
import 'dart:developer';
import 'dart:math' as m;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view/dashboard/dashboard_view.dart';

class NotificationServices {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationServices._privateConstructor();
  static final NotificationServices instance =
      NotificationServices._privateConstructor();

  /// Holds notification data from a cold-start tap, consumed by SplashScreen.
  Map<String, dynamic>? pendingNotificationData;

  /// True when the app was launched (or resumed) via a notification tap.
  bool openedFromNotification = false;

  static const String _channelDescription = "Important app notifications";

  /// Main initialize function
  Future<void> initialize() async {
    await requestNotificationPermission();
    await _initLocalNotifications();
    await _setupFCMHandlers();
    await _getAndSaveInitialToken();
    _listenForTokenRefresh();
  }

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) log('Notification permission granted');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const DarwinInitializationSettings ios = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    // Request local notification permissions safely per platform.
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macosImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle tap on local notification (shown in foreground)
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            _handleNotificationNavigation(data);
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _setupFCMHandlers() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _showLocalNotification(message);
    });

    // App opened from notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        log("App opened from notification: ${message.notification?.title}");
      }
      openedFromNotification = true;
      _handleNotificationNavigation(message.data);
    });

    // App launched from terminated state via notification tap
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Store the data — SplashScreen will consume it after its own navigation
      pendingNotificationData = initialMessage.data;
      openedFromNotification = true;
    }
  }

  /// Navigate based on notification data payload
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    final orderId = data['orderId'] as String?;

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      // Context not ready yet (app still resuming) — store for later.
      pendingNotificationData = data;
      return;
    }

    // Suppress milk run so the dashboard doesn't hijack navigation.
    HomeDashboardScreen.suppressMilkRunForSession = true;

    if (screen != null) {
      switch (screen) {
        case 'CrateApproval':
          if (orderId != null) {
            GoRouter.of(ctx).push('${AppRoutes.crateApproval}?orderId=$orderId');
            return;
          }
        case 'PoolReport':
          if (orderId != null) {
            GoRouter.of(ctx).push('${AppRoutes.poolReport}?orderId=$orderId');
            return;
          }
        case 'OrderHistory':
          GoRouter.of(ctx).go(AppRoutes.orderHistory);
          return;
        case 'DriverDeliveries':
          GoRouter.of(ctx).go(AppRoutes.driverHome);
          return;
        case 'DriverOrderDetail':
          GoRouter.of(ctx).go(AppRoutes.driverHome);
          return;
      }
    }

    // Default: open notifications page for any notification tap
    GoRouter.of(ctx).go(AppRoutes.notifications);
  }

  /// Get token and save via API
  Future<void> _getAndSaveInitialToken() async {
    await _saveFCMTokenToApi(); // No need to pass token — it fetches internally
  }

  /// Token refresh listener — important!
  void _listenForTokenRefresh() {
    messaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) log("FCM Token refreshed: $newToken");
      await _saveFCMTokenToApi(newToken); // Force update with new token
    });
  }

  /// Core function: Save FCM token via API
  Future<void> _saveFCMTokenToApi([String? forcedToken]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get auth token from session
      final sessionJson = prefs.getString('auth_session_json');
      if (sessionJson == null) {
        if (kDebugMode) log("No session found — user not logged in");
        return;
      }

      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      final authToken = session['data']['token'] as String?;
      if (authToken == null || authToken.isEmpty) {
        if (kDebugMode) log("Auth token missing");
        return;
      }

      // Get current device token
      final String? currentDeviceToken =
          forcedToken ?? await messaging.getToken();

      if (currentDeviceToken == null) {
        if (kDebugMode) log("Failed to get device FCM token");
        return;
      }

      // Call API to save FCM token
      final apiServices = NetworkApiServices();
      await apiServices.putApi(
        {"fcmToken": currentDeviceToken},
        AppUrls.saveFcmToken,
        authToken,
      );

      if (kDebugMode) {
        log("FCM Token saved via API: $currentDeviceToken");
      }
    } catch (e) {
      log("Failed to save FCM token via API: $e");
    }
  }

  Future<void> saveTokenOnLogin() async {
    await _saveFCMTokenToApi();
  }

  Future<bool> _getBoolPref(String key, {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Show local notification with user settings
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // final bool isGeneralNotificationEnabled = await _getBoolPref(
    //   'push_notification_enabled',
    // );

    // if (!isGeneralNotificationEnabled) return;

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      m.Random.secure().nextInt(100000).toString(),
      'High Importance Notifications',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
      enableLights: true,
      enableVibration: true,
    );

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id.toString(), // Fixed ID
      channel.name.toString(), // Fixed name
      channelDescription: _channelDescription,
      importance: Importance.high,
      color: AppColors.primary,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      enableLights: true,
      // icon: '@mipmap/launcher_icon',  // Agar chahiye to add kar lo
    );
        // IOS
  const DarwinNotificationDetails iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: message.notification?.title ?? "Notification",
      body: message.notification?.body ?? "You have a new message",
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  /// Optional: Clear token on logout
  Future<void> clearTokenOnLogout() async {
    await _saveFCMTokenToApi(""); // Or null
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}