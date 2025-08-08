// lib/widgets/create_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:front_2/service/userapi.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _roleIds = TextEditingController(); // opcional: "1,2,3"
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    _roleIds.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      List<int>? roleIds;
      if (_roleIds.text.trim().isNotEmpty) {
        roleIds = _roleIds.text
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .where((v) => v != null)
            .cast<int>()
            .toList();
      }

      await UserApi.createUser(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
        roleIds: roleIds?.isEmpty == true ? null : roleIds,
      );
      if (!mounted) return;
      Navigator.pop(context, true); // éxito
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear usuario'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (v) => (v==null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v==null || v.trim().isEmpty) return 'Requerido';
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
                  return ok ? null : 'Email inválido';
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pass,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v==null || v.length<6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pass2,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v != _pass.text) ? 'No coincide' : null,
              ),
              const SizedBox(height: 10),
              // Opcional: IDs de rol separados por coma
              TextFormField(
                controller: _roleIds,
                decoration: const InputDecoration(
                  labelText: 'IDs de roles (opcional, ej: 1,2)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
          label: const Text('Crear'),
        ),
      ],
    );
  }
}
