
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