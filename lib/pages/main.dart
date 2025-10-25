import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init(); // ✅ ต้องเรียกก่อน runApp()
 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.I.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "CatCare",
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        fontFamily: 'Kanit',
      ),
      home: const MainPage(), // ✅ เข้าหน้าหลัก
    );
  }
}
