// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../widgets/app_scaffold.dart';
// import '../routes.dart';
// import '../services/story_service.dart';
// import '../app_state.dart';
//
// class CreateStoryPage extends StatefulWidget {
//   const CreateStoryPage({super.key});
//
//   @override
//   State<CreateStoryPage> createState() => _CreateStoryPageState();
// }
//
// class _CreateStoryPageState extends State<CreateStoryPage> {
//   String genre = 'مغامرة';
//   final _prefs = TextEditingController();
//   bool _isLoading = false;
//
//   Future<void> _createStory() async {
//     if (_prefs.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('يرجى إدخال تفضيلات القصة')),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final appState = Provider.of<AppState>(context, listen: false);
//       final userID = appState.currentUserID;
//       final childID = appState.selectedChildID;
//
//       if (userID == null || childID == null) {
//         throw Exception('لم يتم اختيار طفل أو تسجيل الدخول');
//       }
//
//       print('🔄 بدء إنشاء قصة: userID=$userID, childID=$childID');
//
//       final response = await StoryService.startStory(
//           userID,
//           childID,
//           genre,
//           _prefs.text
//       );
//
//       print('✅ تم إنشاء القصة: ${response['storyID']}');
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('✅ تم إنشاء القصة بنجاح')),
//       );
//
//       Navigator.pushNamed(
//           context,
//           Routes.storyProgress,
//           arguments: {
//             'storyID': response['storyID'],
//             'childID': response['childID'],
//             'part': response['part'],
//             'audio_path': response['audio_path'],
//             'finished': response['finished'],
//           }
//       );
//
//     } catch (e) {
//       print('❌ فشل إنشاء القصة: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('فشل إنشاء القصة: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'إنشاء قصة',
//       body: Padding(
//         padding: const EdgeInsets.all(14.0),
//         child: Column(
//           children: [
//             DropdownButtonFormField<String>(
//               value: genre,
//               decoration: const InputDecoration(
//                 labelText: 'النوع',
//                 border: OutlineInputBorder(),
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//               items: const [
//                 DropdownMenuItem(value: 'مغامرة', child: Text('مغامرة')),
//                 DropdownMenuItem(value: 'خيال', child: Text('خيال')),
//                 DropdownMenuItem(value: 'تعليمي', child: Text('تعليمي')),
//               ],
//               onChanged: (v) => setState(() => genre = v ?? 'مغامرة'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//                 controller: _prefs,
//                 decoration: const InputDecoration(
//                   labelText: 'تفضيلات القصة (اختياري)',
//                   hintText: 'شخصيات، أسلوب، طول ...',
//                   border: OutlineInputBorder(),
//                   filled: true,
//                   fillColor: Colors.white,
//                 )
//             ),
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _createStory,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xff4ab0d1),
//                   foregroundColor: const Color(0xff254865),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text('توليد القصة'),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../routes.dart';
import '../services/story_service.dart';
import '../app_state.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  String genre = 'مغامرة';
  final _prefs = TextEditingController();
  bool _isLoading = false;

  Future<void> _createStory() async {
    if (_prefs.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال تفضيلات القصة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userID = appState.currentUserID;
      final childID = appState.selectedChildID;

      if (userID == null || childID == null) {
        throw Exception('لم يتم اختيار طفل أو تسجيل الدخول');
      }

      print('🔄 بدء إنشاء قصة: userID=$userID, childID=$childID');

      final response = await StoryService.startStory(
          userID,
          childID,
          genre,
          _prefs.text
      );

      final storyID = response['storyID'];
      print('✅ تم إنشاء القصة: $storyID');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إنشاء القصة بنجاح')),
      );

      // !! --- (التعديل هنا) --- !!
      // 1. قم بتخزين القصة الحالية في AppState
      final storyTitle = "قصة $genre"; // (يمكنك تغييره لأي عنوان)
      appState.setCurrentStory(storyID, storyTitle);

      // 2. انتقل إلى الشاشة (بدون إرسال arguments)
      Navigator.pushNamed(
        context,
        Routes.storyProgress,
      );
      // !! --- (نهاية التعديل) --- !!

    } catch (e) {
      print('❌ فشل إنشاء القصة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء القصة: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إنشاء قصة',
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: genre,
              decoration: const InputDecoration(
                labelText: 'النوع',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'مغامرة', child: Text('مغامرة')),
                DropdownMenuItem(value: 'خيال', child: Text('خيال')),
                DropdownMenuItem(value: 'تعليمي', child: Text('تعليمي')),
              ],
              onChanged: (v) => setState(() => genre = v ?? 'مغامرة'),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _prefs,
                decoration: const InputDecoration(
                  labelText: 'تفضيلات القصة',
                  hintText: 'مثال: عن قطة صغيرة تبحث عن أمها', // (تم تحسين النص)
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                )
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4ab0d1),
                  foregroundColor: const Color(0xff254865),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('توليد القصة'),
              ),
            )
          ],
        ),
      ),
    );
  }
}