// import 'api_service.dart';
//
// class AuthService {
//   static Future<Map<String, dynamic>> login(String email, String password) async {
//     return await ApiService.postRequest('/users/login/', {
//       'email': email,
//       'password': password,
//     });
//   }
//
//   static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
//     return await ApiService.postRequest('/users/signup/', {
//       'name': name,
//       'email': email,
//       'password': password,
//     });
//   }
//
//   static Future<Map<String, dynamic>> updateProfile(int userID, String name, String email, String password) async {
//     return await ApiService.putRequest('/users/edit/$userID', {
//       'name': name,
//       'email': email,
//       'password': password,
//     });
//   }
// }
// import 'api_service.dart';
//
// class AuthService {
//   static Future<Map<String, dynamic>> login(String email, String password) async {
//     return await ApiService.postRequest('/users/login/', {
//       'email': email,
//       'password': password,
//     });
//   }
//
//   static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
//     return await ApiService.postRequest('/users/signup/', {
//       'name': name,
//       'email': email,
//       'password': password,
//     });
//   }
//
//   static Future<Map<String, dynamic>> updateProfile(int userID, String name, String email, String password) async {
//     return await ApiService.putRequest('/users/edit/$userID', {
//       'name': name,
//       'email': email,
//       'password': password,
//     });
//   }
// }
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // !! --- (التعديل هنا) --- !!
    // (استدعاء الدالة الجديدة التي ترسل كـ Form)
    return await ApiService.postFormRequest('/users/login/', {
      'email': email,
      'password': password,
    });
    // !! --- (نهاية التعديل) --- !!
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    // (هذه تبقى كما هي، تفترض أنها تتوقع JSON)
    // (إذا واجهت خطأ 422 في إنشاء الحساب أيضاً، فقم بتغييرها إلى postFormRequest)
    return await ApiService.postRequest('/users/signup/', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> updateProfile(int userID, String name, String email, String password) async {
    return await ApiService.putRequest('/users/edit/$userID', {
      'name': name,
      'email': email,
      'password': password,
    });
  }
}