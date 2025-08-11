import 'package:flutter/material.dart';
import 'package:front_2/service/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String? username; 

  const ProfileScreen({super.key, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _email = '';
  List<String> _roles = [];

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedUsername = prefs.getString('username') ?? '';
    final loggedEmail = prefs.getString('email') ?? '';
    final loggedRoles = prefs.getStringList('roles') ?? [];

    setState(() {
      _username = (widget.username != null && widget.username!.trim().isNotEmpty)
          ? widget.username!.trim()
          : loggedUsername;
      _email = loggedEmail;
      _roles = loggedRoles;
    });
  }

  Future<void> _changePassword() async {
    final nuevaPass = _passwordController.text.trim();
    final confirmPass = _confirmController.text.trim();
    if (nuevaPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos los campos son obligatorios')));
      return;
    }
    if (nuevaPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiHelper.put('/usuarios/$_username/password', {'password': nuevaPass});
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contraseña de $_username actualizada')));
        _passwordController.clear();
        _confirmController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtherUser = widget.username != null && widget.username!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOtherUser ? 'Cambiar contraseña' : 'Perfil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(child: CircleAvatar(radius: 40, child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : '?'))),
            const SizedBox(height: 12),
            Center(child: Text(_username, style: Theme.of(context).textTheme.headlineSmall)),
            if (!isOtherUser) ...[
              Center(child: Text(_email, style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(height: 8),
              Center(child: Wrap(spacing: 6, children: _roles.map((r) => Chip(label: Text(r.replaceAll('ROLE_', '')))).toList())),
              const Divider(height: 32),
            ] else
              const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Nueva contraseña', prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _changePassword,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Guardar nueva contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
