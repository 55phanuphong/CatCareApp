import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/notification_service.dart';

/// ✅ Background handler (ต้องเป็น top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notification = message.notification;
  if (notification != null) {
    await NotificationService.I.showNow(
      title: notification.title ?? "CatCare",
      body: notification.body ?? "",
      payload: message.data['payload'],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Init Local Notifications
  await NotificationService.I.init();

  // ✅ ตั้งค่า FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ ขอสิทธิ์แจ้งเตือน (Android 13+ จะขึ้นถาม)
  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ฟัง FCM ตอน foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        await NotificationService.I.showNow(
          title: notification.title ?? "CatCare",
          body: notification.body ?? "",
          payload: message.data['payload'],
        );
      }
    });

    // ✅ ฟังตอนกดจาก system tray
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = message.data['payload'];
      debugPrint("👉 User tapped notification, payload: $payload");

      // ✅ ตัวอย่าง route เมื่อกดแจ้งเตือน
      if (payload == "health_detail") {
        // NotificationService.I.navigatorKey.currentState?.push(
        //   MaterialPageRoute(builder: (_) => HealthDetailPage(...)),
        // );
      }
    });

    return MaterialApp(
      title: 'CatCare App',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.I.navigatorKey, // ✅ ใช้ route จากการกดแจ้งเตือน
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const LoginPage(),
    );
  }
}
