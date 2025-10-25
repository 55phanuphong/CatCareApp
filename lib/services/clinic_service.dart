import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicService {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getClinics() {
    return _firestore.collection('clinics').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
