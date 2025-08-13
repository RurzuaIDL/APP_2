
import 'dart:convert';
import 'package:front_2/service/api_helper.dart';
import 'package:front_2/models/user_model.dart';

class UserApi {
  static Future<List<AppUser>> getUsers() async {
    final resp = await ApiHelper.get('/usuarios/usuarios');
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is! List) throw Exception('Respuesta no es un array');
    return data.map<AppUser>((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }


  static Future<void> updateUser(String username, Map<String, dynamic> body) async {
    final resp = await ApiHelper.put('/usuarios/$username', body);
    if (resp.statusCode != 200) {
      throw Exception('No se pudo actualizar: ${resp.statusCode}');
    }
  }


  static Future<void> deleteUser(String username) async {
    final resp = await ApiHelper.delete('/usuarios/$username');
    if (resp.statusCode != 200) {
      throw Exception('No se pudo eliminar: ${resp.statusCode}');
    }
  }


  static Future<void> updatePassword(String username, String newPassword) async {
    final resp = await ApiHelper.put('/usuarios/$username/password', {'password': newPassword});
    if (resp.statusCode != 200) {
      throw Exception('No se pudo cambiar la contraseña: ${resp.statusCode}');
    }
  }

  static Future<void> createUser({
    required String username,
    required String email,
    required String password,
    List<int>? roleIds, 
  }) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
      if (roleIds != null && roleIds.isNotEmpty)
        'roles': roleIds.map((id) => {'id': id}).toList(),
    };
    final resp = await ApiHelper.post('/usuarios/signup', body);
    if (resp.statusCode != 200) {
      throw Exception('No se pudo crear el usuario: '
          'HTTP ${resp.statusCode} ${resp.body}');
    }
  }
}
