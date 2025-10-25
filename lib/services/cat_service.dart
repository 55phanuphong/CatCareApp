import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cat.dart';

class CatService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  /// ✅ คืนค่า Collection ของแมวใน user แต่ละคน
  CollectionReference<Map<String, dynamic>> get _catCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(userId).collection('cats');
  }

  /// ✅ เพิ่มหรืออัปเดตข้อมูลแมว
  Future<void> addOrUpdateCat(
    Cat cat, {
    File? imageFile,
    bool useBase64 = true,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final collection = _firestore.collection('users').doc(userId).collection('cats');

    // ✅ ถ้า id ว่าง = เพิ่มใหม่
    if (cat.id.isEmpty) {
      String newId;

      // หาค่า id ล่าสุดใน Firestore แล้วเพิ่ม 1
      final snapshot = await collection.orderBy("id", descending: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final lastId = int.tryParse(snapshot.docs.first["id"] as String) ?? 0;
        newId = (lastId + 1).toString().padLeft(2, "0");
      } else {
        newId = "01";
      }

      String? profileUrl;
      String? base64Image = cat.base64Image.isNotEmpty ? cat.base64Image : null;

      // ✅ ถ้ามีรูปที่อัปโหลดจริง (ไม่ใช้ Base64)
      if (imageFile != null && !useBase64) {
        final ref = _storage.ref().child('cat_images/$newId.jpg');
        await ref.putFile(imageFile);
        profileUrl = await ref.getDownloadURL();
        base64Image = null;
      }

      // ✅ เพิ่มข้อมูลใหม่ (ไม่ใช้ merge เพื่อไม่ทับของเก่า)
      await collection.doc(newId).set({
        "id": newId,
        "name": cat.name,
        "weight": cat.weight,
        "birthday": cat.birthday.toIso8601String(),
        "gender": cat.gender,
        "breed": cat.breed,
        "note": cat.note,
        "profileUrl": profileUrl ?? "",
        "base64Image": base64Image ?? "",
        "userId": userId,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } 
    // ✅ ถ้ามี id แล้ว = update เฉพาะเอกสารนั้น
    else {
      await collection.doc(cat.id).update({
        "name": cat.name,
        "weight": cat.weight,
        "birthday": cat.birthday.toIso8601String(),
        "gender": cat.gender,
        "breed": cat.breed,
        "note": cat.note,
        "base64Image": cat.base64Image,
        "profileUrl": cat.profileUrl,
      });
    }
  }

  /// ✅ ดึงข้อมูลแมวทั้งหมดแบบเรียลไทม์ (เรียงตามเวลาสร้าง)
  Stream<List<Cat>> getCats() {
    return _catCollection.orderBy("createdAt", descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Cat.fromMap(data);
          }).toList(),
        );
  }

  /// ✅ ลบแมว (และลบรูปใน Storage ด้วยถ้ามี)
  Future<void> deleteCat(String id) async {
    final doc = await _catCollection.doc(id).get();
    final data = doc.data();

    if (doc.exists && data?['profileUrl'] != null && (data!['profileUrl'] as String).isNotEmpty) {
      try {
        await _storage.refFromURL(data['profileUrl'] as String).delete();
      } catch (e) {
        print("⚠️ ไม่สามารถลบรูปจาก Storage: $e");
      }
    }

    await _catCollection.doc(id).delete();
  }
}
