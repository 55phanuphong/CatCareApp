import 'package:cloud_firestore/cloud_firestore.dart';

class Health {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final String? time;

  // ✅ ฟิลด์สัมพันธ์กับ Cat
  final String? catId;
  final String? catName;

  Health({
    this.id = "", // ✅ ตั้งค่า default เป็น "" เพื่อเลี่ยง null error
    required this.title,
    required this.note,
    required this.date,
    this.time,
    this.catId,
    this.catName,
  });

  // ✅ แปลงเป็น Firestore Map (บันทึกลง DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // 🔥 เก็บ id ด้วยเสมอ
      'title': title,
      'note': note,
      'date': Timestamp.fromDate(date), // เก็บเป็น Firestore Timestamp
      'time': time ?? '',
      'catId': catId ?? '',
      'catName': catName ?? '',
    };
  }

  // ✅ ดึงข้อมูลจาก Firestore Map (อ่านจาก DB)
  factory Health.fromMap(Map<String, dynamic> map, String docId) {
    return Health(
      id: (map['id'] ?? "").toString().isNotEmpty ? map['id'] : docId,
      title: map['title'] ?? '',
      note: map['note'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      time: map['time'] ?? '',
      catId: map['catId'] ?? '',
      catName: map['catName'] ?? '',
    );
  }
}
