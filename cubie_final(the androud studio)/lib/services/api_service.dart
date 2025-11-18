
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // !! تأكد من عنوان IP !!
  static const String _baseUrl = 'http://192.168.8.22';

  static Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (isJson) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    } else {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('API Error (${response.statusCode}): ${response.body}');
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['detail'] ?? 'Failed: ${response.statusCode}');
      } catch (e) {
        throw Exception('Failed: ${response.statusCode}, Body: ${response.body}');
      }
    }
  }

  // --- طلبات JSON (للقوائم والبيانات) ---
  static Future<Map<String, dynamic>> getRequest(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl$endpoint'), headers: headers);
    return _handleResponse(response);
  }

  // --- طلبات Form Data (للتسجيل، الإضافة، التعديل) ---
  // 1. POST FORM (Sign up, Login, Add Child)
  static Future<Map<String, dynamic>> postFormRequest(String endpoint, Map<String, String> body) async {
    final headers = await _getHeaders(isJson: false);
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body,
    );
    return _handleResponse(response);
  }

  // 2. PUT FORM (Edit Profile, Edit Child) - هذا كان ناقصاً ويسبب المشاكل
  static Future<Map<String, dynamic>> putFormRequest(String endpoint, Map<String, String> body) async {
    final headers = await _getHeaders(isJson: false);
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$_baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }
}