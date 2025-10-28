import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart'; // ✅ เพิ่ม import
import 'register_page.dart';
import 'main_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  final _googleService = GoogleSignInService(); // ✅ เพิ่ม service

  bool _isLoading = false;
  bool _googleLoading = false; // ✅ แสดงโหลดตอนกด Gmail

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // โลโก้
                Column(
                  children: [
                    Image.asset('images/logo1.png', height: 200),
                    const SizedBox(height: 20),
                    const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔸 ปุ่ม Google Sign-In
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Image.asset('images/google1.png', height: 24),
                    label: _googleLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "เข้าสู่ระบบด้วย Google",
                            style: TextStyle(fontSize: 16),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    onPressed: _googleLoading
                        ? null
                        : () async {
                            setState(() => _googleLoading = true);
                            try {
                              final user =
                                  await _googleService.signInWithGoogle();
                              if (user != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "🎉 ยินดีต้อนรับ ${user.displayName ?? ''}",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(12),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                );
                                await Future.delayed(
                                    const Duration(milliseconds: 800));
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const MainPage()),
                                );
                              }
                            } catch (e) {
                              debugPrint("❌ Google Sign-In error: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "ไม่สามารถเข้าสู่ระบบด้วย Google ได้"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } finally {
                              setState(() => _googleLoading = false);
                            }
                          },
                  ),
                ),

                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Username",
                    filled: true,
                    fillColor: const Color(0xFFFFC29D),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: const Color(0xFFFFC29D),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      "ลืมรหัสผ่าน?",
                      style: TextStyle(color: Colors.brown[400], fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 🔹 ปุ่ม Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9966),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              final user = await _auth.login(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );

                              if (user != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "✅ Login Success",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    backgroundColor: Color(0xFF4CAF50),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.all(12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                );

                                await Future.delayed(
                                    const Duration(milliseconds: 800));
                                if (!mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const MainPage()),
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Login Failed",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    backgroundColor: Color(0xFF333333),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.all(12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Login Failed",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  backgroundColor: Color(0xFF333333),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                ),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "เพิ่งเคยเข้า CatCare ใช่หรือไม่ ",
                      style: TextStyle(color: Colors.brown),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        "สมัครใหม่",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
