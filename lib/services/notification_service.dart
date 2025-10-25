import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../pages/health_detail_page.dart';
import '../models/health.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// ✅ เรียกใช้ตอน main() ก่อน runApp()
  Future<void> init() async {
    // ✅ ตั้ง timezone ให้ตรงกับประเทศไทย
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    // ✅ ตั้งค่าเริ่มต้น Android / iOS
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // ✅ initialize plugin
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("👉 Tap notification payload=${response.payload}");
        final payload = response.payload;
        if (payload != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => HealthDetailPage(
                health: Health(
                  id: payload,
                  catId: '',
                  catName: 'ไม่ระบุ',
                  title: 'สุขภาพ',
                  note: 'เปิดจากการแจ้งเตือน',
                  date: DateTime.now(),
                  time: '',
                ),
              ),
            ),
          );
        }
      },
    );

    await _requestAllPermissions();
  }

  /// ✅ ขอสิทธิ์แจ้งเตือน + exact alarm (รองรับทุก Android เวอร์ชัน)
  Future<void> _requestAllPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      // ✅ ขอสิทธิ์ exact alarm สำหรับ Android 12+
      if (Platform.isAndroid) {
        try {
          const intent = AndroidIntent(
            action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
        } catch (e) {
          debugPrint('⚠️ เปิดหน้าตั้งค่า Exact Alarm ไม่ได้: $e');
          // ถ้าไม่มีหน้า exact alarm ให้เปิดหน้าแอปแทน
          const fallbackIntent = AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:com.example.catcareapp', // ⚠️ แก้ชื่อ package ของคุณ
          );
          await fallbackIntent.launch();
        }
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดตอนขอ permission: $e');
    }
  }

  // ✅ แจ้งเตือนทันที (test / แจ้งเตือนเร็ว)
  Future<void> showNow({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "catcare_channel",
      "CatCare Notifications",
      channelDescription: "แจ้งเตือนสุขภาพแมว",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ✅ ตั้งเวลาแจ้งเตือน (เช่น นัดสุขภาพ / ฉีดวัคซีน)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "catcare_channel",
      "CatCare Notifications",
      channelDescription: "แจ้งเตือนสุขภาพแมว",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    debugPrint("📅 [NotificationService] ตั้งแจ้งเตือน: $tzTime");

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
      );
      debugPrint("✅ ตั้งแจ้งเตือนสำเร็จ id=$id เวลา=$tzTime");
    } catch (e) {
      debugPrint("❌ ตั้งแจ้งเตือนไม่สำเร็จ: $e");
    }
  }

  /// ✅ ยกเลิกการแจ้งเตือนเดี่ยว
  Future<void> cancel(int id) async => _plugin.cancel(id);

  /// ✅ ยกเลิกการแจ้งเตือนทั้งหมด
  Future<void> cancelAll() async => _plugin.cancelAll();
}
