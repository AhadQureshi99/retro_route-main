import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
  Stripe.publishableKey =
      "pk_test_51QaZkMHxqEkEAwMAn2bzy8c7nRda7DEtaz1I0L3BtWQ87L132axKb5yvSrdFfiLki6JaOqoty1ViI4NjRtXBGP0700Lr1BctnB";
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
  // if (kDebugMode) {
  print("Background Message Received: ${message.notification?.title}");
  // }
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
