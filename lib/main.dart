import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/firebase_options.dart';
import 'package:retro_route/services/notification_service.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Stripe.publishableKey ="pk_test_51QvmjRKXrxTon6nZc9cm3kNOcYB9zA36mfRFpM5THnMD6KjcQLKwIoiEHnmfUfcTAMgovgXipoFWKC3wHhkCvvat00ZUv7d3xm";
  Stripe.merchantIdentifier = 'merchant.com.retrorouteco.app';
  await Stripe.instance.applySettings();
  await NotificationServices.instance.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
  CustomToast.init();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background Message Received: ${message.data['title'] ?? message.notification?.title}");

  // Data-only FCM messages don't produce a system notification, so we
  // display one via flutter_local_notifications.  When the user taps it,
  // getNotificationAppLaunchDetails() will reliably return the payload
  // (unlike FCM getInitialMessage(), which returns null on many devices).
  final title = message.data['title'] ?? message.notification?.title ?? 'Notification';
  final body  = message.data['body']  ?? message.notification?.body  ?? 'You have a new message';

  final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings android =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const DarwinInitializationSettings ios = DarwinInitializationSettings();
  const InitializationSettings initSettings =
      InitializationSettings(android: android, iOS: ios);
  await flnp.initialize(settings: initSettings);

  await flnp.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'retro_route_bg',
        'Retro Route Notifications',
        channelDescription: 'Important app notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      designSize: Size(440, 956),
      child: MaterialApp.router(
        routerConfig: goRouter,
        builder: (context, child) => Overlay(
          initialEntries: [
            if (child != null) ...[OverlayEntry(builder: (context) => child)],
          ],
        ),
        title: 'Retro Route Co',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          textTheme: GoogleFonts.interTextTheme(),
        ),
      ),
    );
  }
}
