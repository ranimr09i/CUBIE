
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

      print('📦 استجابة تاريخ القصص: $response');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل تاريخ القصص: $e')),
      );
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
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day-$month-$year';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  String _getPreview(String storyText) {
    if (storyText.isEmpty) return 'لا يوجد نص'; // (تحسين)

    final preview = storyText.length > 100
        ? '${storyText.substring(0, 100)}...'
        : storyText;

    return preview.replaceAll('\n', ' ');
  }

  @override
  Widget build(BuildContext context) {
    // (يمكن جلب AppState هنا مرة واحدة)
    final appState = Provider.of<AppState>(context, listen: false);

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
              const SizedBox(height: 8),
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
              const Text('ابدأ بإنشاء قصة جديدة', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
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
            final genre = story['genre']?.toString() ?? 'غير محدد';
            final date = _formatDate(story['created_at']?.toString() ?? '2025-09-20');
            final preview = _getPreview(story['generated_story']?.toString() ?? '');

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
                    if (story['audio_files'] != null &&
                        (story['audio_files'] as List).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.audiotrack, size: 16, color: Color(0xff4ab0d1)),
                            const SizedBox(width: 4),
                            Text(
                              '${(story['audio_files'] as List).length} ملف صوتي',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff4ab0d1),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xff4ab0d1)),
                onTap: () {
                  // !! --- (التعديل هنا) --- !!
                  if (story['storyID'] != null) {

                    // 1. جهز العنوان والـ ID
                    final storyID = story['storyID'];
                    final storyTitle = "قصة $genre";

                    // 2. خزّن القصة في AppState
                    appState.setCurrentStory(storyID, storyTitle);

                    // 3. انتقل إلى الشاشة (بدون إرسال arguments)
                    Navigator.pushNamed(
                      context,
                      Routes.storyProgress,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ لا يمكن فتح هذه القصة')),
                    );
                  }
                  // !! --- (نهاية التعديل) --- !!
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
    case 'مغامرة':
    return const Color(0xff4ab0d1);
    case 'خيال':
    return const Color(0xff8dd6bb);
    case 'تعليمي':
    return const Color(0xffffb74d);
    default:
    return const Color(0xff254865);
    }
  }

  IconData _getGenreIcon(String genre) {
    switch (genre) {
      case 'مغامرة':
        return Icons.explore;
      case 'خيال':
        return Icons.auto_awesome;
      case 'تعليمي':
        return Icons.school;
      default:
        return Icons.book;
    }
  }
}