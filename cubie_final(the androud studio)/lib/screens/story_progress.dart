//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/bluetooth_manager.dart';
// import '../services/story_service.dart';
// import '../app_state.dart';
//
// class StoryProgressScreen extends StatefulWidget {
//   const StoryProgressScreen({Key? key}) : super(key: key);
//
//   @override
//   State<StoryProgressScreen> createState() => _StoryProgressScreenState();
// }
//
// class _StoryProgressScreenState extends State<StoryProgressScreen> {
//   late BluetoothManager _bleManager;
//   late AppState _appState;
//
//   String _storyText = "Loading story...";
//   String _statusText = "Connecting...";
//
//   bool _isWaitingForMove = false;
//   String _currentMoveRequired = "";
//   String _pendingMove = "";
//   bool _isProcessing = false;
//
//   // !! إعدادات السيرفر !!
//   // تأكد أن هذا الـ IP هو نفس IP جهازك (MacBook)
//   // إذا كنت تشغل السيرفر على port 80، اتركه كما هو.
//   // إذا كنت تشغله على 8000، أضف :8000 في النهاية (مثلاً: http://192.168.8.22:8000)
//   final String _serverBaseUrl = "http://192.168.8.22";
//
//   int? _currentStoryID;
//   int? _currentUserID;
//   int? _currentChildID;
//
//   @override
//   void initState() {
//     super.initState();
//     _bleManager = Provider.of<BluetoothManager>(context, listen: false);
//     _appState = Provider.of<AppState>(context, listen: false);
//     _bleManager.addListener(_onBleResponseReceived);
//
//     if (!_bleManager.isConnected) {
//       setState(() {
//         _storyText = "CUBIE is not connected!";
//         _statusText = "Connection Error";
//       });
//       return;
//     }
//
//     _currentStoryID = _appState.currentStoryID;
//     _currentUserID = _appState.currentUserID;
//     _currentChildID = _appState.selectedChildID;
//
//     _startStoryPlayback();
//   }
//
//   @override
//   void dispose() {
//     _bleManager.removeListener(_onBleResponseReceived);
//     super.dispose();
//   }
//
//   // بدء تشغيل القصة (إعادة التشغيل أو البداية)
//   Future<void> _startStoryPlayback() async {
//     if (_isProcessing || _currentStoryID == null) return;
//     setState(() {
//       _isProcessing = true;
//       _statusText = "Starting...";
//     });
//     try {
//       final storyData = await StoryService.replayStory(_currentStoryID!);
//       if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
//         _processBackendResponse(storyData['events'][0]);
//       } else {
//         _processBackendResponse(storyData);
//       }
//     } catch (e) {
//       setState(() {
//         _statusText = "Error loading story";
//         print("Error in startStory: $e");
//       });
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }
//
//   // استقبال ردود الأردوينو (البلوتوث)
//   void _onBleResponseReceived() {
//     String response = _bleManager.lastSensorResponse;
//     if (response.isEmpty) return;
//
//     // عند انتهاء الصوت (سواء نجح أو فشل وتم التعامل معه في الاردوينو)
//     if (response.startsWith("AUDIO:FINISHED")) {
//       print("Audio finished logic triggered.");
//
//       if (_pendingMove.isNotEmpty && _pendingMove != "NONE") {
//         // الصوت انتهى، نطلب من الطفل الحركة الآن
//         _bleManager.sendCommand("START $_pendingMove");
//         setState(() {
//           _statusText = "Your Turn! $_currentMoveRequired";
//           _isWaitingForMove = true;
//           _pendingMove = ""; // مسح الحركة المعلقة لأننا بدأناها
//         });
//       } else {
//         // لا توجد حركة مطلوبة، ننتقل للجزء التالي تلقائياً
//         _sendMoveToBackend("NEXT");
//       }
//     } else if (response.startsWith("READY:")) {
//       // المكعب جاهز لاستقبال الحركة (تم تفعيل الحساس)
//     } else if (_isWaitingForMove) {
//       // استلام حركة من الطفل
//       String move = response.trim().toUpperCase();
//       if (["LEFT", "RIGHT", "FORWARD", "BACK", "SHAKE"].contains(move)) {
//         _sendMoveToBackend(move);
//       }
//     }
//   }
//
//   // إرسال الحركة للسيرفر لجلب الجزء التالي
//   Future<void> _sendMoveToBackend(String move) async {
//     if (_isProcessing) return;
//     setState(() {
//       _isProcessing = true;
//       _isWaitingForMove = false;
//       _statusText = "Processing ($move)...";
//     });
//
//     try {
//       final storyData = await StoryService.continueStory(
//         _currentStoryID!,
//         _currentUserID!,
//         _currentChildID!,
//         move,
//       );
//       _processBackendResponse(storyData);
//     } catch (e) {
//       setState(() {
//         _statusText = "Error: $e";
//       });
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }
//
//   // !! دالة إصلاح الرابط !!
//   String _fixUrl(String url) {
//     if (url.isEmpty) return "";
//     // إذا كان الرابط يبدأ بـ http، فهو جاهز
//     if (url.startsWith("http")) return url;
//
//     // إزالة الشرطة المائلة الزائدة في البداية
//     if (url.startsWith("/")) url = url.substring(1);
//
//     // دمج عنوان السيرفر مع مسار الملف
//     if (_serverBaseUrl.endsWith("/")) {
//       return "$_serverBaseUrl$url";
//     } else {
//       return "$_serverBaseUrl/$url";
//     }
//   }
//
//   // معالجة رد الباك اند (نص + صوت + حركة)
//   void _processBackendResponse(Map<String, dynamic> storyData) {
//     // 1. تجهيز الرابط
//     final String rawUrl = storyData['audio_url'] ?? '';
//     final String audioUrl = _fixUrl(rawUrl);
//
//     print("Original URL: $rawUrl");
//     print("Fixed URL sent to BLE: $audioUrl");
//
//     final String text = storyData['text'] ?? '...';
//     final String requiredMove = storyData['required_move'] ?? 'NONE';
//     final bool storyEnd = storyData['story_end'] ?? false;
//
//     setState(() {
//       _storyText = text;
//       _currentMoveRequired = requiredMove;
//     });
//
//     // حالة انتهاء القصة
//     if (storyEnd) {
//       setState(() {
//         _statusText = "The End!";
//         _isWaitingForMove = false;
//       });
//       if (audioUrl.isNotEmpty) _bleManager.sendCommand("PLAY:$audioUrl");
//       return;
//     }
//
//     // إذا كان هناك صوت، شغله أولاً
//     if (audioUrl.isNotEmpty) {
//       _bleManager.sendCommand("PLAY:$audioUrl");
//       _pendingMove = requiredMove; // حفظ الحركة لما بعد الصوت
//       _isWaitingForMove = false;
//       setState(() {
//         _statusText = "Listen...";
//       });
//     } else {
//       // لا يوجد صوت، اطلب الحركة فوراً
//       if (requiredMove != "NONE") {
//         _bleManager.sendCommand("START $requiredMove");
//         setState(() {
//           _isWaitingForMove = true;
//           _statusText = "Move Now!";
//         });
//       } else {
//         // لا صوت ولا حركة، انتقل للتالي
//         _sendMoveToBackend("NEXT");
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool isBleConnected = context.watch<BluetoothManager>().isConnected;
//     // تحديد هل الصوت يعمل حالياً أم لا لعرض الشريط
//     bool isAudioPlaying = _statusText == "Listen..." || _pendingMove.isNotEmpty;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_appState.currentStoryTitle ?? "Story"),
//         backgroundColor: isBleConnected ? Color(0xff254865) : Colors.red,
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24.0),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.white, Color(0xFFE3F2FD)],
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // 1. الحالة (Listen, Move, Processing)
//             Text(
//               _statusText,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xff254865),
//               ),
//             ),
//             SizedBox(height: 40),
//
//             // 2. نص القصة داخل مربع أنيق
//             Container(
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               height: 300,
//               child: Center(
//                 child: SingleChildScrollView(
//                   child: Text(
//                     _storyText,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 22,
//                       height: 1.5,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 40),
//
//             // 3. مؤشر التحميل عند الاتصال بالسيرفر
//             if (_isProcessing)
//               Column(
//                 children: [
//                   CircularProgressIndicator(color: Color(0xff254865)),
//                   SizedBox(height: 10),
//                   Text("Processing...", style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//
//             // 4. شريط تشغيل الصوت (يظهر فقط عند الاستماع)
//             if (!_isProcessing && isAudioPlaying)
//               Column(
//                 children: [
//                   Icon(Icons.volume_up_rounded, size: 40, color: Color(0xff254865)),
//                   SizedBox(height: 10),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: LinearProgressIndicator(
//                       minHeight: 10,
//                       backgroundColor: Colors.grey[300],
//                       valueColor: AlwaysStoppedAnimation<Color>(Color(0xff254865)),
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text("Story is playing on CUBIE...", style: TextStyle(color: Colors.grey[600])),
//                 ],
//               ),
//
//             // 5. زر الطوارئ لتخطي الصوت
//             if (!_isProcessing && isAudioPlaying)
//               Padding(
//                 padding: const EdgeInsets.only(top: 30.0),
//                 child: SizedBox(
//                   width: 200,
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       // محاكاة انتهاء الصوت يدوياً
//                       _bleManager.sendCommand("STOP_AUDIO");
//
//                       // تنفيذ المنطق كما لو أن الأردوينو أرسل AUDIO:FINISHED
//                       if (_pendingMove.isNotEmpty) {
//                         _bleManager.sendCommand("START $_pendingMove");
//                         setState(() {
//                           _statusText = "Your Turn! $_currentMoveRequired";
//                           _isWaitingForMove = true;
//                           _pendingMove = "";
//                         });
//                       } else {
//                         _sendMoveToBackend("NEXT");
//                       }
//                     },
//                     icon: Icon(Icons.skip_next, color: Colors.white),
//                     label: Text("Skip Audio", style: TextStyle(fontSize: 18, color: Colors.white)),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orangeAccent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../services/story_service.dart';
import '../app_state.dart';

class StoryProgressScreen extends StatefulWidget {
  const StoryProgressScreen({Key? key}) : super(key: key);

  @override
  State<StoryProgressScreen> createState() => _StoryProgressScreenState();
}

class _StoryProgressScreenState extends State<StoryProgressScreen> {
  late BluetoothManager _bleManager;
  late AppState _appState;

  String _storyText = "Loading story...";
  String _statusText = "Connecting...";

  bool _isWaitingForMove = false;
  String _currentMoveRequired = "";
  String _pendingMove = "";
  bool _isProcessing = false;

  final String _serverBaseUrl = "http://192.168.8.22";

  int? _currentStoryID;
  int? _currentUserID;
  int? _currentChildID;

  // !! --- (التعديل الأساسي) --- !!
  // متغير لتحديد نوع التشغيل
  bool _isReplayMode = false; // true = من التاريخ، false = قصة جديدة

  // للقصص من التاريخ
  List<Map<String, dynamic>> _storyEvents = [];
  int _currentEventIndex = 0;

  @override
  void initState() {
    super.initState();
    _bleManager = Provider.of<BluetoothManager>(context, listen: false);
    _appState = Provider.of<AppState>(context, listen: false);
    _bleManager.addListener(_onBleResponseReceived);

    if (!_bleManager.isConnected) {
      setState(() {
        _storyText = "CUBIE is not connected!";
        _statusText = "Connection Error";
      });
      return;
    }

    _currentStoryID = _appState.currentStoryID;
    _currentUserID = _appState.currentUserID;
    _currentChildID = _appState.selectedChildID;

    // !! --- (كشف نوع التشغيل) --- !!
    // إذا جاء من التاريخ، سيكون هناك arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        _isReplayMode = args['isReplay'] == true;
      }

      if (_isReplayMode) {
        _loadStoryForReplay();
      } else {
        _startLiveStory();
      }
    });
  }

  @override
  void dispose() {
    _bleManager.removeListener(_onBleResponseReceived);
    super.dispose();
  }

  // !! --- (للقصص من التاريخ) --- !!
  Future<void> _loadStoryForReplay() async {
    if (_isProcessing || _currentStoryID == null) return;

    setState(() {
      _isProcessing = true;
      _statusText = "Loading story...";
    });

    try {
      final storyData = await StoryService.replayStory(_currentStoryID!);

      if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
        _storyEvents = List<Map<String, dynamic>>.from(storyData['events']);
        _currentEventIndex = 0;
        _playCurrentEvent();
      } else {
        throw Exception("No events found for this story.");
      }

    } catch (e) {
      print("❌ Error loading story: $e");
      setState(() {
        _statusText = "Error loading story";
        _storyText = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _playCurrentEvent() {
    if (_currentEventIndex >= _storyEvents.length) {
      setState(() {
        _statusText = "The End!";
        _storyText = "Story finished. Thank you for listening!";
      });
      return;
    }

    final event = _storyEvents[_currentEventIndex];
    _processBackendResponse(event);
  }

  // !! --- (للقصص الجديدة - التشغيل الحي) --- !!
  Future<void> _startLiveStory() async {
    // القصة جديدة، الباك إند أرسل الجزء الأول مسبقاً
    // نحتاج فقط أن نحصل عليه من الـ AppState أو من arguments

    // (للتبسيط، سنستدعي replay للحصول على الجزء الأول)
    // لكن سنعامله كجزء وحيد ونستمر بـ /continue

    if (_isProcessing || _currentStoryID == null) return;

    setState(() {
      _isProcessing = true;
      _statusText = "Starting story...";
    });

    try {
      // جلب الجزء الأول (المحفوظ من /start)
      final storyData = await StoryService.replayStory(_currentStoryID!);

      if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
        // خذ أول حدث فقط
        final firstEvent = storyData['events'][0];
        _processBackendResponse(firstEvent);
      } else {
        throw Exception("No initial event found.");
      }

    } catch (e) {
      print("❌ Error starting story: $e");
      setState(() {
        _statusText = "Error starting story";
        _storyText = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // !! --- (استقبال ردود البلوتوث) --- !!
  void _onBleResponseReceived() {
    String response = _bleManager.lastSensorResponse;
    if (response.isEmpty) return;

    if (response.startsWith("AUDIO:FINISHED")) {
      print("🎵 Audio finished.");

      if (_pendingMove.isNotEmpty && _pendingMove != "NONE") {
        _bleManager.sendCommand("START $_pendingMove");
        setState(() {
          _statusText = "Your Turn! $_currentMoveRequired";
          _isWaitingForMove = true;
          _pendingMove = "";
        });
      } else {
        // لا حركة مطلوبة
        if (_isReplayMode) {
          _moveToNextEvent();
        } else {
          // قصة حية، انتظر حركة من الطفل أو أكمل تلقائياً
          _continueStoryWithMove("NEXT");
        }
      }
    }
    else if (response.startsWith("READY:")) {
      print("✅ CUBIE ready for move.");
    }
    else if (_isWaitingForMove) {
      String move = response.trim().toUpperCase();
      if (["LEFT", "RIGHT", "FORWARD", "BACK", "SHAKE"].contains(move)) {
        print("🎮 Move received: $move");

        if (_isReplayMode) {
          _moveToNextEvent();
        } else {
          _continueStoryWithMove(move);
        }
      }
    }
  }

  // !! --- (للقصص من التاريخ) --- !!
  void _moveToNextEvent() {
    setState(() {
      _isWaitingForMove = false;
      _currentEventIndex++;
    });
    _playCurrentEvent();
  }

  // !! --- (للقصص الجديدة) --- !!
  Future<void> _continueStoryWithMove(String move) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isWaitingForMove = false;
      _statusText = "Processing ($move)...";
    });

    try {
      final storyData = await StoryService.continueStory(
        _currentStoryID!,
        _currentUserID!,
        _currentChildID!,
        move,
      );

      _processBackendResponse(storyData);

    } catch (e) {
      print("❌ Error continuing story: $e");
      setState(() {
        _statusText = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // !! --- (معالجة رد الباك إند) --- !!
  void _processBackendResponse(Map<String, dynamic> storyData) {
    final String rawUrl = storyData['audio_url'] ?? '';
    final String audioUrl = _fixUrl(rawUrl);
    final String text = storyData['text'] ?? '...';
    final String requiredMove = storyData['required_move'] ?? 'NONE';
    final bool storyEnd = storyData['story_end'] ?? false;

    print("📖 Processing event...");
    print("🔗 Audio URL: $audioUrl");
    print("🎯 Required Move: $requiredMove");
    print("🏁 Story End: $storyEnd");

    setState(() {
      _storyText = text;
      _currentMoveRequired = requiredMove;
    });

    if (storyEnd) {
      setState(() {
        _statusText = "The End!";
        _isWaitingForMove = false;
      });
      if (audioUrl.isNotEmpty) {
        _bleManager.sendCommand("PLAY:$audioUrl");
      }
      return;
    }

    if (audioUrl.isNotEmpty) {
      _bleManager.sendCommand("PLAY:$audioUrl");
      _pendingMove = requiredMove;
      _isWaitingForMove = false;
      setState(() {
        _statusText = "Listen...";
      });
    } else {
      if (requiredMove != "NONE") {
        _bleManager.sendCommand("START $requiredMove");
        setState(() {
          _isWaitingForMove = true;
          _statusText = "Move Now!";
        });
      } else {
        if (_isReplayMode) {
          _moveToNextEvent();
        } else {
          _continueStoryWithMove("NEXT");
        }
      }
    }
  }

  String _fixUrl(String url) {
    if (url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    if (url.startsWith("/")) url = url.substring(1);
    return _serverBaseUrl.endsWith("/")
        ? "$_serverBaseUrl$url"
        : "$_serverBaseUrl/$url";
  }

  @override
  Widget build(BuildContext context) {
    bool isBleConnected = context.watch<BluetoothManager>().isConnected;
    bool isAudioPlaying = _statusText == "Listen..." || _pendingMove.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appState.currentStoryTitle ?? "Story"),
        backgroundColor: isBleConnected ? Color(0xff254865) : Colors.red,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff254865),
              ),
            ),
            SizedBox(height: 20),

            if (_isReplayMode && _storyEvents.isNotEmpty)
              Text(
                'Part ${_currentEventIndex + 1} of ${_storyEvents.length}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              height: 300,
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    _storyText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),

            if (_isProcessing)
              Column(
                children: [
                  CircularProgressIndicator(color: Color(0xff254865)),
                  SizedBox(height: 10),
                  Text("Processing...", style: TextStyle(color: Colors.grey)),
                ],
              ),

            if (!_isProcessing && isAudioPlaying)
              Column(
                children: [
                  Icon(Icons.volume_up_rounded, size: 40, color: Color(0xff254865)),
                  SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff254865)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Playing on CUBIE...", style: TextStyle(color: Colors.grey[600])),
                ],
              ),

            if (!_isProcessing && isAudioPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _bleManager.sendCommand("STOP_AUDIO");

                      if (_pendingMove.isNotEmpty) {
                        _bleManager.sendCommand("START $_pendingMove");
                        setState(() {
                          _statusText = "Your Turn! $_currentMoveRequired";
                          _isWaitingForMove = true;
                          _pendingMove = "";
                        });
                      } else {
                        if (_isReplayMode) {
                          _moveToNextEvent();
                        } else {
                          _continueStoryWithMove("NEXT");
                        }
                      }
                    },
                    icon: Icon(Icons.skip_next, color: Colors.white),
                    label: Text("Skip Audio", style: TextStyle(fontSize: 18, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}