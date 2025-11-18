
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    return await ApiService.postFormRequest('/users/signup/', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await ApiService.postFormRequest('/users/login/', {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> updateProfile(int userID, String name, String email, String password) async {
    return await ApiService.putFormRequest('/users/edit/$userID', {
      'userID': userID.toString(), // تحويل الرقم لنص مهم جداً
      'name': name,
      'email': email,
      'password': password,
    });
  }
}