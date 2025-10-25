import 'package:flutter/material.dart';
import '../models/health.dart';
import '../services/health_service.dart';
import 'add_edit_health_page.dart';

class HealthDetailPage extends StatelessWidget {
  final Health health;
  final HealthService _healthService = HealthService(); // ✅ ระบุ type ชัดเจน

  HealthDetailPage({super.key, required this.health});

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "ยืนยันการลบข้อมูล",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("คุณต้องการลบข้อมูลสุขภาพนี้ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "ยกเลิก",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            label: const Text("ลบ"),
          ),
        ],
      ),
    );

    // ✅ ถ้าผู้ใช้กดยืนยัน
    if (result == true) {
      try {
        await _healthService.deleteHealthRecord(health.id); // ✅ ใช้ชื่อที่ถูกต้อง
        if (context.mounted) {
          Navigator.pop(context); // ปิดหน้า detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("ลบข้อมูลสุขภาพเรียบร้อยแล้ว ✅"),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("เกิดข้อผิดพลาดในการลบ: $e"),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text("รายละเอียดสุขภาพ"),
        backgroundColor: const Color(0xFFFFF8E7),
        foregroundColor: Colors.brown,
        elevation: 0,
        actions: [
          // ✏️ ปุ่มแก้ไข
          IconButton(
            tooltip: "แก้ไขข้อมูล",
            icon: const Icon(Icons.edit, color: Colors.brown),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditHealthPage(health: health),
                ),
              );
            },
          ),

          // 🗑️ ปุ่มลบ
          IconButton(
            tooltip: "ลบข้อมูล",
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: const Color(0xFFFFC29D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🐾 ชื่อแมว
                Text(
                  (health.catName?.trim().isNotEmpty ?? false) ? health.catName!.trim() : "ไม่ทราบชื่อแมว",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 16),

                // 📅 วันที่ และ เวลา
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "วันที่: ${health.date.toLocal()}".split(" ")[0],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    if (health.time != null)
                      Text(
                        "เวลา: ${health.time}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 📝 รายละเอียด
                const Text(
                  "รายละเอียด:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  health.note.isNotEmpty ? health.note : "ไม่มีรายละเอียดเพิ่มเติม",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
