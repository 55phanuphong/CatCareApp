import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Cloud Function API Base
  final String apiBase = "https://<your-cloud-function-url>";

  // ✅ สมัครสมาชิก
  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Register Error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // ✅ ล็อกอิน
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // ✅ ลืมรหัสผ่าน (Firebase Default → ส่งลิงก์รีเซ็ตไปที่อีเมล)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Reset Password Error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // ✅ ส่ง OTP ไปที่อีเมล (ผ่าน Cloud Function/SMTP API)
  Future<String?> sendOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse("$apiBase/sendOtp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)["otp"];
      } else {
        print("Send OTP Failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Send OTP Error: $e");
      return null;
    }
  }

  // ✅ รีเซ็ตรหัสผ่านใหม่ด้วย OTP (ผ่าน Cloud Function/SMTP API)
  Future<bool> resetPasswordWithOtp(
      String email, String otp, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse("$apiBase/resetPassword"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Reset Password With OTP Error: $e");
      return false;
    }
  }

  // ✅ ล็อกเอาท์
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ✅ ฟังสถานะ user (login/logout)
  Stream<User?> get userStream => _auth.authStateChanges();

  // ✅ ดึง user ปัจจุบัน
  User? get currentUser => _auth.currentUser;
}
