import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.8.19:8000';

  static Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> body
      ) async {
    try {
      print('🌐 [API] POST إلى: $baseUrl$endpoint');
      print('📦 [API] البيانات: $body');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('📡 [API] الاستجابة: ${response.statusCode}');
      print('📄 [API] المحتوى: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [API] خطأ: $e');
      throw Exception('خطأ شبكة: $e');
    }
  }

  static Future<Map<String, dynamic>> putRequest(
      String endpoint,
      Map<String, dynamic> body
      ) async {
    try {
      print('🌐 [API] PUT إلى: $baseUrl$endpoint');
      print('📦 [API] البيانات: $body');

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('📡 [API] الاستجابة: ${response.statusCode}');
      print('📄 [API] المحتوى: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [API] خطأ: $e');
      throw Exception('خطأ شبكة: $e');
    }
  }

  static Future<Map<String, dynamic>> getRequest(String endpoint) async {
    try {
      print('🌐 [API] GET من: $baseUrl$endpoint');

      final response = await http.get(Uri.parse('$baseUrl$endpoint'));

      print('📡 [API] الاستجابة: ${response.statusCode}');
      print('📄 [API] المحتوى: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [API] خطأ: $e');
      throw Exception('خطأ شبكة: $e');
    }
  }
}