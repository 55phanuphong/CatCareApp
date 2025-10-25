import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// ✅ สุ่ม OTP 6 หลัก
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// ✅ ส่ง OTP ไปที่ Firestore (และอีเมลจริงคุณต้องเชื่อม SMTP/Nodemailer/Cloud Function)
  Future<bool> sendOtp(String email) async {
    try {
      final otp = _generateOtp();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      await _firestore.collection("otps").doc(email).set({
        "otp": otp,
        "expiresAt": expiresAt.toIso8601String(),
      });

      debugPrint("📩 OTP สำหรับ $email คือ: $otp (ใช้แทนส่งอีเมลจริง)");

      // ❗ NOTE: ตรงนี้ควรใช้ Firebase Cloud Function ส่ง email OTP จริง
      return true;
    } catch (e) {
      debugPrint("❌ Error sendOtp: $e");
      return false;
    }
  }

  /// ✅ ตรวจสอบ OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final doc = await _firestore.collection("otps").doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final savedOtp = data["otp"];
      final expiresAt = DateTime.parse(data["expiresAt"]);

      if (savedOtp == otp && DateTime.now().isBefore(expiresAt)) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error verifyOtp: $e");
      return false;
    }
  }

  /// ✅ รีเซ็ตรหัสผ่านใหม่
  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      // Firebase ไม่อนุญาตให้ reset รหัสผ่านโดยตรงจาก client;
      // ให้ส่งลิงก์รีเซ็ตไปยังอีเมล หรือใช้ Admin SDK ในฝั่งเซิร์ฟเวอร์.
      // เราจะพยายามส่งลิงก์รีเซ็ตรหัสผ่านและจับข้อผิดพลาดถ้าไม่มีผู้ใช้
      await _auth.sendPasswordResetEmail(email: email);

      debugPrint("📩 ส่งลิงก์ reset password ไปที่ $email แล้ว");
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        debugPrint("❌ ไม่มี user: $email");
        return false;
      }
      debugPrint("❌ Error resetPassword: $e");
      return false;
    } catch (e) {
      debugPrint("❌ Error resetPassword: $e");
      return false;
    }
  }
}
