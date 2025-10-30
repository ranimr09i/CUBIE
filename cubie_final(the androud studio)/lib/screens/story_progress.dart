// lib/screens/story_progress.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../services/bluetooth_manager.dart'; // استيراد المدير الجديد
import '../services/story_service.dart';
import '../app_state.dart';
import '../routes.dart';

// =======================================================
// الجزء الأول: كلاس الواجهة (StatefulWidget) - هذا الجزء كان ناقصًا
// =======================================================
class StoryProgressPage extends StatefulWidget {
  const StoryProgressPage({super.key});

  @override
  State<StoryProgressPage> createState() => _StoryProgressPageState();
}


// =======================================================
// الجزء الثاني: كلاس الحالة (State) - هذا الجزء يحتوي على كل الأكواد
// =======================================================
class _StoryProgressPageState extends State<StoryProgressPage> {
  // الوصول إلى مدير البلوتوث مباشرة
  final btManager = BluetoothManager.instance;

  Map<String, dynamic> _storyData = {};
  String _statusMessage = '...جاري تحميل القصة';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        _handleError('لم يتم استلام بيانات القصة');
        return;
      }
      _updateStoryState(args);
    });
  }

  void _updateStoryState(Map<String, dynamic> newStoryData) {
    setState(() {
      _storyData = newStoryData;
      _isLoading = false;
      // افترض أن الباك إند يرسل حقل question_mode عندما يكون هناك سؤال
      final questionMode = _storyData['question_mode'];

      if (questionMode != null && questionMode.isNotEmpty) {
        _statusMessage = 'الآن! حرّك المكعب لاختيار المسار...';
        _askQuestionAndListen(questionMode);
      } else {
        _statusMessage = 'استمر في مغامرتك...';
        if (_storyData['finished'] == true) {
          _statusMessage = 'النهاية! قصة رائعة.';
        }
      }
    });
  }

  void _askQuestionAndListen(String mode) {
    // التحقق من الاتصال
    if (!btManager.isConnectedNotifier.value) {
      _handleError('المكعب غير متصل. يرجى الاتصال به أولاً.');
      return;
    }

    // إرسال الأمر للأردوينو
    final command = "START $mode";
    btManager.sendMessage(command);

    // بدء الاستماع للجواب من الأردوينو
    btManager.listenForAnswer((String answerFromCube) {
      if (['RIGHT', 'LEFT', 'FORWARD', 'BACK', 'SHAKE'].contains(answerFromCube)) {
        // إذا وصل الجواب، أرسله للباك إند
        _sendAnswerToBackend(answerFromCube);
      }
    });
  }

  Future<void> _sendAnswerToBackend(String answer) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'اختيار موفق! لنرى ماذا سيحدث بعد اختيار "$answer"...';
    });
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final response = await StoryService.continueStory(
        _storyData['storyID'],
        appState.currentUserID!,
        appState.selectedChildID!,
        answer,
      );
      _updateStoryState(response);
    } catch (e) {
      _handleError('فشل في متابعة القصة: $e');
    }
  }

  void _handleError(String message) {
    print('❌ $message');
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.error, arguments: message);
    }
  }
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'مغامرة شيقة',
      body: _isLoading
      // --- في حالة التحميل: اعرض الدائرة في المنتصف ---
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
      // --- في حالة عرض القصة: استخدم أداة التمرير ---
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _storyData['part'] ?? 'لا يوجد نص لعرضه',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, height: 1.5),
              ),
              const SizedBox(height: 40),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff254865),
                ),
              ),
              if (_storyData['finished'] == true) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, Routes.home, (route) => false),
                  child: const Text('العودة للصفحة الرئيسية'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'مغامرة شيقة',
//       body: Center(
//         child: _isLoading
//             ? Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             Text(_statusMessage, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
//           ],
//         )
//             : Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 _storyData['part'] ?? 'لا يوجد نص لعرضه',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 22, height: 1.5),
//               ),
//               const SizedBox(height: 40),
//               Text(
//                 _statusMessage,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xff254865),
//                 ),
//               ),
//               if (_storyData['finished'] == true) ...[
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
//                   child: const Text('العودة للصفحة الرئيسية'),
//                 ),
//               ]
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }