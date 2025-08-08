// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';
import 'package:front_2/service/auth_service.dart';

class CustomNavigationRail extends StatelessWidget {
  final String username; // no se muestra aquí, pero lo mantenemos por firma
  final List<String> roles; // idem
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCollapse; // 👈 nuevo: pide al padre que colapse

  const CustomNavigationRail({
    super.key,
    required this.username,
    required this.roles,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCollapse, // 👈 requerido
  });

  static const double _railWidth = 112;

  @override
  Widget build(BuildContext context) {
    const destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.tab_outlined),
        selectedIcon: Icon(Icons.tab),
        label: Text('Table'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.mail_outline),
        selectedIcon: Icon(Icons.mail),
        label: Text('Messages'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Team'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];

    return SizedBox(
      width: _railWidth,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              const Divider(height: 1),

              // 🔘 Rail
              Expanded(
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelect,
                  extended: false,
                  minWidth: _railWidth,
                  minExtendedWidth: _railWidth,
                  groupAlignment: -1.0,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations,
                ),
              ),

              // ⤵️ Logout abajo
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await AuthService().logout();
                      if (!context.mounted) return;
                      // Si quieres, envía a login:
                      // ignore: use_build_context_synchronously
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
