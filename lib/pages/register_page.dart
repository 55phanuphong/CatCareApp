import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้
              Image.asset('images/logo1.png', width: 210),
              const SizedBox(height: 20),
              const Text(
                "สมัครบัญชีผู้ใช้",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 20),

              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
                  filled: true,
                  fillColor: const Color(0xFFFFC29D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                ),
              ),
              const SizedBox(height: 15),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: const Color(0xFFFFC29D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                ),
              ),
              const SizedBox(height: 25),

              // 🔹 Register Button
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
                            final user = await _userService.registerUser(
                              _usernameController.text.trim(),
                              _passwordController.text.trim(),
                            );

                            if (user != null && mounted) {
                              final customId =
                                  await _userService.getCurrentUserCustomId();

                              // ✅ แสดง SnackBar สวยแบบ Login
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "สมัครสมาชิกสำเร็จ! รหัสผู้ใช้คือ $customId",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  backgroundColor: const Color(0xFF4CAF50),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(12),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                ),
                              );

                              // ✅ หน่วงเวลาให้ SnackBar แสดงก่อนเปลี่ยนหน้า
                              await Future.delayed(
                                  const Duration(milliseconds: 800));

                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Register Failed",
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
                                  "Register Failed",
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
                          "Register",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // ลิงก์กลับไปหน้า Login
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: "หากมีบัญชีผู้ใช้แล้ว คุณสามารถ ",
                    style: TextStyle(color: Colors.brown),
                    children: [
                      TextSpan(
                        text: "เข้าสู่ระบบ",
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
