import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageHelper {
  /// ✅ แปลงรูป (File) → Base64 string (พร้อมบีบอัด)
  static Future<String?> fileToBase64(File file) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 800,
        quality: 80,
      );

      if (compressed == null) return null;
      return base64Encode(compressed);
    } catch (e) {
      debugPrint("⚠️ fileToBase64 error: $e");
      return null;
    }
  }

  /// ✅ แปลง Base64 → ImageProvider (ใช้กับ CircleAvatar, Container, ฯลฯ)
  static ImageProvider? base64ToImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Str);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint("⚠️ base64ToImage error: $e");
      return null;
    }
  }

  /// ✅ แปลง Base64 → Widget `Image` โดยตรง (ใช้กรณีพิเศษ)
  static Image base64ToImageWidget(String base64Str,
      {BoxFit fit = BoxFit.cover}) {
    final bytes = base64Decode(base64Str);
    return Image.memory(bytes, fit: fit);
  }
}
