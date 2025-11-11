// // lib/screens/story_progress.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../widgets/app_scaffold.dart';
// import '../services/bluetooth_manager.dart'; // استيراد المدير الجديد
// import '../services/story_service.dart';
// import '../app_state.dart';
// import '../routes.dart';
//
// // =======================================================
// // الجزء الأول: كلاس الواجهة (StatefulWidget) - هذا الجزء كان ناقصًا
// // =======================================================
// class StoryProgressPage extends StatefulWidget {
//   const StoryProgressPage({super.key});
//
//   @override
//   State<StoryProgressPage> createState() => _StoryProgressPageState();
// }
//
//
// // =======================================================
// // الجزء الثاني: كلاس الحالة (State) - هذا الجزء يحتوي على كل الأكواد
// // =======================================================
// class _StoryProgressPageState extends State<StoryProgressPage> {
//   // الوصول إلى مدير البلوتوث مباشرة
//   final btManager = BluetoothManager.instance;
//
//   Map<String, dynamic> _storyData = {};
//   String _statusMessage = '...جاري تحميل القصة';
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//       if (args == null) {
//         _handleError('لم يتم استلام بيانات القصة');
//         return;
//       }
//       _updateStoryState(args);
//     });
//   }
//
//   void _updateStoryState(Map<String, dynamic> newStoryData) {
//     setState(() {
//       _storyData = newStoryData;
//       _isLoading = false;
//       // افترض أن الباك إند يرسل حقل question_mode عندما يكون هناك سؤال
//       final questionMode = _storyData['question_mode'];
//
//       if (questionMode != null && questionMode.isNotEmpty) {
//         _statusMessage = 'الآن! حرّك المكعب لاختيار المسار...';
//         _askQuestionAndListen(questionMode);
//       } else {
//         _statusMessage = 'استمر في مغامرتك...';
//         if (_storyData['finished'] == true) {
//           _statusMessage = 'النهاية! قصة رائعة.';
//         }
//       }
//     });
//   }
//
//   void _askQuestionAndListen(String mode) {
//     // التحقق من الاتصال
//     if (!btManager.isConnectedNotifier.value) {
//       _handleError('المكعب غير متصل. يرجى الاتصال به أولاً.');
//       return;
//     }
//
//     // إرسال الأمر للأردوينو
//     final command = "START $mode";
//     btManager.sendMessage(command);
//
//     // بدء الاستماع للجواب من الأردوينو
//     btManager.listenForAnswer((String answerFromCube) {
//       if (['RIGHT', 'LEFT', 'FORWARD', 'BACK', 'SHAKE'].contains(answerFromCube)) {
//         // إذا وصل الجواب، أرسله للباك إند
//         _sendAnswerToBackend(answerFromCube);
//       }
//     });
//   }
//
//   Future<void> _sendAnswerToBackend(String answer) async {
//     setState(() {
//       _isLoading = true;
//       _statusMessage = 'اختيار موفق! لنرى ماذا سيحدث بعد اختيار "$answer"...';
//     });
//     try {
//       final appState = Provider.of<AppState>(context, listen: false);
//       final response = await StoryService.continueStory(
//         _storyData['storyID'],
//         appState.currentUserID!,
//         appState.selectedChildID!,
//         answer,
//       );
//       _updateStoryState(response);
//     } catch (e) {
//       _handleError('فشل في متابعة القصة: $e');
//     }
//   }
//
//   void _handleError(String message) {
//     print('❌ $message');
//     if (mounted) {
//       Navigator.pushReplacementNamed(context, Routes.error, arguments: message);
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'مغامرة شيقة',
//       body: _isLoading
//       // --- في حالة التحميل: اعرض الدائرة في المنتصف ---
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             Text(
//               _statusMessage,
//               style: const TextStyle(fontSize: 18),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       )
//       // --- في حالة عرض القصة: استخدم أداة التمرير ---
//           : SingleChildScrollView(
//         child: Padding(
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
//                   onPressed: () => Navigator.pushNamedAndRemoveUntil(
//                       context, Routes.home, (route) => false),
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
// lib/screens/story_progress.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../widgets/app_scaffold.dart';
// import '../services/bluetooth_manager.dart'; // استيراد المدير الجديد
// import '../services/story_service.dart';
// import '../app_state.dart';
// import '../routes.dart';
//
// class StoryProgressPage extends StatefulWidget {
//   const StoryProgressPage({super.key});
//
//   @override
//   State<StoryProgressPage> createState() => _StoryProgressPageState();
// }
//
// class _StoryProgressPageState extends State<StoryProgressPage> {
//   final btManager = BluetoothManager.instance;
//
//   Map<String, dynamic> _storyData = {};
//   String _statusMessage = '...جاري تحميل القصة';
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//       if (args == null) {
//         _handleError('لم يتم استلام بيانات القصة');
//         return;
//       }
//       _updateStoryState(args);
//     });
//   }
//
//   // (1) تعديل: نضيف دالة لإيقاف الاستماع عند الخروج من الصفحة
//   // هذا يمنع تسرب الذاكرة ويوقف العمليات عند إغلاق الصفحة
//   @override
//   void dispose() {
//     btManager.stopListening();
//     super.dispose();
//   }
//
//   void _updateStoryState(Map<String, dynamic> newStoryData) {
//     // التأكد من أن الواجهة لا تزال موجودة قبل تحديث حالتها
//     if (!mounted) return;
//
//     setState(() {
//       _storyData = newStoryData;
//       _isLoading = false;
//       final questionMode = _storyData['question_mode'];
//
//       // التأكد من أن questionMode ليس null وليس "FINISH"
//       if (questionMode != null && questionMode.isNotEmpty && questionMode != "FINISH") {
//         _statusMessage = 'الآن! حرّك المكعب لاختيار المسار...';
//         _askQuestionAndListen(questionMode);
//       } else {
//         _statusMessage = 'استمر في مغامرتك...';
//         if (_storyData['finished'] == true) {
//           _statusMessage = 'النهاية! قصة رائعة.';
//         }
//       }
//     });
//   }
//
//   void _askQuestionAndListen(String mode) {
//     if (!btManager.isConnectedNotifier.value) {
//       _handleError('المكعب غير متصل. يرجى الاتصال به أولاً.');
//       return;
//     }
//
//     final command = "START $mode";
//
//     // (2) تعديل: نبدأ الاستماع قبل إرسال الأمر
//     // سيستلم هذا المستمع كل شيء يرسله الأردوينو
//     btManager.listenForAnswer((String answerFromCube) {
//
//       // (3) طباعة كل ما يصل (ممتاز لتصحيح الأخطاء)
//       print("Received from Cube: $answerFromCube");
//
//       // (4) الفلترة: نحن نهتم فقط بإجابات الحركة
//       // سيتجاهل هذا الشرط رسالة "READY:TILTZ" أو "READY:TILTY" ... الخ
//       if (['RIGHT', 'LEFT', 'FORWARD', 'BACK', 'SHAKE'].contains(answerFromCube)) {
//
//         // (5) !! مهم: إيقاف الاستماع فورًا بعد استلام الجواب الصحيح
//         btManager.stopListening();
//
//         // (6) إرسال الجواب للباك إند
//         _sendAnswerToBackend(answerFromCube);
//       }
//       // إذا كانت الرسالة "READY:TILTZ" سيتم طباعتها وتجاهلها، وسيبقى الاستماع فعال
//     });
//
//     // (7) إرسال الأمر للأردوينو (بعد بدء الاستماع)
//     btManager.sendMessage(command);
//   }
//
//   Future<void> _sendAnswerToBackend(String answer) async {
//     // (8) التأكد من أننا لا نزال في هذه الصفحة قبل تحديث الواجهة
//     if (!mounted) return;
//
//     setState(() {
//       _isLoading = true;
//       _statusMessage = 'اختيار موفق! لنرى ماذا سيحدث بعد اختيار "$answer"...';
//     });
//
//     try {
//       final appState = Provider.of<AppState>(context, listen: false);
//       final response = await StoryService.continueStory(
//         _storyData['storyID'],
//         appState.currentUserID!,
//         appState.selectedChildID!,
//         answer,
//       );
//
//       // (9) التأكد مرة أخرى قبل تحديث الواجهة
//       if (mounted) {
//         _updateStoryState(response);
//       }
//     } catch (e) {
//       _handleError('فشل في متابعة القصة: $e');
//     }
//   }
//
//   void _handleError(String message) {
//     print('❌ $message');
//     if (mounted) {
//       btManager.stopListening(); // (10) إيقاف الاستماع عند حدوث خطأ
//       Navigator.pushReplacementNamed(context, Routes.error, arguments: message);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'مغامرة شيقة',
//       body: _isLoading
//       // --- في حالة التحميل: اعرض الدائرة في المنتصف ---
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             Text(
//               _statusMessage,
//               style: const TextStyle(fontSize: 18),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       )
//       // --- في حالة عرض القصة: استخدم أداة التمرير ---
//           : SingleChildScrollView(
//         child: Padding(
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
//                   onPressed: () => Navigator.pushNamedAndRemoveUntil(
//                       context, Routes.home, (route) => false),
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
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/bluetooth_manager.dart';
// import '../services/api_service.dart';
// import '../app_state.dart'; // نحتاجه لجلب childId
//
// class StoryProgressScreen extends StatefulWidget {
//   final int storyId;
//   final String storyTitle; // أضفنا العنوان لعرضه
//
//   const StoryProgressScreen({
//     Key? key,
//     required this.storyId,
//     required this.storyTitle,
//   }) : super(key: key);
//
//   @override
//   State<StoryProgressScreen> createState() => _StoryProgressScreenState();
// }
//
// class _StoryProgressScreenState extends State<StoryProgressScreen> {
//   late ApiService _apiService;
//   late BluetoothManager _bleManager;
//   late AppState _appState;
//
//   String _storyText = "Loading story...";
//   String _statusText = "Connecting..."; // حالة للعرض
//   bool _isWaitingForMove = false;
//   String _currentMoveRequired = ""; // مثل TILT Y أو SHAKE
//   bool _isProcessing = false; // لمنع الطلبات المزدوجة
//
//   @override
//   void initState() {
//     super.initState();
//     _apiService = ApiService(); // (أو احصل عليه من Provider إذا كنت تستخدمه)
//     _bleManager = Provider.of<BluetoothManager>(context, listen: false);
//     _appState = Provider.of<AppState>(context, listen: false);
//
//     // !! إضافة المستمع !!
//     // استمع لأي ردود قادمة من المكعب
//     _bleManager.addListener(_onBleResponseReceived);
//
//     // التأكد من أننا متصلون قبل بدء القصة
//     if (!_bleManager.isConnected) {
//       _storyText = "CUBIE is not connected!";
//       _statusText = "Please go back and connect to CUBIE.";
//     } else {
//       _startStory();
//     }
//   }
//
//   @override
//   void dispose() {
//     // !! إزالة المستمع !!
//     _bleManager.removeListener(_onBleResponseReceived);
//     // إيقاف أي صوت عند الخروج
//     if (_bleManager.isConnected) {
//       _bleManager.sendCommand("STOP_AUDIO");
//     }
//     super.dispose();
//   }
//
//   // --- 1. بدء القصة ---
//   Future<void> _startStory() async {
//     if (_isProcessing) return;
//
//     setState(() {
//       _isProcessing = true;
//       _storyText = "Loading first part of the story...";
//       _statusText = "Starting story...";
//     });
//
//     try {
//       final storyData = await _apiService.startStory(
//         _appState.currentChild!.id, // (افترضت أن لديك currentChild في AppState)
//         widget.storyId,
//       );
//       // معالجة رد الباك اند (الذي يحتوي على الصوت والحركة المطلوبة)
//       _processBackendResponse(storyData);
//     } catch (e) {
//       setState(() {
//         _storyText = "Error starting story: $e";
//         _statusText = "Error";
//       });
//     } finally {
//       setState(() { _isProcessing = false; });
//     }
//   }
//
//   // --- 2. المستمع الرئيسي لردود البلوتوث ---
//   void _onBleResponseReceived() {
//     // (هذه الدالة يتم استدعاؤها من BluetoothManager في كل مرة يتغير _lastSensorResponse)
//     String response = _bleManager.lastSensorResponse;
//     if (response.isEmpty) return;
//
//     if (response.startsWith("AUDIO:FINISHED")) {
//       // انتهى تشغيل الصوت على المكعب
//       // إذا لم نكن ننتظر حركة، نرسل "NEXT" للباك اند
//       if (!_isWaitingForMove) {
//         print("Audio finished, and we are NOT waiting for a move. Sending 'NEXT'.");
//         _sendMoveToBackend("NEXT");
//       } else {
//         // انتهى الصوت، ونحن الآن ننتظر حركة من الطفل
//         print("Audio finished. Now waiting for move: $_currentMoveRequired");
//         setState(() {
//           _statusText = "Now... $_currentMoveRequired!";
//         });
//       }
//     }
//     else if (response.startsWith("READY:")) {
//       // المكعب جاهز لاستقبال الحركة (هذا الرد هو تأكيد فقط)
//       print("CUBIE is ready for move: ${response.substring(6)}");
//       setState(() {
//         _statusText = "Waiting for you to move CUBIE...";
//       });
//     }
//     else if (_isWaitingForMove) {
//       // كنا ننتظر حركة (مثل RIGHT, LEFT, SHAKE) ووصلت
//       // (نفترض أن الرد هو اسم الحركة مباشرة)
//       String move = response.trim().toUpperCase();
//       print("Sensor move '$move' received!");
//
//       // (اختياري: التحقق إذا كانت الحركة هي المطلوبة)
//       // if (move == _currentMoveRequired) {
//       //   _sendMoveToBackend(move);
//       // }
//
//       // سنقبل أي حركة تصل طالما نحن في وضع الانتظار
//       _sendMoveToBackend(move);
//     }
//   }
//
//   // --- 3. إرسال الحركة للباك اند ---
//   Future<void> _sendMoveToBackend(String move) async {
//     if (_isProcessing) return;
//
//     setState(() {
//       _isProcessing = true;
//       _isWaitingForMove = false; // أنهينا الانتظار
//       _storyText = "Great move! ($move). Let's see what happens next...";
//       _statusText = "Processing...";
//     });
//
//     try {
//       final storyData = await _apiService.processMove(
//         _appState.currentChild!.id,
//         widget.storyId,
//         move,
//       );
//       // معالجة الرد القادم من الباك اند
//       _processBackendResponse(storyData);
//
//     } catch (e) {
//       setState(() {
//         _storyText = "Error processing move: $e";
//         _statusText = "Error";
//       });
//     } finally {
//       setState(() { _isProcessing = false; });
//     }
//   }
//
//   // --- 4. معالجة رد الباك اند (تشغيل الصوت وطلب الحركة) ---
//   void _processBackendResponse(Map<String, dynamic> storyData) {
//     // (هذا يعتمد على شكل الـ JSON القادم من الباك اند)
//     // نفترض أنه يحتوي على: 'audio_url', 'text', 'required_move', 'story_end'
//
//     final String audioUrl = storyData['audio_url'];
//     final String text = storyData['text']; // النص للعرض على الشاشة
//     final String requiredMove = storyData['required_move']; // (e.g., "TILTZ", "SHAKE", "NONE")
//     final bool storyEnd = storyData['story_end'] ?? false; // التأكد من وجود مفتاح نهاية القصة
//
//     setState(() {
//       _storyText = text; // عرض النص الجديد
//     });
//
//     // 1. هل انتهت القصة؟
//     if (storyEnd) {
//       setState(() {
//         _statusText = "The End!";
//         _isWaitingForMove = false;
//       });
//       // (اختياري: تشغيل صوت النهاية إذا وجد)
//       if (audioUrl.isNotEmpty) {
//         _bleManager.sendCommand("PLAY:$audioUrl");
//       }
//       return; // إنهاء الدالة
//     }
//
//     // 2. أرسل أمر تشغيل الصوت إلى المكعب (إذا لم تنته القصة)
//     if (audioUrl.isNotEmpty) {
//       _bleManager.sendCommand("PLAY:$audioUrl");
//       setState(() { _statusText = "Listening..."; });
//     }
//
//     // 3. هل الباك اند يطلب حركة من الطفل؟
//     if (requiredMove != "NONE" && requiredMove.isNotEmpty) {
//       setState(() {
//         _isWaitingForMove = true;
//         _currentMoveRequired = requiredMove;
//         // سيتم تحديث _statusText إلى "Waiting for move..." بعد انتهاء الصوت (في _onBleResponseReceived)
//       });
//
//       // 4. أرسل الأمر للمكعب ليكون مستعداً لرصد الحركة
//       _bleManager.sendCommand("START $requiredMove"); // e.g., "START TILTZ"
//
//     } else {
//       // القصة لا تتطلب حركة، ستستمر بعد انتهاء الصوت
//       // (سيتم التعامل معها عند استقبال "AUDIO:FINISHED" في _onBleResponseReceived)
//       setState(() {
//         _isWaitingForMove = false;
//         _currentMoveRequired = "";
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // مراقبة حالة الاتصال بالبلوتوث
//     bool isBleConnected = context.watch<BluetoothManager>().isConnected;
//
//     if (!isBleConnected) {
//       // إذا انقطع الاتصال أثناء القصة
//       _storyText = "Connection Lost!";
//       _statusText = "Please reconnect to CUBIE.";
//       _isWaitingForMove = false;
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.storyTitle),
//         backgroundColor: isBleConnected ? Colors.blue.shade700 : Colors.red,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Icon(isBleConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
//           ),
//         ],
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // (يمكنك وضع صورة هنا)
//             // Image.asset('assets/story_icon.png', height: 150),
//
//             SizedBox(height: 30),
//
//             // --- حالة القصة ---
//             Text(
//               _statusText,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: _isWaitingForMove ? Colors.orange.shade700 : Colors.blue.shade800,
//               ),
//             ),
//
//             SizedBox(height: 20),
//
//             // --- نص القصة ---
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Text(
//                   _storyText,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 20, height: 1.5),
//                 ),
//               ),
//             ),
//
//             SizedBox(height: 20),
//
//             // --- مؤشر التحميل ---
//             if (_isProcessing) CircularProgressIndicator(),
//
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/bluetooth_manager.dart';
// import '../services/api_service.dart';
// import '../app_state.dart'; // نحتاجه لجلب childId
//
// class StoryProgressScreen extends StatefulWidget {
//   final int storyId;
//   final String storyTitle; // أضفنا العنوان لعرضه
//
//   const StoryProgressScreen({
//     Key? key,
//     required this.storyId,
//     required this.storyTitle,
//   }) : super(key: key);
//
//   @override
//   State<StoryProgressScreen> createState() => _StoryProgressScreenState();
// }
//
// class _StoryProgressScreenState extends State<StoryProgressScreen> {
//   late ApiService _apiService;
//   late BluetoothManager _bleManager;
//   late AppState _appState;
//
//   String _storyText = "Loading story...";
//   String _statusText = "Connecting..."; // حالة للعرض
//   bool _isWaitingForMove = false;
//   String _currentMoveRequired = ""; // مثل TILT Y أو SHAKE
//   bool _isProcessing = false; // لمنع الطلبات المزدوجة
//
//   @override
//   void initState() {
//     super.initState();
//     _apiService = ApiService(); // (أو احصل عليه من Provider إذا كنت تستخدمه)
//     _bleManager = Provider.of<BluetoothManager>(context, listen: false);
//     _appState = Provider.of<AppState>(context, listen: false);
//
//     // !! إضافة المستمع !!
//     // استمع لأي ردود قادمة من المكعب
//     _bleManager.addListener(_onBleResponseReceived);
//
//     // التأكد من أننا متصلون قبل بدء القصة
//     if (!_bleManager.isConnected) {
//       _storyText = "CUBIE is not connected!";
//       _statusText = "Please go back and connect to CUBIE.";
//     } else {
//       _startStory();
//     }
//   }
//
//   @override
//   void dispose() {
//     // !! إزالة المستمع !!
//     _bleManager.removeListener(_onBleResponseReceived);
//     // إيقاف أي صوت عند الخروج
//     if (_bleManager.isConnected) {
//       _bleManager.sendCommand("STOP_AUDIO");
//     }
//     super.dispose();
//   }
//
//   // --- 1. بدء القصة ---
//   Future<void> _startStory() async {
//     if (_isProcessing) return;
//
//     // !! --- (تصحيح الخطأ هنا) --- !!
//     // التأكد من وجود طفل مختار
//     if (_appState.currentChild == null) {
//       setState(() {
//         _storyText = "Error: No child selected.";
//         _statusText = "Please select a child profile first.";
//       });
//       return;
//     }
//     // !! --- (نهاية التصحيح) --- !!
//
//     setState(() {
//       _isProcessing = true;
//       _storyText = "Loading first part of the story...";
//       _statusText = "Starting story...";
//     });
//
//     try {
//       // !! --- (تصحيح الخطأ هنا) --- !!
//       // تم تغيير .id إلى ['id']
//       final int childId = _appState.currentChild!['id'];
//       // !! --- (نهاية التصحيح) --- !!
//
//       final storyData = await _apiService.startStory(
//         childId,
//         widget.storyId,
//       );
//       // معالجة رد الباك اند (الذي يحتوي على الصوت والحركة المطلوبة)
//       _processBackendResponse(storyData);
//
//     } catch (e) {
//       setState(() {
//         _storyText = "Error starting story: $e";
//         _statusText = "Error";
//       });
//     } finally {
//       setState(() { _isProcessing = false; });
//     }
//   }
//
//   // --- 2. المستمع الرئيسي لردود البلوتوث ---
//   void _onBleResponseReceived() {
//     // (هذه الدالة يتم استدعاؤها من BluetoothManager في كل مرة يتغير _lastSensorResponse)
//     String response = _bleManager.lastSensorResponse;
//     if (response.isEmpty) return;
//
//     if (response.startsWith("AUDIO:FINISHED")) {
//       // انتهى تشغيل الصوت على المكعب
//       // إذا لم نكن ننتظر حركة، نرسل "NEXT" للباك اند
//       if (!_isWaitingForMove) {
//         print("Audio finished, and we are NOT waiting for a move. Sending 'NEXT'.");
//         _sendMoveToBackend("NEXT");
//       } else {
//         // انتهى الصوت، ونحن الآن ننتظر حركة من الطفل
//         print("Audio finished. Now waiting for move: $_currentMoveRequired");
//         setState(() {
//           _statusText = "Now... $_currentMoveRequired!";
//         });
//       }
//     }
//     else if (response.startsWith("READY:")) {
//       // المكعب جاهز لاستقبال الحركة (هذا الرد هو تأكيد فقط)
//       print("CUBIE is ready for move: ${response.substring(6)}");
//       setState(() {
//         _statusText = "Waiting for you to move CUBIE...";
//       });
//     }
//     else if (_isWaitingForMove) {
//       // كنا ننتظر حركة (مثل RIGHT, LEFT, SHAKE) ووصلت
//       // (نفترض أن الرد هو اسم الحركة مباشرة)
//       String move = response.trim().toUpperCase();
//       print("Sensor move '$move' received!");
//
//       // (اختياري: التحقق إذا كانت الحركة هي المطلوبة)
//       // if (move == _currentMoveRequired) {
//       //   _sendMoveToBackend(move);
//       // }
//
//       // سنقبل أي حركة تصل طالما نحن في وضع الانتظار
//       _sendMoveToBackend(move);
//     }
//   }
//
//   // --- 3. إرسال الحركة للباك اند ---
//   Future<void> _sendMoveToBackend(String move) async {
//     if (_isProcessing) return;
//
//     // !! --- (تصحيح الخطأ هنا) --- !!
//     if (_appState.currentChild == null) {
//       print("Error: currentChild is null, can't send move.");
//       return;
//     }
//     final int childId = _appState.currentChild!['id'];
//     // !! --- (نهاية التصحيح) --- !!
//
//
//     setState(() {
//       _isProcessing = true;
//       _isWaitingForMove = false; // أنهينا الانتظار
//       _storyText = "Great move! ($move). Let's see what happens next...";
//       _statusText = "Processing...";
//     });
//
//     try {
//       final storyData = await _apiService.processMove(
//         childId,
//         widget.storyId,
//         move,
//       );
//       // معالجة الرد القادم من الباك اند
//       _processBackendResponse(storyData);
//
//     } catch (e) {
//       setState(() {
//         _storyText = "Error processing move: $e";
//         _statusText = "Error";
//       });
//     } finally {
//       setState(() { _isProcessing = false; });
//     }
//   }
//
//   // --- 4. معالجة رد الباك اند (تشغيل الصوت وطلب الحركة) ---
//   void _processBackendResponse(Map<String, dynamic> storyData) {
//     // (هذا يعتمد على شكل الـ JSON القادم من الباك اند)
//     // نفترض أنه يحتوي على: 'audio_url', 'text', 'required_move', 'story_end'
//
//     final String audioUrl = storyData['audio_url'];
//     final String text = storyData['text']; // النص للعرض على الشاشة
//     final String requiredMove = storyData['required_move']; // (e.g., "TILTZ", "SHAKE", "NONE")
//     final bool storyEnd = storyData['story_end'] ?? false; // التأكد من وجود مفتاح نهاية القصة
//
//     setState(() {
//       _storyText = text; // عرض النص الجديد
//     });
//
//     // 1. هل انتهت القصة؟
//     if (storyEnd) {
//       setState(() {
//         _statusText = "The End!";
//         _isWaitingForMove = false;
//       });
//       // (اختياري: تشغيل صوت النهاية إذا وجد)
//       if (audioUrl.isNotEmpty) {
//         _bleManager.sendCommand("PLAY:$audioUrl");
//       }
//       return; // إنهاء الدالة
//     }
//
//     // 2. أرسل أمر تشغيل الصوت إلى المكعب (إذا لم تنته القصة)
//     if (audioUrl.isNotEmpty) {
//       _bleManager.sendCommand("PLAY:$audioUrl");
//       setState(() { _statusText = "Listening..."; });
//     }
//
//     // 3. هل الباك اند يطلب حركة من الطفل؟
//     if (requiredMove != "NONE" && requiredMove.isNotEmpty) {
//       setState(() {
//         _isWaitingForMove = true;
//         _currentMoveRequired = requiredMove;
//         // سيتم تحديث _statusText إلى "Waiting for move..." بعد انتهاء الصوت (في _onBleResponseReceived)
//       });
//
//       // 4. أرسل الأمر للمكعب ليكون مستعداً لرصد الحركة
//       _bleManager.sendCommand("START $requiredMove"); // e.g., "START TILTZ"
//
//     } else {
//       // القصة لا تتطلب حركة، ستستمر بعد انتهاء الصوت
//       // (سيتم التعامل معها عند استقبال "AUDIO:FINISHED" في _onBleResponseReceived)
//       setState(() {
//         _isWaitingForMove = false;
//         _currentMoveRequired = "";
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // مراقبة حالة الاتصال بالبلوتوث
//     bool isBleConnected = context.watch<BluetoothManager>().isConnected;
//
//     if (!isBleConnected && mounted) {
//       // إذا انقطع الاتصال أثناء القصة
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         setState(() {
//           _storyText = "Connection Lost!";
//           _statusText = "Please reconnect to CUBIE.";
//           _isWaitingForMove = false;
//         });
//       });
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.storyTitle),
//         backgroundColor: isBleConnected ? Colors.blue.shade700 : Colors.red,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Icon(isBleConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
//           ),
//         ],
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // (يمكنك وضع صورة هنا)
//             // Image.asset('assets/story_icon.png', height: 150),
//
//             SizedBox(height: 30),
//
//             // --- حالة القصة ---
//             Text(
//               _statusText,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: _isWaitingForMove ? Colors.orange.shade700 : Colors.blue.shade800,
//               ),
//             ),
//
//             SizedBox(height: 20),
//
//             // --- نص القصة ---
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Text(
//                   _storyText,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 20, height: 1.5),
//                 ),
//               ),
//             ),
//
//             SizedBox(height: 20),
//
//             // --- مؤشر التحميل ---
//             if (_isProcessing) CircularProgressIndicator(),
//
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../services/story_service.dart'; // (تم التغيير لاستخدام StoryService)
import '../app_state.dart';

class StoryProgressScreen extends StatefulWidget {
  // (لم نعد بحاجة لـ storyId أو storyTitle هنا)
  // (سيتم جلبهما من AppState)

  const StoryProgressScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<StoryProgressScreen> createState() => _StoryProgressScreenState();
}

class _StoryProgressScreenState extends State<StoryProgressScreen> {
  late BluetoothManager _bleManager;
  late AppState _appState;

  String _storyText = "Loading story...";
  String _statusText = "Connecting..."; // حالة للعرض
  bool _isWaitingForMove = false;
  String _currentMoveRequired = ""; // مثل TILT Y أو SHAKE
  bool _isProcessing = false; // لمنع الطلبات المزدوجة

  // (متغيرات لحفظ بيانات القصة الحالية)
  int? _currentStoryID;
  int? _currentUserID;
  int? _currentChildID;

  @override
  void initState() {
    super.initState();
    _bleManager = Provider.of<BluetoothManager>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);

    // !! إضافة المستمع !!
    _bleManager.addListener(_onBleResponseReceived);

    // التأكد من أننا متصلون قبل بدء القصة
    if (!_bleManager.isConnected) {
      _storyText = "CUBIE is not connected!";
      _statusText = "Please go back and connect to CUBIE.";
      return;
    }

    // (جلب البيانات من AppState)
    _currentStoryID = _appState.currentStoryID;
    _currentUserID = _appState.currentUserID;
    _currentChildID = _appState.selectedChildID;

    if (_currentStoryID == null || _currentUserID == null || _currentChildID == null) {
      _storyText = "Error: No story or user selected!";
      _statusText = "Please go back and start a story.";
      return;
    }

    // (البدء الفعلي للقصة)
    _startStoryPlayback();
  }

  @override
  void dispose() {
    // !! إزالة المستمع !!
    _bleManager.removeListener(_onBleResponseReceived);
    // إيقاف أي صوت عند الخروج
    if (_bleManager.isConnected) {
      _bleManager.sendCommand("STOP_AUDIO");
    }
    super.dispose();
  }

  // --- 1. بدء (إعادة) تشغيل القصة ---
  Future<void> _startStoryPlayback() async {
    if (_isProcessing || _currentStoryID == null) return;

    setState(() {
      _isProcessing = true;
      _storyText = "Loading first part of the story...";
      _statusText = "Starting story...";
    });

    try {
      // (استدعاء replayStory من StoryService)
      final storyData = await StoryService.replayStory(_currentStoryID!);

      // (الباك اند يرد بمصفوفة من الأحداث، نأخذ أول حدث)
      if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
        _processBackendResponse(storyData['events'][0]);
      } else {
        throw Exception("No events found for this story.");
      }

    } catch (e) {
      setState(() {
        _storyText = "Error starting story: $e";
        _statusText = "Error";
      });
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  // --- 2. المستمع الرئيسي لردود البلوتوث ---
  void _onBleResponseReceived() {
    String response = _bleManager.lastSensorResponse;
    if (response.isEmpty) return;

    if (response.startsWith("AUDIO:FINISHED")) {
      // انتهى تشغيل الصوت على المكعب
      if (!_isWaitingForMove) {
        print("Audio finished, and we are NOT waiting for a move. Sending 'NEXT'.");
        // (نرسل "NEXT" كحركة افتراضية)
        _sendMoveToBackend("NEXT");
      } else {
        // انتهى الصوت، ونحن الآن ننتظر حركة من الطفل
        print("Audio finished. Now waiting for move: $_currentMoveRequired");
        setState(() {
          _statusText = "Now... $_currentMoveRequired!";
        });
      }
    }
    else if (response.startsWith("READY:")) {
      print("CUBIE is ready for move: ${response.substring(6)}");
      setState(() {
        _statusText = "Waiting for you to move CUBIE...";
      });
    }
    else if (_isWaitingForMove) {
      // كنا ننتظر حركة (مثل RIGHT, LEFT, SHAKE) ووصلت
      String move = response.trim().toUpperCase();
      print("Sensor move '$move' received!");
      _sendMoveToBackend(move);
    }
  }

  // --- 3. إرسال الحركة للباك اند ---
  Future<void> _sendMoveToBackend(String move) async {
    if (_isProcessing || _currentStoryID == null || _currentUserID == null || _currentChildID == null) return;

    setState(() {
      _isProcessing = true;
      _isWaitingForMove = false; // أنهينا الانتظار
      _storyText = "Great move! ($move). Let's see what happens next...";
      _statusText = "Processing...";
    });

    try {
      // (استدعاء continueStory من StoryService)
      final storyData = await StoryService.continueStory(
        _currentStoryID!,
        _currentUserID!,
        _currentChildID!,
        move, // (إرسال الحركة كـ "answer")
      );

      _processBackendResponse(storyData);

    } catch (e) {
      setState(() {
        _storyText = "Error processing move: $e";
        _statusText = "Error";
      });
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  // --- 4. معالجة رد الباك اند (تشغيل الصوت وطلب الحركة) ---
  void _processBackendResponse(Map<String, dynamic> storyData) {
    // (هذا يعتمد على شكل الـ JSON القادم من الباك اند)
    // (نفترض أنه يحتوي على: 'audio_url', 'text', 'required_move', 'story_end')

    final String audioUrl = storyData['audio_url'] ?? '';
    final String text = storyData['text'] ?? '...'; // النص للعرض على الشاشة
    final String requiredMove = storyData['required_move'] ?? 'NONE'; // (e.g., "TILTZ", "SHAKE", "NONE")
    final bool storyEnd = storyData['story_end'] ?? false;

    setState(() {
      _storyText = text; // عرض النص الجديد
    });

    // 1. هل انتهت القصة؟
    if (storyEnd) {
      setState(() {
        _statusText = "The End!";
        _isWaitingForMove = false;
      });
      if (audioUrl.isNotEmpty) {
        _bleManager.sendCommand("PLAY:$audioUrl");
      }
      return; // إنهاء الدالة
    }

    // 2. أرسل أمر تشغيل الصوت إلى المكعب
    if (audioUrl.isNotEmpty) {
      _bleManager.sendCommand("PLAY:$audioUrl");
      setState(() { _statusText = "Listening..."; });
    } else {
      // (إذا لم يكن هناك صوت، ننتقل للخطوة التالية فوراً)
      // (هذه الحالة قد لا تحدث، لكن للاحتياط)
      if (requiredMove == "NONE" || requiredMove.isEmpty) {
        _sendMoveToBackend("NEXT"); // (اطلب المقطع التالي)
      }
    }


    // 3. هل الباك اند يطلب حركة من الطفل؟
    if (requiredMove != "NONE" && requiredMove.isNotEmpty) {
      setState(() {
        _isWaitingForMove = true;
        _currentMoveRequired = requiredMove;
        // (سيتم تحديث النص عند انتهاء الصوت)
      });

      // 4. أرسل الأمر للمكعب ليكون مستعداً لرصد الحركة
      _bleManager.sendCommand("START $requiredMove"); // e.g., "START TILTZ"

    } else {
      // القصة لا تتطلب حركة، ستستمر بعد انتهاء الصوت
      setState(() {
        _isWaitingForMove = false;
        _currentMoveRequired = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة حالة الاتصال بالبلوتوث
    bool isBleConnected = context.watch<BluetoothManager>().isConnected;
    String storyTitle = _appState.currentStoryTitle ?? "Story";

    if (!isBleConnected) {
      // إذا انقطع الاتصال أثناء القصة
      _storyText = "Connection Lost!";
      _statusText = "Please reconnect to CUBIE.";
      _isWaitingForMove = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(storyTitle), // (عرض عنوان القصة من AppState)
        backgroundColor: isBleConnected ? Colors.blue.shade700 : Colors.red,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(isBleConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // (يمكنك وضع صورة هنا)
            // Image.asset('assets/story_icon.png', height: 150),

            SizedBox(height: 30),

            // --- حالة القصة ---
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isWaitingForMove ? Colors.orange.shade700 : Colors.blue.shade800,
              ),
            ),

            SizedBox(height: 20),

            // --- نص القصة ---
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _storyText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, height: 1.5),
                ),
              ),
            ),

            SizedBox(height: 20),

            // --- مؤشر التحميل ---
            if (_isProcessing) CircularProgressIndicator(),

          ],
        ),
      ),
    );
  }
}