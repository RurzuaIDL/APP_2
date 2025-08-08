// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:front_2/widgets/dashboard_view.dart';
import 'package:front_2/widgets/profile.dart';
import 'package:front_2/widgets/tabla_con_filtro.dart';
import 'package:front_2/widgets/sidebar.dart';
import 'package:front_2/widgets/teams.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = 'Guest';
  List<String> _roles = const [];
  int _selectedIndex = 0;
  bool _railOpen = true; // 👈 controla si el sidebar está visible

  final _titles = const ['Dashboard', 'Table', 'Messages', 'Team', 'Settings'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  String _formatName(String value) {
    if (value.contains('@')) {
      final local = value.split('@').first;
      return local
          .split(RegExp(r'[.\-_ ]+'))
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');
    }
    return value
        .split(RegExp(r'[_\-. ]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _loadUserData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? userFromArgs;
    if (args is String && args.trim().isNotEmpty) userFromArgs = args.trim();
    if (args is Map) {
      userFromArgs ??= (args['username'] as String?)?.trim();
      userFromArgs ??= (args['email'] as String?)?.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username')?.trim();
    final email = prefs.getString('email')?.trim();
    final roles = prefs.getStringList('roles') ?? const [];
    final rawName = userFromArgs ?? username ?? email ?? 'Guest';
    if (!mounted) return;
    setState(() {
      _displayName = _formatName(rawName);
      _roles = roles;
    });
  }

  void _onDestinationSelected(int index) => setState(() => _selectedIndex = index);

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return const DashboardView();
      case 1: return const TablaConFiltro();
      case 2: return const Center(child: Text('Messages'));
      case 3: return const UsersWidget();
      case 4: return const Center(child: Text('Settings'));
      default: return const Center(child: Text('No encontrado'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_selectedIndex >= 0 && _selectedIndex < _titles.length) ? _selectedIndex : 0;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_titles[safeIndex]),
        leading: IconButton( // 👈 opcional: reabrir desde AppBar
          tooltip: _railOpen ? 'Ocultar menú' : 'Mostrar menú',
          icon: Icon(_railOpen ? Icons.menu_open : Icons.menu),
          onPressed: () => setState(() => _railOpen = !_railOpen),
        ),
        actions: [
          Tooltip(
            message: _roles.isEmpty
                ? 'Sin roles'
                : _roles.map((r) => r.replaceAll('ROLE_', '')).join(', '),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'perfil') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'perfil',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Perfil'),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(_displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 8),
                    Text(_displayName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // 👇 Bloque del sidebar + divisor: aparece/desaparece completo
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _railOpen
                  ? Row(
                      key: const ValueKey('rail-open'),
                      children: [
                        CustomNavigationRail(
                          username: _displayName,
                          roles: _roles,
                          selectedIndex: safeIndex,
                          onSelect: _onDestinationSelected,
                          onCollapse: () => setState(() => _railOpen = false), // 👈 cierra completo
                        ),
                        const VerticalDivider(width: 1),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('rail-closed')),
            ),

            // Contenido principal
            Expanded(child: _buildPage(safeIndex)),
          ],
        ),
      ),
    );
  }
}
