import 'api_service.dart';

class StoryService {
  static Future<Map<String, dynamic>> startStory(
      int userID, int childID, String genre, String description
      ) async {
    return await ApiService.postRequest('/chat/start/', {
      'userID': userID.toString(),
      'childID': childID.toString(),
      'genre': genre,
      'description': description,
    });
  }

  static Future<Map<String, dynamic>> continueStory(
      int storyID, int userID, int childID, String answer
      ) async {
    return await ApiService.postRequest('/chat/continue/', {
      'storyID': storyID.toString(),
      'userID': userID.toString(),
      'childID': childID.toString(),
      'answer': answer,
    });
  }

  static Future<Map<String, dynamic>> getStoryHistory(int userID) async {
    return await ApiService.getRequest('/stories/history/$userID');
  }

  static Future<Map<String, dynamic>> replayStory(int storyID) async {
    return await ApiService.getRequest('/stories/replay/$storyID');
  }
}