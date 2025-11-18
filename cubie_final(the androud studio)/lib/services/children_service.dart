import 'api_service.dart';

class ChildrenService {
  static Future<Map<String, dynamic>> getChildren(int userID) async {
    // GET لا يحتاج فورم داتا
    return await ApiService.getRequest('/children/list/$userID');
  }

  static Future<Map<String, dynamic>> addChild(int userID, String name, int age, String gender, String grade) async {
    // نستخدم postFormRequest ونحول كل شيء لنصوص
    return await ApiService.postFormRequest('/children/add/', {
      'userID': userID.toString(),
      'name': name,
      'age': age.toString(),
      'gender': gender, // تأكد أن القيمة هنا 'Male' أو 'Female'
      'grade': grade,
    });
  }

  static Future<Map<String, dynamic>> editChild(int childID, String name, int age, String gender, String grade) async {
    // نستخدم putFormRequest
    return await ApiService.putFormRequest('/children/edit/$childID', {
      'name': name,
      'age': age.toString(),
      'gender': gender,
      'grade': grade,
    });
  }

  static Future<Map<String, dynamic>> deleteChild(int childID) async {
    return await ApiService.postRequest('/children/delete/$childID', {});
  }
}