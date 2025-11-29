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
    // !! --- إضافة إيقاف الصوت عند الخروج --- !!
    if (_bleManager.isConnected) {
      _bleManager.sendCommand("STOP_AUDIO");
    }
    super.dispose();
  }

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

  Future<void> _startLiveStory() async {
    if (_isProcessing || _currentStoryID == null) return;

    setState(() {
      _isProcessing = true;
      _statusText = "Starting story...";
    });

    try {
      final storyData = await StoryService.replayStory(_currentStoryID!);

      if (storyData['events'] != null && (storyData['events'] as List).isNotEmpty) {
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

  void _onBleResponseReceived() {
    // !! --- تجاهل ردود البلوتوث في وضع إعادة التشغيل --- !!
    if (_isReplayMode) return;

    String response = _bleManager.lastSensorResponse;
    if (response.isEmpty) return;

    print("📡 [BLE Response] $response");

    if (response.startsWith("AUDIO:FINISHED")) {
      print("🎵 Audio finished.");

      if (_pendingMove.isNotEmpty && _pendingMove != "NONE" && _pendingMove != "FINISH") {
        _bleManager.sendCommand("START $_pendingMove");
        setState(() {
          _statusText = _getMoveInstruction(_pendingMove);
          _isWaitingForMove = true;
          _pendingMove = "";
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
    else if (response.startsWith("READY:")) {
      print("✅ CUBIE ready for move.");
    }
    else if (response.startsWith("GESTURE:")) {
      if (_isWaitingForMove) {
        String move = response.split(':')[1].trim().toUpperCase();
        print("🎮 Move received: $move");

        setState(() {
          _isWaitingForMove = false;
          _statusText = "Processing...";
        });

        Future.delayed(Duration(milliseconds: 500), () {
          _continueStoryWithMove(move);
        });
      }
    }
  }

  void _moveToNextEvent() {
    setState(() {
      _isWaitingForMove = false;
      _currentEventIndex++;
    });

    // !! --- إضافة تأخير بين الأجزاء في وضع الإعادة --- !!
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _playCurrentEvent();
      }
    });
  }

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

  String _getMoveInstruction(String moveType) {
    switch (moveType) {
      case "TILTZ":
        return "دورك! لف المكعب يمين أو يسار";
      case "TILTY":
        return "دورك! لف المكعب أمام أو خلف";
      case "SHAKE":
        return "دورك! هز المكعب بقوة";
      default:
        return "دورك!";
    }
  }

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
        _pendingMove = "FINISH";
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
        _statusText = "استمع للقصة...";
      });
    } else {
      // !! --- التعديل الأساسي: في وضع الإعادة لا نطلب حركات --- !!
      if (_isReplayMode) {
        // في وضع الإعادة، ننتقل تلقائياً للجزء التالي
        _moveToNextEvent();
      } else {
        // في الوضع الحي، نطلب الحركة
        if (requiredMove != "NONE") {
          _bleManager.sendCommand("START $requiredMove");
          setState(() {
            _isWaitingForMove = true;
            _statusText = _getMoveInstruction(requiredMove);
          });
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
    bool isAudioPlaying = _statusText == "استمع للقصة..." || _pendingMove.isNotEmpty;

    return WillPopScope(
      // !! --- إضافة معالجة زر الرجوع --- !!
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
              // !! --- إضافة شارة وضع الإعادة --- !!
              if (_isReplayMode)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xff4ab0d1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'وضع الإعادة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),

              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff254865),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              if (_isReplayMode && _storyEvents.isNotEmpty)
                Text(
                  'جزء ${_currentEventIndex + 1} من ${_storyEvents.length}',
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
                    Icon(Icons.volume_up_rounded, size: 50, color: Color(0xff254865)),
                    SizedBox(height: 15),
                    Text(
                        "القصة تُشغَّل على CUBIE...",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500
                        )
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff254865)),
                        ),
                      ),
                    ),
                  ],
                ),

              // !! --- عرض طلب الحركة فقط في الوضع الحي --- !!
              if (!_isProcessing && _isWaitingForMove && !_isReplayMode)
                Column(
                  children: [
                    Icon(Icons.touch_app, size: 50, color: Color(0xff4ab0d1)),
                    SizedBox(height: 15),
                    Text(
                        "في انتظار حركتك...",
                        style: TextStyle(
                            fontSize: 18,
                            color: Color(0xff254865),
                            fontWeight: FontWeight.w600
                        )
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