import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front_2/models/user_model.dart';
import 'package:front_2/service/userapi.dart';
import 'package:front_2/widgets/create_dialog_user.dart';
import 'package:front_2/widgets/profile.dart';

class UsersWidget extends StatefulWidget {
  final void Function(AppUser user)? onUserTap;
  const UsersWidget({super.key, this.onUserTap});

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState extends State<UsersWidget> {
  final TextEditingController _qCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<AppUser> _all = [];
  List<AppUser> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _qCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await UserApi.getUsers();
      setState(() {
        _all = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _applyFilter);
  }

  void _applyFilter() {
    final q = _qCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(_all));
      return;
    }
    setState(() {
      _filtered = _all
          .where((u) =>
              u.username.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.roles.join(',').toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _createUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateUserDialog(),
    );
    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado')),
      );
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar usuario, email o rol…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _qCtrl.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _qCtrl.clear();
                                  _applyFilter();
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _applyFilter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: _fetch,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth >= 900;
                  if (!isWide) {
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88), 
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              u.username.isNotEmpty
                                  ? u.username[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(u.username),
                          subtitle: Text(
                            '${u.email}\n${u.roles.map((r) => r.replaceAll("ROLE_", "")).join(", ")}',
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(
                                  username: u.username,
                                ),
                              ),
                            );
                          },
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    );
                  } else {
                    final cols = (c.maxWidth ~/ 280).clamp(2, 6);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96), 
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 4 / 2,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: widget.onUserTap != null
                                ? () => widget.onUserTap!(u)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          u.username.isNotEmpty
                                              ? u.username[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          u.username,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    u.email,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const Spacer(),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: -6,
                                    children: u.roles.map((r) {
                                      final t = r.replaceAll('ROLE_', '');
                                      return Chip(
                                        label: Text(t),
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _createUser,
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo'),
          ),
        ),
      ],
    );
  }
}
