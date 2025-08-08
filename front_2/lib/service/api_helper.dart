import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String baseUrl = 'http://localhost:8080/api';  

  static Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path, [Map<String, dynamic>? query]) async {
    final headers = await getHeaders();
    final uri = buildUri(path, query);
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> post(String path, dynamic body) async {
    final headers = await getHeaders();
    final uri = buildUri(path);
    return http.post(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String path, dynamic body) async {
    final headers = await getHeaders();
    final uri = buildUri(path);
    return http.put(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    final headers = await getHeaders();
    final uri = buildUri(path);
    return http.delete(uri, headers: headers);
  }

  static Future<http.Response> postPlainText(String path, String plainText) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwtToken') ?? '';
  final uri = buildUri(path);
  final headers = {
    'Content-Type': 'text/plain',
    'Authorization': 'Bearer $token',
  };
  return http.post(uri, headers: headers, body: plainText);
}

}
