// lib/models/user_model.dart
class AppUser {
  final int? id;
  final String username;
  final String email;
  final List<String> roles; // e.g. ["ROLE_USER","ROLE_ADMIN"]

  AppUser({
    this.id,
    required this.username,
    required this.email,
    required this.roles,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // roles puede venir como lista de strings o de objetos { name: "ROLE_USER" }
    final rawRoles = (j['roles'] as List?) ?? const [];
    final roles = rawRoles.map((e) {
      if (e is String) return e;
      if (e is Map && e['name'] != null) return e['name'].toString();
      return e.toString();
    }).toList();
    return AppUser(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
      username: '${j['username'] ?? ''}',
      email: '${j['email'] ?? ''}',
      roles: roles,
    );
  }
}
