import 'dart:convert'; // ✅ สำหรับแปลง base64 → bytes
import 'package:flutter/material.dart';
import '../services/cat_service.dart';
import '../models/cat.dart';
import 'add_edit_cat_page.dart';
import 'cat_detail_page.dart';

class CatListPage extends StatelessWidget {
  final CatService _catService = CatService();

  CatListPage({super.key});

  /// ✅ ฟังก์ชันคำนวณอายุจากวันเกิด
  String _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int years = now.year - birthday.year;
    int months = now.month - birthday.month;
    int days = now.day - birthday.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    return "$years ปี $months เดือน $days วัน";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text("สัตว์เลี้ยงของฉัน"),
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        foregroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Cat>>(
        stream: _catService.getCats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cats = snapshot.data!;
          if (cats.isEmpty) {
            return const Center(child: Text("ยังไม่มีข้อมูลแมว"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cats.length,
            itemBuilder: (context, index) {
              final cat = cats[index];

              // ✅ เลือกรูป: Base64 > URL > Default Icon
              ImageProvider? imageProvider;
              if (cat.base64Image.isNotEmpty) {
                try {
                  final bytes = base64Decode(cat.base64Image);
                  imageProvider = MemoryImage(bytes);
                } catch (e) {
                  debugPrint("⚠️ Base64 decode error: $e");
                }
              } else if (cat.profileUrl.isNotEmpty) {
                imageProvider = NetworkImage(cat.profileUrl);
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CatDetailPage(cat: cat),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Card(
                  color: const Color(0xFFFFC29D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ แสดงรูปแมว
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: imageProvider,
                          backgroundColor: Colors.grey[300],
                          child: imageProvider == null
                              ? const Icon(Icons.pets, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // ✅ ข้อมูลแมว
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ชื่อ + เพศ
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("เพศ: ${cat.gender}"),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // พันธุ์ + น้ำหนัก
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("พันธุ์: ${cat.breed}"),
                                  Text("น้ำหนัก: ${cat.weight} kg"),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // วันเกิด + อายุ
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "วันเกิด: ${cat.birthday.toLocal().toString().split(' ')[0]}",
                                  ),
                                  Text("อายุ: ${_calculateAge(cat.birthday)}"),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // หมายเหตุ
                              if (cat.note.isNotEmpty)
                                Text("หมายเหตุ: ${cat.note}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF9966),
        icon: const Icon(Icons.add, color: Colors.black54),
        label: const Text("เพิ่มน้องแมว",
          style: TextStyle(color: Colors.black54),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditCatPage()),
        ),
      ),
    );
  }
}
