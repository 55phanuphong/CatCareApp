import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccine {
  final String id;
  final String catId;
  final String catName;
  final String vaccineName;
  final String status; // done, upcoming, pending
  final DateTime? vaccineDate;
  final DateTime? nextDate;
  final String? note;

  Vaccine({
    required this.id,
    required this.catId,
    required this.catName,
    required this.vaccineName,
    required this.status,
    this.vaccineDate,
    this.nextDate,
    this.note,
  });

  Vaccine copyWith({
    String? id,
    String? catId,
    String? catName,
    String? vaccineName,
    String? status,
    DateTime? vaccineDate,
    DateTime? nextDate,
    String? note,
  }) {
    return Vaccine(
      id: id ?? this.id,
      catName: catName ?? this.catName,
      catId: catId ?? this.catId,
      vaccineName: vaccineName ?? this.vaccineName,
      status: status ?? this.status,
      vaccineDate: vaccineDate ?? this.vaccineDate,
      nextDate: nextDate ?? this.nextDate,
      note: note ?? this.note,
    );
  }

  factory Vaccine.fromMap(Map<String, dynamic> map, String id) {
    return Vaccine(
      id: id,
      catId: map['catId'] ?? '',
      catName: map['catName'] ?? 'ไม่ทราบชื่อแมว',
      vaccineName: map['vaccineName'] ?? '',
      status: map['status'] ?? 'pending',
      vaccineDate: map['vaccineDate'] != null
          ? (map['vaccineDate'] as Timestamp).toDate()
          : null,
      nextDate: map['nextDate'] != null
          ? (map['nextDate'] as Timestamp).toDate()
          : null,
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'catId': catId,
      'catName': catName,
      'vaccineName': vaccineName,
      'status': status,
      'vaccineDate': vaccineDate,
      'nextDate': nextDate,
      'note': note,
    };
  }
}
