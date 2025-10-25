import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// สมัคร user + สร้าง customId อัตโนมัติ
  Future<User?> registerUser(String email, String password) async {
    try {
      // ✅ สมัครสมาชิก FirebaseAuth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // ✅ หา customId ล่าสุด (เรียง 01, 02, 03)
      final snapshot = await _firestore.collection('users').get();
      final count = snapshot.docs.length;
      final customId = (count + 1).toString().padLeft(2, "0");

      // ✅ บันทึกข้อมูล user ลง Firestore
      await _firestore.collection('users').doc(uid).set({
        "customId": customId,
        "email": email,
        "createdAt": DateTime.now().toIso8601String(),
      });

      return userCredential.user;
    } catch (e) {
      print("Error registering user: $e");
      return null;
    }
  }

  /// ดึง customId ของ user ที่ login
  Future<String?> getCurrentUserCustomId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['customId'];
  }
}
