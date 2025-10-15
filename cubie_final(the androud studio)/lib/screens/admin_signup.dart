import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../app_state.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    if (_pass.text != _confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور غير متطابقة')),
      );
      return;
    }

    if (_pass.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔄 بدء عملية التسجيل...');

      final signupResponse = await AuthService.signup(
          _name.text,
          _email.text,
          _pass.text
      );

      print('✅ التسجيل ناجح: $signupResponse');

      print('🔄 محاولة تسجيل الدخول...');
      final loginResponse = await AuthService.login(_email.text, _pass.text);

      print('✅ تسجيل الدخول ناجح: $loginResponse');

      final appState = Provider.of<AppState>(context, listen: false);
      appState.setUser(loginResponse['userID'], loginResponse['name']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إنشاء الحساب وتسجيل الدخول بنجاح')),
      );

      Navigator.pushReplacementNamed(context, Routes.home);

    } catch (e) {
      print('❌ خطأ مفصل: $e');

      String errorMessage;

      if (e.toString().contains('Email already exists')) {
        errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
      } else if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'تم التسجيل لكن كلمة المرور خطأ - جرب تسجيل الدخول يدوياً';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'خطأ في الاتصال بالخادم';
      } else {
        errorMessage = 'فشل إنشاء الحساب: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إنشاء حساب مشرف',
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
                'إنشاء حساب مشرف',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),

            TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                )
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),

            TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                )
            ),
            const SizedBox(height: 8),

            TextField(
                controller: _confirmPass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                )
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4ab0d1),
                  foregroundColor: const Color(0xff254865),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إنشاء وحفظ'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لديك حساب؟ تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }
}