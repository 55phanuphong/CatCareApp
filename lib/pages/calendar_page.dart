import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/health.dart';
import '../models/vaccine.dart';
import '../services/health_service.dart';
import '../services/vaccine_service.dart';
import 'health_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final HealthService _healthService = HealthService();
  final VaccineService _vaccineService = VaccineService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener(); // ฟังแบบ real-time ทันที
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshOnce(); // โหลดข้อมูลใหม่ทุกครั้งที่กลับเข้าหน้านี้
  }

  /// ✅ โหลดข้อมูลล่าสุด 1 ครั้ง (เวลาเข้าใหม่)
  Future<void> _refreshOnce() async {
    final healthRecords = await _healthService.getHealthRecordsOnce();
    final vaccineRecords = await _vaccineService.getAllVaccinesOnce();
    _updateEvents(healthRecords, vaccineRecords);
  }

  /// ✅ ฟังข้อมูลสุขภาพ + วัคซีนแบบ real-time ตลอด
  void _setupRealtimeListener() {
    final healthStream = _healthService.getHealthRecords();
    final vaccineStream = _vaccineService.getVaccinesStreamForAllCats();

    _subscription = CombineLatestStream.combine2<List<Health>, List<Vaccine>,
        Map<DateTime, List<Map<String, dynamic>>>>(
      healthStream,
      vaccineStream,
      (healthRecords, vaccineRecords) {
        final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

        // 🩺 ข้อมูลสุขภาพ
        for (var h in healthRecords) {
          final dateKey = DateTime(h.date.year, h.date.month, h.date.day);
          newEvents.putIfAbsent(dateKey, () => []);
          newEvents[dateKey]!.add({
            "type": "health",
            "title": "ตรวจสุขภาพของ ${h.catName}",
            "note": h.note,
            "time": h.time ?? "-",
            "catName": h.catName,
            "data": h,
          });
        }

        // 💉 ข้อมูลวัคซีน
        for (var v in vaccineRecords) {
          if (v.nextDate == null) continue;
          final dateKey =
              DateTime(v.nextDate!.year, v.nextDate!.month, v.nextDate!.day);
          newEvents.putIfAbsent(dateKey, () => []);
          newEvents[dateKey]!.add({
            "type": "vaccine",
            "title": "วัคซีน ${v.vaccineName}",
            "note": "แมว: ${v.catName} | สถานะ: ${v.status}",
            "time":
                "${v.nextDate!.hour.toString().padLeft(2, "0")}:${v.nextDate!.minute.toString().padLeft(2, "0")}",
            "catName": v.catName,
            "data": v,
          });
        }

        return newEvents;
      },
    ).listen((newEvents) {
      setState(() => _events = newEvents);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// ✅ รวมข้อมูลเข้าปฏิทิน
  void _updateEvents(List<Health> healthRecords, List<Vaccine> vaccineRecords) {
    final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

    for (var h in healthRecords) {
      final dateKey = DateTime(h.date.year, h.date.month, h.date.day);
      newEvents.putIfAbsent(dateKey, () => []);
      newEvents[dateKey]!.add({
        "type": "health",
        "title": "ตรวจสุขภาพของ ${h.catName}",
        "note": h.note,
        "time": h.time ?? "-",
        "catName": h.catName,
        "data": h,
      });
    }

    for (var v in vaccineRecords) {
      if (v.nextDate == null) continue;
      final dateKey =
          DateTime(v.nextDate!.year, v.nextDate!.month, v.nextDate!.day);
      newEvents.putIfAbsent(dateKey, () => []);
      newEvents[dateKey]!.add({
        "type": "vaccine",
        "title": "วัคซีน ${v.vaccineName}",
        "note": "แมว: ${v.catName} | สถานะ: ${v.status}",
        "time":
            "${v.nextDate!.hour.toString().padLeft(2, "0")}:${v.nextDate!.minute.toString().padLeft(2, "0")}",
        "catName": v.catName,
        "data": v,
      });
    }

    setState(() => _events = newEvents);
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text("📅 ปฏิทินสุขภาพ & วัคซีน"),
        backgroundColor: const Color(0xFFFFF8E7),
        foregroundColor: Colors.brown,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFFFA559),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.brown,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.brown),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.brown),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final nonNullEvents = events ?? [];
                if (nonNullEvents.isEmpty) return const SizedBox();

                final hasHealth = nonNullEvents.any(
                    (e) => e is Map<String, dynamic> && e['type'] == 'health');
                final hasVaccine = nonNullEvents.any(
                    (e) => e is Map<String, dynamic> && e['type'] == 'vaccine');

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasHealth)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasVaccine)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedDay == null
                  ? const Center(
                      key: ValueKey("noDay"),
                      child: Text(
                        "แตะวันที่บนปฏิทินเพื่อดูสุขภาพและวัคซีนของแมว",
                        style: TextStyle(fontSize: 16, color: Colors.brown),
                      ),
                    )
                  : _buildEventList(_getEventsForDay(_selectedDay!)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return const Center(
        key: ValueKey("noEvent"),
        child: Text("ไม่มีรายการในวันนี้",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    events.sort((a, b) => a["time"].toString().compareTo(b["time"].toString()));

    return ListView.builder(
      key: const ValueKey("eventList"),
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        final isHealth = e["type"] == "health";
        final isVaccine = e["type"] == "vaccine";

        return Card(
          color: isHealth ? Colors.green[100] : Colors.orange[100],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              isHealth ? Icons.monitor_heart : Icons.vaccines,
              color: isHealth ? Colors.green : Colors.deepOrange,
              size: 30,
            ),
            title: Text(
              e["title"],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            subtitle: Text(
              "เวลา: ${e["time"]}\n${e["note"] ?? '-'}",
              style: const TextStyle(color: Colors.black87, height: 1.5),
            ),
            trailing: isHealth
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.brown),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HealthDetailPage(health: e["data"]),
                        ),
                      );
                    },
                  )
                : const SizedBox(),
          ),
        );
      },
    );
  }
}
