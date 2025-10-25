import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health.dart';

class HealthService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ✅ อ้างอิง collection ตาม userId
  CollectionReference<Map<String, dynamic>> get _healthCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(userId).collection('health');
  }

  /// ✅ ดึงข้อมูลสุขภาพทั้งหมดแบบ real-time
  Stream<List<Health>> getHealthRecords() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    return _healthCollection
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Health.fromMap(doc.data(), doc.id)).toList());
  }

  /// ✅ โหลดข้อมูลสุขภาพทั้งหมดครั้งเดียว (ใช้ตอนเปิดหน้าแอป)
  Future<List<Health>> getHealthRecordsOnce() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final snapshot = await _healthCollection
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => Health.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// ✅ เพิ่มหรืออัปเดตข้อมูลสุขภาพ
  Future<void> addOrUpdateHealth(Health health) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    if (health.id.isEmpty) {
      // 🔹 สร้างเอกสารใหม่แบบ auto-id
      final newDoc = _healthCollection.doc();
      await newDoc.set({
        ...health.toMap(),
        'id': newDoc.id,
        'userId': userId,
      });
    } else {
      // ✏️ อัปเดตข้อมูลเดิม
      await _healthCollection.doc(health.id).set({
        ...health.toMap(),
        'userId': userId,
      }, SetOptions(merge: true));
    }
  }

  /// ✅ ลบข้อมูลสุขภาพ (ใช้ doc.id จาก Firestore)
  Future<void> deleteHealthRecord(String id) async {
    await _healthCollection.doc(id).delete();
  }
}
