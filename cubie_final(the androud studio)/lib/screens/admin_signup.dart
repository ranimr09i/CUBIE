
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

      // 1. طلب التسجيل (الخدمة تتكفل بتحويل البيانات إلى Form)
      await AuthService.signup(
          _name.text,
          _email.text,
          _pass.text
      );

      print('✅ التسجيل ناجح، جاري تسجيل الدخول...');

      // 2. تسجيل الدخول تلقائياً بعد إنشاء الحساب
      final loginResponse = await AuthService.login(_email.text, _pass.text);


      print('✅ تسجيل الدخول ناجح: $loginResponse');

      // 3. حفظ بيانات المستخدم في التطبيق
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setUser(
          loginResponse['userID'],
          loginResponse['name'],
          loginResponse['email'] ?? _email.text // استخدام الايميل الراجع أو المدخل
      );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إنشاء الحساب بنجاح')),
      );

      // 4. التوجيه للصفحة الرئيسية
      Navigator.pushReplacementNamed(context, Routes.home);

    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      String errorMessage = 'فشل إنشاء الحساب';

      if (e.toString().contains('Email already exists')) {
        errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
      } else if (e.toString().contains('422')) {
        errorMessage = 'بيانات غير صالحة (422). تأكد من المدخلات.';
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff254865))
              ),
              const SizedBox(height: 20),

              TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.person),
                  )
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock),
                  )
              ),
              const SizedBox(height: 12),

              TextField(
                  controller: _confirmPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock_outline),
                  )
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4ab0d1),
                    foregroundColor: const Color(0xff254865),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إنشاء الحساب'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
              ),
            ],
          ),
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