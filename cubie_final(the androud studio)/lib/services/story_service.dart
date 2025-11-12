
import 'api_service.dart';

class StoryService {
  static Future<Map<String, dynamic>> startStory(
      int userID, int childID, String genre, String description
      ) async {

    // !! --- (التعديل هنا) --- !!
    // (استخدام postFormRequest بدلاً من postRequest)
    return await ApiService.postFormRequest('/chat/start/', {
      'userID': userID.toString(),
      'childID': childID.toString(),
      'genre': genre,
      'description': description,
    });
    // !! --- (نهاية التعديل) --- !!
  }

  static Future<Map<String, dynamic>> continueStory(
      int storyID, int userID, int childID, String answer
      ) async {

    // !! --- (التعديل هنا) --- !!
    // (استخدام postFormRequest بدلاً من postRequest)
    return await ApiService.postFormRequest('/chat/continue/', {
      'storyID': storyID.toString(),
      'userID': userID.toString(),
      'childID': childID.toString(),
      'answer': answer,
    });
    // !! --- (نهاية التعديل) --- !!
  }

  static Future<Map<String, dynamic>> getStoryHistory(int userID) async {
    return await ApiService.getRequest('/stories/history/$userID');
  }

  static Future<Map<String, dynamic>> replayStory(int storyID) async {
    return await ApiService.getRequest('/stories/replay/$storyID');
  }
}