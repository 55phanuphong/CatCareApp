import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/vaccine.dart';
import 'notification_service.dart';
import 'package:async/async.dart';

class VaccineService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// ✅ Reference ไปยัง collection วัคซีนของแมวแต่ละตัว
  CollectionReference<Map<String, dynamic>> _vaccineCollection(String catId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cats')
        .doc(catId)
        .collection('vaccines');
  }

  /// ✅ ดึงวัคซีนของแมวตัวเดียวแบบ real-time
  Stream<List<Vaccine>> getVaccinesByCat(String catId) {
    return _vaccineCollection(catId)
        .orderBy('vaccineName')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Vaccine.fromMap(doc.data(), doc.id)).toList());
  }

  /// ✅ เพิ่มวัคซีนใหม่ + ตั้งการแจ้งเตือน
  Future<void> addVaccine(String catId, Vaccine vaccine) async {
    final doc = _vaccineCollection(catId).doc();
    final vaccineMap = {
      ...vaccine.toMap(),
      'id': doc.id,
      'catName': vaccine.catName,
      'nextDate': vaccine.nextDate,
    };

    await doc.set(vaccineMap);

    // ✅ ตั้งการแจ้งเตือนล่วงหน้าและวันจริง
    if (vaccine.nextDate != null) {
      await _scheduleNotifications(
        vaccine.catName,
        vaccine.vaccineName,
        vaccine.nextDate!,
        doc.id,
      );
    }
  }

  /// ✅ ตั้งการแจ้งเตือนล่วงหน้า
  Future<void> _scheduleNotifications(
      String catName, String vaccineName, DateTime scheduledTime, String docId) async {
    final before24h = scheduledTime.subtract(const Duration(hours: 24));
    final before3h = scheduledTime.subtract(const Duration(hours: 3));

    // 🔔 ล่วงหน้า 1 วัน
    if (before24h.isAfter(DateTime.now())) {
      await NotificationService.I.scheduleNotification(
        id: before24h.millisecondsSinceEpoch.remainder(100000),
        title: "💉 อีก 1 วันจะถึงวันฉีดวัคซีน $vaccineName",
        body: "ตรวจสอบสุขภาพของ $catName",
        scheduledTime: tz.TZDateTime.from(before24h, tz.local),
        payload: docId,
      );
    }

    // 🔔 ล่วงหน้า 3 ชั่วโมง
    if (before3h.isAfter(DateTime.now())) {
      await NotificationService.I.scheduleNotification(
        id: before3h.millisecondsSinceEpoch.remainder(100000),
        title: "⏰ อีก 3 ชั่วโมงจะถึงเวลาฉีดวัคซีน $vaccineName",
        body: "เตรียมตัวพา $catName ไปคลินิกนะ!",
        scheduledTime: tz.TZDateTime.from(before3h, tz.local),
        payload: docId,
      );
    }

    // 🔔 วันจริง
    if (scheduledTime.isAfter(DateTime.now())) {
      await NotificationService.I.scheduleNotification(
        id: scheduledTime.millisecondsSinceEpoch.remainder(100000),
        title: "🐾 ถึงวันฉีดวัคซีน $vaccineName แล้ว!",
        body: "พา $catName ไปฉีดวัคซีนวันนี้นะ 💉",
        scheduledTime: tz.TZDateTime.from(scheduledTime, tz.local),
        payload: docId,
      );
    }
  }

  /// ✅ เปลี่ยนสถานะวัคซีนเป็น “ฉีดแล้ว”
  Future<void> markAsDone(String catId, String vaccineId) async {
    await _vaccineCollection(catId).doc(vaccineId).update({
      'status': 'done',
      'vaccineDate': DateTime.now(),
    });
  }

  /// ✅ อัปเดตวันนัดหมายถัดไป
  Future<void> updateNextDate(String vaccineId, DateTime nextDate) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final cats = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cats')
        .get();

    for (final cat in cats.docs) {
      final vaccineDoc = cat.reference.collection('vaccines').doc(vaccineId);
      final snapshot = await vaccineDoc.get();
      if (snapshot.exists) {
        await vaccineDoc.update({
          'nextDate': nextDate,
          'status': 'upcoming',
        });
      }
    }
  }

  /// ✅ อัปเดตวัคซีน (แก้วันนัดหรือสถานะ)
  Future<void> updateVaccine(
    String catId,
    String vaccineId, {
    String? status,
    DateTime? nextDate,
  }) async {
    final vaccineRef = _vaccineCollection(catId).doc(vaccineId);
    final snapshot = await vaccineRef.get();
    if (!snapshot.exists) throw Exception("Vaccine not found");

    final data = snapshot.data()!;
    final vaccineName = data['vaccineName'];
    final catName = data['catName'] ?? 'แมวของคุณ';

    await vaccineRef.update({
      if (status != null) 'status': status,
      if (nextDate != null) 'nextDate': nextDate,
    });

    // ✅ ถ้ามีการแก้วันนัด → ตั้งแจ้งเตือนใหม่อัตโนมัติ
    if (nextDate != null) {
      await _scheduleNotifications(catName, vaccineName, nextDate, vaccineId);
    }
  }

  /// ✅ ลบวัคซีน
  Future<void> deleteVaccine(String catId, String vaccineId) async {
    await _vaccineCollection(catId).doc(vaccineId).delete();
  }

  /// ✅ โหลดวัคซีนทั้งหมดครั้งเดียว (ใช้ตอนเปิดหน้า Calendar)
  Future<List<Vaccine>> getAllVaccinesOnce() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final List<Vaccine> allVaccines = [];

    final catDocs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cats')
        .get();

    for (final cat in catDocs.docs) {
      final catId = cat.id;
      final catName = cat['name'] ?? "ไม่ทราบชื่อแมว";

      final vaccineSnap =
          await cat.reference.collection('vaccines').get();

      for (final doc in vaccineSnap.docs) {
        final data = doc.data();

        allVaccines.add(Vaccine.fromMap({
          ...data,
          'catId': catId,
          'catName': catName,
        }, doc.id));
      }
    }

    return allVaccines;
  }

  /// ✅ ดึงวัคซีนทุกตัวแบบ real-time ของแมวทุกตัว
  Stream<List<Vaccine>> getVaccinesStreamForAllCats() async* {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final catsCollection =
        _firestore.collection('users').doc(userId).collection('cats');

    await for (final catsSnapshot in catsCollection.snapshots()) {
      if (catsSnapshot.docs.isEmpty) {
        yield [];
        continue;
      }

      final List<Stream<List<Vaccine>>> streams =
          catsSnapshot.docs.map((catDoc) {
        final catId = catDoc.id;
        final catName = catDoc['name'] ?? 'ไม่ทราบชื่อแมว';

        return catDoc.reference.collection('vaccines').snapshots().map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            return Vaccine.fromMap({
              ...data,
              'catId': catId,
              'catName': catName,
            }, doc.id);
          }).toList();
        });
      }).toList();

      if (streams.isNotEmpty) {
        yield* StreamZip(streams).map((listOfLists) {
          return listOfLists.expand((v) => v).toList();
        });
      }
    }
  }
}
