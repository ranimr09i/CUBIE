
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
        backgroundColor: isBleConnected ?  Color(0xff254865) : Colors.red,
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