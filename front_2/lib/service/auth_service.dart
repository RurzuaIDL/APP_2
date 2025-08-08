import 'dart:convert';
import 'package:front_2/service/api_helper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> login(String username, String password) async {
    final response = await http.post(
      ApiHelper.buildUri('/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwtToken', data['jwt']);
      await prefs.setString('username', username);
      await prefs.setString('email', data['email']);
      await prefs.setString('id', data['id']);
      await prefs.setStringList('roles', List<String>.from(data['roles']));
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('roles') ?? [];
  }
}
