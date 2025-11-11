// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// //
// // class ApiService {
// //   static const String baseUrl = 'http://192.168.8.19';
// //
// //   static Future<Map<String, dynamic>> postRequest(
// //       String endpoint,
// //       Map<String, dynamic> body
// //       ) async {
// //     try {
// //       print('🌐 [API] POST إلى: $baseUrl$endpoint');
// //       print('📦 [API] البيانات: $body');
// //
// //       final response = await http.post(
// //         Uri.parse('$baseUrl$endpoint'),
// //         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
// //         body: body,
// //       );
// //
// //       print('📡 [API] الاستجابة: ${response.statusCode}');
// //       print('📄 [API] المحتوى: ${response.body}');
// //
// //       if (response.statusCode == 200) {
// //         return json.decode(response.body);
// //       } else {
// //         throw Exception('فشل: ${response.statusCode} - ${response.body}');
// //       }
// //     } catch (e) {
// //       print('❌ [API] خطأ: $e');
// //       throw Exception('خطأ شبكة: $e');
// //     }
// //   }
// //
// //   static Future<Map<String, dynamic>> putRequest(
// //       String endpoint,
// //       Map<String, dynamic> body
// //       ) async {
// //     try {
// //       print('🌐 [API] PUT إلى: $baseUrl$endpoint');
// //       print('📦 [API] البيانات: $body');
// //
// //       final response = await http.put(
// //         Uri.parse('$baseUrl$endpoint'),
// //         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
// //         body: body,
// //       );
// //
// //       print('📡 [API] الاستجابة: ${response.statusCode}');
// //       print('📄 [API] المحتوى: ${response.body}');
// //
// //       if (response.statusCode == 200) {
// //         return json.decode(response.body);
// //       } else {
// //         throw Exception('فشل: ${response.statusCode} - ${response.body}');
// //       }
// //     } catch (e) {
// //       print('❌ [API] خطأ: $e');
// //       throw Exception('خطأ شبكة: $e');
// //     }
// //   }
// //
// //   static Future<Map<String, dynamic>> getRequest(String endpoint) async {
// //     try {
// //       print('🌐 [API] GET من: $baseUrl$endpoint');
// //
// //       final response = await http.get(Uri.parse('$baseUrl$endpoint'));
// //
// //       print('📡 [API] الاستجابة: ${response.statusCode}');
// //       print('📄 [API] المحتوى: ${response.body}');
// //
// //       if (response.statusCode == 200) {
// //         return json.decode(response.body);
// //       } else {
// //         throw Exception('فشل: ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       print('❌ [API] خطأ: $e');
// //       throw Exception('خطأ شبكة: $e');
// //     }
// //   }
// // }
// // lib/services/api_service.dart
// //
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// //
// // class ApiService {
// //
// //   static const String baseUrl = 'http://192.168.8.22';
// //
// //   static Future<Map<String, dynamic>> postRequest(
// //       String endpoint,
// //       Map<String, dynamic> body
// //       ) async {
// //     try {
// //       print('🌐 [API] POST إلى: $baseUrl$endpoint');
// //       print('📦 [API] البيانات: $body');
// //
// //       final response = await http.post(
// //         Uri.parse('$baseUrl$endpoint'),
// //         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
// //         body: body,
// //       );
// //
// //       print('📡 [API] الاستجابة: ${response.statusCode}');
// //
// //       if (response.statusCode == 200) {
// //         // ===========================================
// //         // == التعديل هنا: فك ترميز الرد كـ UTF-8 ==
// //         final String responseBody = utf8.decode(response.bodyBytes);
// //         print('📄 [API] المحتوى: $responseBody');
// //         return json.decode(responseBody);
// //         // ===========================================
// //       } else {
// //         throw Exception('فشل: ${response.statusCode} - ${response.body}');
// //       }
// //     } catch (e) {
// //       print('❌ [API] خطأ: $e');
// //       throw Exception('خطأ شبكة: $e');
// //     }
// //   }
// //
// //   static Future<Map<String, dynamic>> putRequest(
// //       String endpoint,
// //       Map<String, dynamic> body
// //       ) async {
// //     try {
// //       print('🌐 [API] PUT إلى: $baseUrl$endpoint');
// //       print('📦 [API] البيانات: $body');
// //
// //       final response = await http.put(
// //         Uri.parse('$baseUrl$endpoint'),
// //         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
// //         body: body,
// //       );
// //
// //       print('📡 [API] الاستجابة: ${response.statusCode}');
// //
// //       if (response.statusCode == 200) {
// //         // ===========================================
// //         // == التعديل هنا: فك ترميز الرد كـ UTF-8 ==
// //         final String responseBody = utf8.decode(response.bodyBytes);
// //         print('📄 [API] المحتوى: $responseBody');
// //         return json.decode(responseBody);
// //         // ===========================================
// //       } else {
// //         throw Exception('فشل: ${response.statusCode} - ${response.body}');
// //       }
// //     } catch (e) {
// //       print('❌ [API] خطأ: $e');
// //       throw Exception('خطأ شبكة: $e');
// //     }
// //   }
// //
// //   static Future<Map<String, dynamic>> getRequest(String endpoint) async {
// //     try {
// //       print('🌐 [API] GET من: $baseUrl$endpoint');
// //
// //       final response = await http.get(Uri.parse('$baseUrl$endpoint'));
// //
// //       print('📡 [API] الاستجابة: ${response.statusCode}');
// //
// //       if (response.statusCode == 200) {
// //         // ===========================================
// //         // == التعديل هنا: فك ترميز الرد كـ UTF-8 ==
// //         final String responseBody = utf8.decode(response.bodyBytes);
// //         print('📄 [API] المحتوى: $responseBody');
// //         return json.decode(responseBody);
// //         // ===========================================
// //       } else {
// //         throw Exception('فشل: ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       print('❌ [API] خطأ: $e');
// //       throw Exception('خطأ شبكة: $e');
// //     }
// //   }
// // }
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class ApiService {
// //   // !! عدّل هذا الـ IP ليطابق عنوان الباك اند عندك !!
// //   final String baseUrl = 'http://192.168.100.18:8000';
// //
// //   // (دالة تسجيل الدخول - موجودة عندك)
// //   Future<Map<String, dynamic>> login(String email, String password) async {
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/users/login'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({'email': email, 'password': password}),
// //     );
// //
// //     if (response.statusCode == 200) {
// //       return jsonDecode(response.body);
// //     } else {
// //       throw Exception('Failed to login: ${response.body}');
// //     }
// //   }
// //
// //   // (دالة إنشاء حساب - موجودة عندك)
// //   Future<Map<String, dynamic>> signup(String username, String email, String password) async {
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/users/signup'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({'username': username, 'email': email, 'password': password}),
// //     );
// //
// //     if (response.statusCode == 200) {
// //       return jsonDecode(response.body);
// //     } else {
// //       throw Exception('Failed to signup: ${response.body}');
// //     }
// //   }
// //
// //   // (دالة جلب القصص - موجودة عندك)
// //   Future<List<dynamic>> getStories() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('token');
// //
// //     final response = await http.get(
// //       Uri.parse('$baseUrl/stories/'),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $token',
// //       },
// //     );
// //
// //     if (response.statusCode == 200) {
// //       return jsonDecode(utf8.decode(response.bodyBytes));
// //     } else {
// //       throw Exception('Failed to load stories');
// //     }
// //   }
// //
// //   // !! --- دالة جديدة: بدء القصة --- !!
// //   // (هذه الدالة تطلب من الباك اند البدء وتعطيك أول مقطع صوتي)
// //   Future<Map<String, dynamic>> startStory(int childId, int storyId) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('token');
// //
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/chat/start_story/$childId/$storyId'),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $token',
// //       },
// //     );
// //
// //     if (response.statusCode == 200) {
// //       // الباك اند سيرد بالجزء الأول من القصة
// //       return jsonDecode(utf8.decode(response.bodyBytes));
// //     } else {
// //       throw Exception('Failed to start story. Status: ${response.statusCode}, Body: ${response.body}');
// //     }
// //   }
// //
// //
// //   // !! --- دالة جديدة: إرسال حركة الحساس --- !!
// //   // (هذه الدالة ترسل حركة المكعب للباك اند وتستقبل الرد)
// //   Future<Map<String, dynamic>> processMove(int childId, int storyId, String move) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('token');
// //
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/chat/process_move/$childId/$storyId'),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $token',
// //       },
// //       body: jsonEncode({'move': move}), // إرسال الحركة في الـ body
// //     );
// //
// //     if (response.statusCode == 200) {
// //       // الباك اند سيرد بالجزء التالي من القصة
// //       return jsonDecode(utf8.decode(response.bodyBytes));
// //     } else {
// //       throw Exception('Failed to process move. Status: ${response.statusCode}, Body: ${response.body}');
// //     }
// //   }
// //
// // // (احتفظ بأي دوال أخرى موجودة لديك... مثل جلب الأطفال أو تعديل الحساب)
// // }
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ApiService {
//   static const String _baseUrl = 'http://192.168.8.22';
//
//   static Future<Map<String, String>> _getHeaders() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token'); // (لم أعد أستخدمه، لأن الباك اند لا يتطلبه حالياً)
//
//     final headers = {
//       'Content-Type': 'application/json; charset=UTF-8',
//     };
//
//     // (إذا كان الباك اند يتطلب توكن، ألغِ التعليق عن هذا)
//     if (token != null) {
//       headers['Authorization'] = 'Bearer $token';
//     }
//     return headers;
//   }
//
//   // دالة لمعالجة الردود
//   static Map<String, dynamic> _handleResponse(http.Response response) {
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       // استخدام utf8.decode لضمان دعم اللغة العربية
//       return jsonDecode(utf8.decode(response.bodyBytes));
//     } else {
//       print('API Error (${response.statusCode}): ${response.body}');
//       try {
//         // محاولة قراءة رسالة الخطأ من الباك اند
//         final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
//         throw Exception(errorBody['detail'] ?? 'Failed request: ${response.statusCode}');
//       } catch (e) {
//         // إذا فشلت قراءة الخطأ
//         throw Exception('Failed request: ${response.statusCode}');
//       }
//     }
//   }
//
//   // --- الدوال الأساسية ---
//
//   static Future<Map<String, dynamic>> getRequest(String endpoint) async {
//     final headers = await _getHeaders();
//     final response = await http.get(
//       Uri.parse('$_baseUrl$endpoint'),
//       headers: headers,
//     );
//     return _handleResponse(response);
//   }
//
//   static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
//     final headers = await _getHeaders();
//     final response = await http.post(
//       Uri.parse('$_baseUrl$endpoint'),
//       headers: headers,
//       body: jsonEncode(body),
//     );
//     return _handleResponse(response);
//   }
//
//   static Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, dynamic> body) async {
//     final headers = await _getHeaders();
//     final response = await http.put(
//       Uri.parse('$_baseUrl$endpoint'),
//       headers: headers,
//       body: jsonEncode(body),
//     );
//     return _handleResponse(response);
//   }
// }
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ApiService {
//   // !! --- (التعديل الأهم هنا) --- !!
//   // (تم تحديث الآي بي والبورت ليتطابق مع سيرفر الماك)
//   static const String _baseUrl = 'http://192.168.8.22'; // (يعمل على بورت 80 الافتراضي)
//   // !! --- (نهاية التعديل) --- !!
//
//
//   // دالة خاصة لجلب الـ Headers مع التوكن
//   static Future<Map<String, String>> _getHeaders() async {
//     final headers = {
//       'Content-Type': 'application/json; charset=UTF-8',
//     };
//     return headers;
//   }
//
//   // دالة لمعالجة الردود
//   static Map<String, dynamic> _handleResponse(http.Response response) {
//     // استخدام utf8.decode لضمان دعم اللغة العربية
//     final responseBody = utf8.decode(response.bodyBytes);
//
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       return jsonDecode(responseBody);
//     } else {
//       print('API Error (${response.statusCode}): $responseBody');
//       try {
//         // محاولة قراءة رسالة الخطأ من الباك اند
//         final errorBody = jsonDecode(responseBody);
//         // (قد يرسل الباك اند الخطأ كـ detail أو message)
//         final detail = errorBody['detail'];
//         if (detail is List && detail.isNotEmpty) {
//           throw Exception(detail[0]['msg'] ?? 'Failed request: ${response.statusCode}');
//         } else if (detail is String) {
//           throw Exception(detail);
//         }
//         throw Exception(errorBody['message'] ?? 'Failed request: ${response.statusCode}');
//       } catch (e) {
//         // إذا فشلت قراءة الخطأ
//         throw Exception('Failed request: ${response.statusCode}');
//       }
//     }
//   }
//
//   // --- الدوال الأساسية ---
//
//   static Future<Map<String, dynamic>> getRequest(String endpoint) async {
//     final headers = await _getHeaders();
//     final response = await http.get(
//       Uri.parse('$_baseUrl$endpoint'),
//       headers: headers,
//     );
//     return _handleResponse(response);
//   }
//
//   static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
//     final headers = await _getHeaders();
//     final response = await http.post(
//       Uri.parse('$_baseUrl$endpoint'),
//       headers: headers,
//       body: jsonEncode(body),
//     );
//     return _handleResponse(response);
//   }
//
//   static Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, dynamic> body) async {
//     final headers = await _getHeaders();
//     final response = await http.put(
//       Uri.parse('$_baseUrl$endpoint'),
//       headers: headers,
//       body: jsonEncode(body),
//     );
//     return _handleResponse(response);
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // !! تأكد أن هذا الـ IP صحيح للباك اند عندك !!
  static const String _baseUrl = 'http://192.168.8.22'; // (استخدم IP الخاص بك)

  // دالة خاصة لجلب الـ Headers (للطلبات من نوع JSON)
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // دالة لمعالجة الردود
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // استخدام utf8.decode لضمان دعم اللغة العربية
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('API Error (${response.statusCode}): ${response.body}');
      try {
        // محاولة قراءة رسالة الخطأ من الباك اند
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['detail'] ?? 'Failed request: ${response.statusCode}');
      } catch (e) {
        // إذا فشلت قراءة الخطأ
        throw Exception('Failed request: ${response.statusCode}, Body: ${response.body}');
      }
    }
  }

  // --- الدوال الأساسية (للطلبات من نوع JSON) ---

  static Future<Map<String, dynamic>> getRequest(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body), // (هذه ترسل JSON)
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // !! --- (دالة جديدة مضافة هنا لحل خطأ 422) --- !!
  // هذه الدالة ترسل البيانات كـ Form (x-www-form-urlencoded)
  static Future<Map<String, dynamic>> postFormRequest(String endpoint, Map<String, String> body) async {

    // هنا لا نستخدم _getHeaders لأننا نغير نوع المحتوى
    final headers = {
      // (مهم جداً) تغيير نوع المحتوى إلى فورم
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json', // (نخبر السيرفر أننا نتوقع رداً بصيغة JSON)
    };

    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body, // (هنا التغيير الأهم: لا نستخدم jsonEncode)
    );

    // نستخدم نفس دالة معالجة الرد
    return _handleResponse(response);
  }
}