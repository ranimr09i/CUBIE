import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../routes.dart';

class ErrorPage extends StatefulWidget {
  const ErrorPage({super.key});

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  String _errorMessage = 'حدث خطأ غير متوقع';
  String _errorDetails = '';

  @override
  void initState() {
    super.initState();
    _loadErrorDetails();
  }

  void _loadErrorDetails() {
    // يمكنك إضافة منطق لتحميل تفاصيل الخطأ من arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      if (args is String) {
        setState(() {
          _errorMessage = args;
        });
      } else if (args is Map) {
        final dynamicArgs = args as Map<dynamic, dynamic>;
        final convertedArgs = <String, dynamic>{};

        dynamicArgs.forEach((key, value) {
          convertedArgs[key.toString()] = value;
        });

        setState(() {
          _errorMessage = convertedArgs['message']?.toString() ?? 'حدث خطأ غير متوقع';
          _errorDetails = convertedArgs['details']?.toString() ?? '';
        });
      }
    }
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.home,
          (route) => false,
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _goHome();
    }
  }

  void _reportError() {
    // هنا يمكنك إضافة منطق للإبلاغ عن الخطأ
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإبلاغ عن الخطأ'),
        content: const Text('شكراً للإبلاغ عن هذا الخطأ. سيتم مراجعته قريباً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'حدث خطأ',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff254865),
                ),
                textAlign: TextAlign.center,
              ),
              if (_errorDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xfff5f5f5),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _errorDetails,
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'نعتذر للإزعاج، يرجى المحاولة مرة أخرى أو الاتصال بالدعم',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4ab0d1),
                        foregroundColor: const Color(0xff254865),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('العودة'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff254865),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('الصفحة الرئيسية'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reportError,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('الإبلاغ عن الخطأ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'نصائح استكشاف الأخطاء:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff254865),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          '• تحقق من اتصال الإنترنت\n• أعد تشغيل التطبيق\n• تأكد من تسجيل الدخول',
                          style: TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}