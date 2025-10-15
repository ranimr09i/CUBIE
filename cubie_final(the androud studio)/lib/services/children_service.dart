import 'api_service.dart';

class ChildrenService {
  static Future<Map<String, dynamic>> getChildren(int userID) async {
    return await ApiService.getRequest('/children/list/$userID');
  }

  static Future<Map<String, dynamic>> addChild(
      int userID, String name, int age, String gender
      ) async {
    return await ApiService.postRequest('/children/add/', {
      'userID': userID.toString(),
      'name': name,
      'age': age.toString(),
      'gender': gender == 'ذكر' ? 'Male' : 'Female',
    });
  }

  static Future<Map<String, dynamic>> editChild(
      int childID, String name, int age, String gender
      ) async {
    return await ApiService.putRequest('/children/edit/$childID', {
      'name': name,
      'age': age.toString(),
      'gender': gender == 'ذكر' ? 'Male' : 'Female',
    });
  }

  static Future<Map<String, dynamic>> deleteChild(int childID) async {
    return await ApiService.postRequest('/children/delete/$childID', {});
  }

  static Future<Map<String, dynamic>> selectChild(int childID, int userID) async {
    return await ApiService.getRequest('/children/select/$childID?userID=$userID');
  }
}