
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../app_state.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔄 محاولة تسجيل الدخول...');
      final loginResponse = await AuthService.login(_email.text, _pass.text);


      final appState = Provider.of<AppState>(context, listen: false);
      appState.setUser(
          loginResponse['userID'],
          loginResponse['name'],
          loginResponse['email'] ?? _email.text // استخدام الايميل الراجع أو المدخل
      );

      print('✅ تسجيل الدخول ناجح: ${loginResponse['userID']}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تسجيل الدخول بنجاح')),
      );

      Navigator.pushReplacementNamed(context, Routes.home);

    } catch (e) {
      print('❌ فشل تسجيل الدخول: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe6eceb),
      body: SafeArea(
        // !! --- (التعديل هنا لإصلاح الـ Overflow) --- !!
        // 1. أضفنا Center و SingleChildScrollView
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                // 2. أزلنا mainAxisSize: MainAxisSize.min
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 250,
                    width: 250,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.account_circle, size: 100, color: Color(0xff4ab0d1)),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'تسجيل دخول المشرف',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff254865),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: TextStyle(color: Color(0xff254865)),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      labelStyle: TextStyle(color: Color(0xff254865)),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4ab0d1),
                        foregroundColor: const Color(0xff254865),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.adminSignup),
                      child: const Text(
                        'إنشاء حساب مشرف',
                        style: TextStyle(
                          color: Color(0xff4ab0d1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // !! --- (نهاية التعديل) --- !!
      ),
    );
  }
}