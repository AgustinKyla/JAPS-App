// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../data/data_store.dart';
import '../models/models.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'dashboard_page.dart';
import 'remittances_page.dart';
import 'buses_page.dart';
import 'routes_page.dart';
import 'fare_settings_page.dart';
import 'schedules_page.dart';
import 'users_page.dart';

enum AppTab {
  dashboard,
  remittances,
  buses,
  routes,
  fareSettings,
  schedules,
  users,
}

extension AppTabX on AppTab {
  String get label {
    switch (this) {
      case AppTab.dashboard:
        return 'Dashboard';
      case AppTab.remittances:
        return 'Remittances';
      case AppTab.buses:
        return 'Buses';
      case AppTab.routes:
        return 'Routes';
      case AppTab.fareSettings:
        return 'Fare Settings';
      case AppTab.schedules:
        return 'Schedules';
      case AppTab.users:
        return 'Users';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.dashboard:
        return Icons.grid_view_rounded;
      case AppTab.remittances:
        return Icons.receipt_long_rounded;
      case AppTab.buses:
        return Icons.directions_bus_rounded;
      case AppTab.routes:
        return Icons.alt_route_rounded;
      case AppTab.fareSettings:
        return Icons.sell_rounded;
      case AppTab.schedules:
        return Icons.event_note_rounded;
      case AppTab.users:
        return Icons.people_alt_rounded;
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.dashboard;
  bool _collapsed = false;

  Widget _content() {
    switch (_tab) {
      case AppTab.dashboard:
        return const DashboardPage();
      case AppTab.remittances:
        return const RemittancesPage();
      case AppTab.buses:
        return const BusesPage();
      case AppTab.routes:
        return const RoutesPage();
      case AppTab.fareSettings:
        return const FareSettingsPage();
      case AppTab.schedules:
        return const SchedulesPage();
      case AppTab.users:
        return const UsersPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final store = DataScope.of(context);
    final authService = AuthScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([store, authService]),
      builder: (context, _) {
        final currentUser = authService.currentUser;
        final displayName = currentUser?.name ?? 'User';
        final displayRole = currentUser?.role.label.toUpperCase() ?? 'ROLE';

        final sidebar = Sidebar(
          collapsed: _collapsed && !isMobile,
          current: _tab,
          username: displayName,
          role: displayRole,
          onSelect: (t) {
            setState(() => _tab = t);
            if (isMobile) Navigator.of(context).maybePop();
          },
          onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
          showCollapseToggle: !isMobile,
        );

        return Scaffold(
          drawer: isMobile ? Drawer(child: sidebar) : null,
          body: Row(
            children: [
              if (!isMobile) sidebar,
              Expanded(
                child: Column(
                  children: [
                    TopBar(
                      isMobile: isMobile,
                      title: 'Owner Portal',
                      username: displayName,
                    ),
                    Expanded(
                      child: Container(
                        color: AppColors.bg,
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: _content(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------- Sidebar --------------------

class Sidebar extends StatelessWidget {
  final bool collapsed;
  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onToggleCollapse;
  final bool showCollapseToggle;
  final String username;
  final String role;

  const Sidebar({
    super.key,
    required this.collapsed,
    required this.current,
    required this.onSelect,
    required this.onToggleCollapse,
    required this.showCollapseToggle,
    required this.username,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: collapsed ? 76 : 240,
      color: AppColors.primaryDark,
      child: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'JAPS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (showCollapseToggle)
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: onToggleCollapse,
                      tooltip: 'Collapse menu',
                    ),
                ] else if (showCollapseToggle)
                  Expanded(
                    child: IconButton(
                      icon: const Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: onToggleCollapse,
                      tooltip: 'Expand menu',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              children: AppTab.values
                  .map(
                    (t) => _NavItem(
                      tab: t,
                      collapsed: collapsed,
                      selected: t == current,
                      onTap: () => onSelect(t),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          role,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    tooltip: 'Logout',
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your JAPS account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              AuthScope.of(context).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final AppTab tab;
  final bool collapsed;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.collapsed,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? Colors.white
        : (_hover ? Colors.white.withOpacity(0.08) : Colors.transparent);
    final fg = widget.selected ? AppColors.primary : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14,
              vertical: 11,
            ),
            alignment: widget.collapsed
                ? Alignment.center
                : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.collapsed
                ? Icon(widget.tab.icon, color: fg, size: 20)
                : Row(
                    children: [
                      Icon(widget.tab.icon, color: fg, size: 19),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.tab.label,
                          style: TextStyle(
                            color: fg,
                            fontSize: 13.5,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// -------------------- Top Bar --------------------

class TopBar extends StatelessWidget {
  final bool isMobile;
  final String title;
  final String username;

  const TopBar({
    super.key, 
    required this.isMobile, 
    required this.title, 
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (v) {
              if (v == 'logout') {
                AuthScope.of(context).signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  buildSnack('Profile settings coming soon', SnackType.info),
                );
              }
            },
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}