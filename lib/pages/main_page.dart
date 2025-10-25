import 'package:flutter/material.dart';
import 'cat_list_page.dart';
import 'health_page.dart';
import 'calendar_page.dart';
import 'clinic_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key}); // ✅ แก้เป็น const

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // ✅ ใส่ const ไว้ได้เพราะทุกหน้ามี const constructor แล้ว
  final List<Widget> _pages = [
    CatListPage(),
    HealthPage(),
    const CalendarPage(),
    const ClinicPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFF8E7),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: "สัตว์เลี้ยง",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "ข้อมูลสุขภาพ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "ปฏิทินสุขภาพ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital),
            label: "คลินิกใกล้ฉัน",
          ),
        ],
      ),
    );
  }
}
