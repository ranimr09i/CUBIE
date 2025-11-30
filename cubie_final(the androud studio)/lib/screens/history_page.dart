import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// !! --- تأكدي من إضافة audioplayers في pubspec.yaml وعمل Pub get --- !!
import 'package:audioplayers/audioplayers.dart'; 
import '../widgets/app_scaffold.dart';
import '../routes.dart';
import '../services/story_service.dart';
import '../app_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> stories = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userID = appState.currentUserID;

    if (userID == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      print('🔄 جلب تاريخ القصص للمستخدم: $userID');
      final response = await StoryService.getStoryHistory(userID);

      List<Map<String, dynamic>> storiesList = [];

      if (response['stories'] != null) {
        for (var story in response['stories']) {
          final storyMap = <String, dynamic>{};
          story.forEach((key, value) {
            storyMap[key.toString()] = value;
          });
          storiesList.add(storyMap);
        }
      }

      setState(() {
        stories = storiesList;
        _isLoading = false;
        _hasError = false;
      });

      print('✅ تم تحميل ${stories.length} قصة');

    } catch (e) {
      print('❌ فشل تحميل تاريخ القصص: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _refreshStories() async {
    await _loadStories();
    if (!_hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تحديث تاريخ القصص')),
      );
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  String _getPreview(String storyText) {
    if (storyText.isEmpty) return 'لا يوجد نص';
    final preview = storyText.length > 100
        ? '${storyText.substring(0, 100)}...'
        : storyText;
    return preview.replaceAll('\n', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'سجل القصص',
      showLogo: true,
      body: RefreshIndicator(
        onRefresh: _refreshStories,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('فشل تحميل التاريخ', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ElevatedButton(
                onPressed: _loadStories,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        )
            : stories.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('لا توجد قصص سابقة', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, Routes.createStory),
                child: const Text('إنشاء قصة جديدة'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: stories.length,
          itemBuilder: (c, i) {
            final story = stories[i];
            final genre = story['genre']?.toString() ?? 'قصة';
            final date = _formatDate(story['created_at']?.toString() ?? '2025-01-01');
            
            // النص الكامل
            final fullStoryText = story['generated_story']?.toString() ?? '';
            final preview = _getPreview(fullStoryText);
            
            // قائمة روابط الصوت
            final audioFiles = story['audio_files'] as List<dynamic>? ?? [];
            final audioCount = audioFiles.length;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: Colors.white,
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getGenreColor(genre),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGenreIcon(genre),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  '$genre • $date',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff254865),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview,
                      style: const TextStyle(color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (audioCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.audiotrack, size: 16, color: Color(0xff4ab0d1)),
                            const SizedBox(width: 4),
                            Text(
                              '$audioCount مقاطع صوتية',
                              style: const TextStyle(fontSize: 12, color: Color(0xff4ab0d1)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.menu_book, size: 28, color: Color(0xff4ab0d1)), 
                onTap: () {
                  // !! --- هنا نفتح صفحة القراءة الجديدة بدلاً من صفحة اللعب --- !!
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryReaderScreen(
                        title: "قصة $genre",
                        fullText: fullStoryText,
                        // نحول الـ dynamic list إلى List<String>
                        audioUrls: audioFiles.map((e) => e.toString()).toList(),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    switch (genre) {
      case 'مغامرة': return const Color(0xff4ab0d1);
      case 'خيال': return const Color(0xff8dd6bb);
      case 'تعليمي': return const Color(0xffffb74d);
      default: return const Color(0xff254865);
    }
  }

  IconData _getGenreIcon(String genre) {
    switch (genre) {
      case 'مغامرة': return Icons.explore;
      case 'خيال': return Icons.auto_awesome;
      case 'تعليمي': return Icons.school;
      default: return Icons.book;
    }
  }
}

// ======================================================
//  شاشة عرض القصة وتشغيل الصوت (Reader View)
// ======================================================
class StoryReaderScreen extends StatefulWidget {
  final String title;
  final String fullText;
  final List<String> audioUrls;

  const StoryReaderScreen({
    super.key,
    required this.title,
    required this.fullText,
    required this.audioUrls,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  int currentAudioIndex = 0; // أي مقطع يشتغل حالياً

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // عند انتهاء المقطع الحالي، نشغل التالي تلقائياً
    _audioPlayer.onPlayerComplete.listen((event) {
      if (currentAudioIndex < widget.audioUrls.length - 1) {
        // شغل اللي بعده
        setState(() {
          currentAudioIndex++;
        });
        _playCurrent();
      } else {
        // خلصت القصة
        setState(() {
          isPlaying = false;
          currentAudioIndex = 0; // رجعنا للبداية
        });
      }
    });

    // تحديث حالة الزر play/pause
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCurrent() async {
    if (widget.audioUrls.isEmpty) return;
    try {
      await _audioPlayer.play(UrlSource(widget.audioUrls[currentAudioIndex]));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
       // إذا كنا واقفين أو مخلصين، شغل من الاندكس الحالي
       _playCurrent();
    }
  }

  void _skipNext() {
    if (currentAudioIndex < widget.audioUrls.length - 1) {
      setState(() => currentAudioIndex++);
      if (isPlaying) _playCurrent(); // لو شغال كمل شغل الجديد
    }
  }

  void _skipPrevious() {
    if (currentAudioIndex > 0) {
      setState(() => currentAudioIndex--);
      if (isPlaying) _playCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      showLogo: false, 
      body: Column(
        children: [
          // 1. منطقة النص (سكرول)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.fullText,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.8,
                    color: Colors.black87,
                    fontFamily: 'Cairo', // أو الخط اللي تستخدمينه
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),

          // 2. مشغل الصوت
          if (widget.audioUrls.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0,-5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // مؤشر المقطع
                  Text(
                    "مقطع صوتي ${currentAudioIndex + 1} من ${widget.audioUrls.length}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  
                  // أزرار التحكم
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 40, color: Color(0xff254865)),
                        onPressed: currentAudioIndex > 0 ? _skipPrevious : null,
                      ),
                      const SizedBox(width: 20),
                      
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xff4ab0d1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xff4ab0d1).withOpacity(0.4), blurRadius: 10, offset: const Offset(0,4))
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 40, color: Color(0xff254865)),
                        onPressed: currentAudioIndex < widget.audioUrls.length - 1 ? _skipNext : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}