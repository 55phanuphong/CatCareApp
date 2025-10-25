import 'package:catcareapp/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../models/health.dart';
import '../services/health_service.dart';
import 'add_edit_health_page.dart';
import 'health_detail_page.dart';

class HealthPage extends StatelessWidget {
  final HealthService _healthService = HealthService();

  HealthPage({super.key});

  /// ✅ แปลงวันที่ให้โชว์เป็น วัน/เดือน (แบบย่อ)
  String _formatDay(DateTime date) {
    return date.day.toString().padLeft(2, "0");
  }

  String _formatMonth(DateTime date) {
    const months = [
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค."
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text("ข้อมูลสุขภาพ"),
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        foregroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Health>>(
        stream: _healthService.getHealthRecords(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!;
          if (records.isEmpty) {
            return const Center(child: Text("ยังไม่มีข้อมูลสุขภาพ"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = records[index];
              final date = record.date;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailPage(health: record),
                    ),
                  );
                },
                child: Card(
                  color: const Color(0xFFFFC29D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // ✅ กล่องวันที่
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDay(date),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatMonth(date),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // ✅ ข้อมูลสุขภาพ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (record.catName != null)
                                Text(
                                  record.catName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                "เวลา ${record.time ?? "-"}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.note,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            backgroundColor: const Color(0xFFFF9966),
            icon: const Icon(Icons.add, color: Colors.black54),
            label: const Text(
              "เพิ่มข้อมูลสุขภาพ",
              style: TextStyle(color: Colors.black54),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditHealthPage()),
            ),
          ),
        ],
      ),
    );
  }
}
