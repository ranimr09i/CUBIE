import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';

class ConnectCubePage extends StatelessWidget {
  const ConnectCubePage({super.key});

  void _connectToCube(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 جاري الاتصال بالمكعب...'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم الاتصال بالمكعب بنجاح'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _testConnection(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 جاري اختبار الاتصال...'),
        duration: Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ الاتصال يعمل بشكل صحيح'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الاتصال بالمكعب',
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.bluetooth,
              size: 80,
              color: Color(0xff4ab0d1),
            ),
            const SizedBox(height: 16),
            const Text(
              'اتصل بالمكعب الذكي',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff254865),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'قم بالاتصال بالمكعب التفاعلي لبدء رحلة القصص',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.bluetooth_searching, size: 36, color: Color(0xff4ab0d1)),
                title: const Text(
                  'Cube-ESP32',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff254865)),
                ),
                subtitle: const Text('قابل للاتصال - قوة الإشارة: ممتاز'),
                trailing: ElevatedButton(
                  onPressed: () => _connectToCube(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4ab0d1),
                    foregroundColor: const Color(0xff254865),
                  ),
                  child: const Text('اتصال'),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              color: const Color(0xffe6eceb),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تعليمات الاتصال:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff254865),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInstruction('1. تأكد من تشغيل البلوتوث'),
                    _buildInstruction('2. قرب الجهاز من المكعب'),
                    _buildInstruction('3. انقر على زر "اتصال"'),
                    _buildInstruction('4. انتظر حتى يكتمل الاتصال'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testConnection(context),
                    icon: const Icon(Icons.settings_input_antenna),
                    label: const Text('اختبار الاتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff8dd6bb),
                      foregroundColor: const Color(0xff254865),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4ab0d1),
                      foregroundColor: const Color(0xff254865),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xff4ab0d1)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}