import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import '../main.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool isLoading = false;
  String errorMsg = "";

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController(text: "test@voiceguide.com");
  final TextEditingController passCtrl = TextEditingController(text: "123456");

  Future<void> submit() async {
    setState(() {
      errorMsg = "";
      isLoading = true;
    });

    try {
      if (!isLogin) {
        bool regOk = await ApiService.register(emailCtrl.text, passCtrl.text, nameCtrl.text.isEmpty ? "Yeni Kullanıcı" : nameCtrl.text);
        if (!regOk) {
          setState(() {
            errorMsg = "Kayıt başarısız oldu.";
            isLoading = false;
          });
          return;
        }
      }

      bool loginOk = await ApiService.login(emailCtrl.text, passCtrl.text);
      if (loginOk) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainScreen(cameras: cameras)),
        );
      } else {
        setState(() {
          errorMsg = "Giriş başarısız. Lütfen bilgileri kontrol edin.";
        });
      }
    } catch (e) {
      setState(() => errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color forest = Color(0xFF2D5A27);
    const Color meadow = Color(0xFF4A7C42);
    const Color sage = Color(0xFF7AAD70);
    const Color darkBg = Color(0xFF080F09);

    return Scaffold(
      backgroundColor: darkBg,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.8),
            radius: 1.2,
            colors: [Color(0x264A7C42), darkBg], // 15% opacity meadow -> dark
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // İkon kutusu
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0x4D4A7C42), Color(0x26C9747A)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sage.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.graphic_eq, color: sage, size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isLogin ? "Tekrar hoş geldin" : "Hesap oluştur",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin ? "Sesli rehbere devam et" : "Dünyayı keşfetmeye başla",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tab bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isLogin = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLogin ? meadow.withOpacity(0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Giriş Yap",
                                  style: TextStyle(
                                    color: isLogin ? sage : Colors.white.withOpacity(0.3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isLogin = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !isLogin ? meadow.withOpacity(0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Kayıt Ol",
                                  style: TextStyle(
                                    color: !isLogin ? sage : Colors.white.withOpacity(0.3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isLogin) ...[
                      _buildTextField("Ad Soyad", nameCtrl, Icons.person_outline),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField("E-posta", emailCtrl, Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField("Şifre", passCtrl, Icons.lock_outline, obscure: true),
                    const SizedBox(height: 24),

                    if (errorMsg.isNotEmpty) ...[
                      Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: meadow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 8,
                          shadowColor: meadow.withOpacity(0.5),
                        ),
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLogin ? "Giriş Yap" : "Hesap Oluştur",
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: const Color(0xFF7AAD70), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
