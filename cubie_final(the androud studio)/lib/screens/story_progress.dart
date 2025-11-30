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
  
  // !! --- متغير جديد لحالة الإيقاف المؤقت --- !!
  bool _isPaused = false;

  final String _serverBaseUrl = "http://192.168.8.22";

  int? _currentStoryID;
  int? _currentUserID;
  int? _currentChildID;

  bool _isReplayMode = false;
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
    if (_bleManager.isConnected) {
      _bleManager.sendCommand("STOP_AUDIO");
    }
    super.dispose();
  }
  
  // !! --- دالة التبديل بين التشغيل والإيقاف --- !!
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _bleManager.sendCommand("PAUSE");
      setState(() => _statusText = "⏸️ القصة متوقفة مؤقتاً");
    } else {
      _bleManager.sendCommand("RESUME");
      setState(() => _statusText = "استمع للقصة...");
    }
  }

  // ... (باقي دوال التحميل والتشغيل كما هي بدون تغيير) ...
  Future<void> _loadStoryForReplay() async {
    if (_isProcessing || _currentStoryID == null) return;
    setState(() { _isProcessing = true; _statusText = "Loading story..."; });
    try {
      final storyData = await StoryService.replayStory(_currentStoryID!);
      if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
        _storyEvents = List<Map<String, dynamic>>.from(storyData['events']);
        _currentEventIndex = 0;
        _playCurrentEvent();
      } else { throw Exception("No events found for this story."); }
    } catch (e) {
      print("❌ Error loading story: $e");
      setState(() { _statusText = "Error loading story"; _storyText = "Error: $e"; });
    } finally { setState(() { _isProcessing = false; }); }
  }

  void _playCurrentEvent() {
    if (_currentEventIndex >= _storyEvents.length) {
      setState(() { _statusText = "The End!"; _storyText = "Story finished."; });
      return;
    }
    final event = _storyEvents[_currentEventIndex];
    _processBackendResponse(event);
  }

  Future<void> _startLiveStory() async {
    if (_isProcessing || _currentStoryID == null) return;
    setState(() { _isProcessing = true; _statusText = "Starting story..."; });
    try {
      final storyData = await StoryService.replayStory(_currentStoryID!);
      if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
        final firstEvent = storyData['events'][0];
        _processBackendResponse(firstEvent);
      } else { throw Exception("No initial event found."); }
    } catch (e) {
      print("❌ Error starting story: $e");
      setState(() { _statusText = "Error starting story"; _storyText = "Error: $e"; });
    } finally { setState(() { _isProcessing = false; }); }
  }

  void _onBleResponseReceived() {
    if (_isReplayMode) return;
    String response = _bleManager.lastSensorResponse;
    if (response.isEmpty) return;
    
    // !! --- إذا جاء حدث انتهاء الصوت، نتأكد أننا لسنا في حالة إيقاف مؤقت --- !!
    if (response.startsWith("AUDIO:FINISHED")) {
      if (_isPaused) return; // تجاهل إذا كان متوقفاً يدوياً (احتياط)

      print("🎵 Audio finished.");
      if (_pendingMove.isNotEmpty && _pendingMove != "NONE" && _pendingMove != "FINISH") {
        _bleManager.sendCommand("START $_pendingMove");
        setState(() {
          _statusText = _getMoveInstruction(_pendingMove);
          _isWaitingForMove = true;
          _pendingMove = "";
          _isPaused = false; // إعادة تعيين حالة الإيقاف
        });
      } else if (_pendingMove == "FINISH") {
        setState(() {
          _statusText = "The End!";
          _isWaitingForMove = false;
        });
      } else {
        _continueStoryWithMove("NEXT");
      }
    }
    else if (response.startsWith("GESTURE:")) {
      if (_isWaitingForMove) {
        String move = response.split(':')[1].trim().toUpperCase();
        setState(() { _isWaitingForMove = false; _statusText = "Processing..."; });
        Future.delayed(Duration(milliseconds: 500), () { _continueStoryWithMove(move); });
      }
    }
  }

  void _moveToNextEvent() {
    setState(() { _isWaitingForMove = false; _currentEventIndex++; _isPaused = false; });
    Future.delayed(Duration(seconds: 2), () { if (mounted) _playCurrentEvent(); });
  }

  Future<void> _continueStoryWithMove(String move) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; _isWaitingForMove = false; _statusText = "Processing ($move)..."; });
    try {
      final storyData = await StoryService.continueStory(_currentStoryID!, _currentUserID!, _currentChildID!, move);
      _processBackendResponse(storyData);
    } catch (e) {
      print("❌ Error continuing story: $e");
      setState(() { _statusText = "Error: $e"; });
    } finally { setState(() { _isProcessing = false; }); }
  }
  
  String _getMoveInstruction(String moveType) {
    switch (moveType) {
      case "TILTZ": return "دورك! لف المكعب يمين أو يسار";
      case "TILTY": return "دورك! لف المكعب أمام أو خلف";
      case "SHAKE": return "دورك! هز المكعب بقوة";
      default: return "دورك!";
    }
  }

  void _processBackendResponse(Map<String, dynamic> storyData) {
    final String rawUrl = storyData['audio_url'] ?? '';
    final String audioUrl = _fixUrl(rawUrl);
    final String text = storyData['text'] ?? '...';
    final String requiredMove = storyData['required_move'] ?? 'NONE';
    final bool storyEnd = storyData['story_end'] ?? false;

    setState(() {
      _storyText = text;
      _currentMoveRequired = requiredMove;
      _isPaused = false; // دائماً نبدأ التشغيل غير متوقف
    });

    if (storyEnd) {
      setState(() {
        _statusText = "The End!";
        _isWaitingForMove = false;
        _pendingMove = "FINISH";
      });
      if (audioUrl.isNotEmpty) { _bleManager.sendCommand("PLAY:$audioUrl"); }
      return;
    }

    if (audioUrl.isNotEmpty) {
      _bleManager.sendCommand("PLAY:$audioUrl");
      _pendingMove = requiredMove;
      _isWaitingForMove = false;
      setState(() { _statusText = "استمع للقصة..."; });
    } else {
      if (_isReplayMode) {
        _moveToNextEvent();
      } else {
        if (requiredMove != "NONE") {
          _bleManager.sendCommand("START $requiredMove");
          setState(() { _isWaitingForMove = true; _statusText = _getMoveInstruction(requiredMove); });
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
    return _serverBaseUrl.endsWith("/") ? "$_serverBaseUrl$url" : "$_serverBaseUrl/$url";
  }

  @override
  Widget build(BuildContext context) {
    bool isBleConnected = context.watch<BluetoothManager>().isConnected;
    // نعتبر الصوت يعمل إذا كان النص "استمع للقصة..." أو "متوقف مؤقتاً"
    bool isAudioActive = _statusText == "استمع للقصة..." || _statusText == "⏸️ القصة متوقفة مؤقتاً";

    return WillPopScope(
      onWillPop: () async {
        if (_bleManager.isConnected) {
          _bleManager.sendCommand("STOP_AUDIO");
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appState.currentStoryTitle ?? "Story"),
          backgroundColor: isBleConnected ? Color(0xff254865) : Colors.red,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (_bleManager.isConnected) {
                _bleManager.sendCommand("STOP_AUDIO");
              }
              Navigator.pop(context);
            },
          ),
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
              if (_isReplayMode)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Color(0xff4ab0d1), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.replay, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('وضع الإعادة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              SizedBox(height: 20),

              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isPaused ? Colors.orange : Color(0xff254865), // تغيير اللون عند الإيقاف
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                ),
                height: 300,
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      _storyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, height: 1.5, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),

              if (_isProcessing)
                Column(children: [CircularProgressIndicator(color: Color(0xff254865)), SizedBox(height: 10), Text("Processing...", style: TextStyle(color: Colors.grey))]),

              // !! --- زر التحكم بالصوت --- !!
              if (!_isProcessing && isAudioActive)
                Column(
                  children: [
                    // زر كبير للتحكم
                    GestureDetector(
                      onTap: _togglePause,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isPaused ? Colors.orange : Color(0xff254865),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                          ],
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      _isPaused ? "اضغط للمتابعة" : "القصة تعمل...",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 10),
                    // شريط تقدم وهمي (للزينة)
                    if (!_isPaused)
                      Container(
                        width: 150,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff4ab0d1)),
                        ),
                      ),
                  ],
                ),

              if (!_isProcessing && _isWaitingForMove && !_isReplayMode)
                Column(children: [Icon(Icons.touch_app, size: 50, color: Color(0xff4ab0d1)), SizedBox(height: 15), Text("في انتظار حركتك...", style: TextStyle(fontSize: 18, color: Color(0xff254865), fontWeight: FontWeight.w600))]),
            ],
          ),
        ),
      ),
    );
  }
}