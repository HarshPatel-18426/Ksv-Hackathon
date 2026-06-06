import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import 'status_chip.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final List<UserRole> allowedRoles;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.allowedRoles,
  });
}

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final Widget? floatingActionButton;

  ResponsiveScaffold({
    super.key,
    required this.body,
    required this.title,
    this.floatingActionButton,
  });

  // Complete list of screens in navigation drawer
  final List<NavigationItem> _menuItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
      allowedRoles: UserRole.values,
    ),
    NavigationItem(
      title: 'Vendors',
      icon: Icons.people_outline,
      route: '/vendors',
      allowedRoles: [UserRole.admin, UserRole.procurementOfficer, UserRole.manager],
    ),
    NavigationItem(
      title: 'RFQs',
      icon: Icons.request_quote_outlined,
      route: '/rfqs',
      allowedRoles: UserRole.values,
    ),
    NavigationItem(
      title: 'Approvals',
      icon: Icons.rule_folder_outlined,
      route: '/approvals',
      allowedRoles: [UserRole.admin, UserRole.manager, UserRole.procurementOfficer],
    ),
    NavigationItem(
      title: 'Purchase Orders',
      icon: Icons.shopping_bag_outlined,
      route: '/purchase-orders',
      allowedRoles: [UserRole.admin, UserRole.procurementOfficer, UserRole.manager],
    ),
    NavigationItem(
      title: 'Invoices',
      icon: Icons.receipt_long_outlined,
      route: '/invoices',
      allowedRoles: UserRole.values,
    ),
    NavigationItem(
      title: 'Reports & Analytics',
      icon: Icons.analytics_outlined,
      route: '/reports',
      allowedRoles: [UserRole.admin, UserRole.manager],
    ),
    NavigationItem(
      title: 'Activity Log',
      icon: Icons.history_outlined,
      route: '/activity-log',
      allowedRoles: [UserRole.admin, UserRole.manager],
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings',
      allowedRoles: UserRole.values,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userRole = user?.role ?? UserRole.procurementOfficer;

    // Filter items based on user role
    final accessibleItems = _menuItems.where((item) => item.allowedRoles.contains(userRole)).toList();

    // Determine current active route to highlight it
    final currentRoute = GoRouterState.of(context).uri.path;

    // Determine current index for BottomNavigationBar or NavigationRail
    int activeIndex = accessibleItems.indexWhere((item) => currentRoute.startsWith(item.route));
    if (activeIndex == -1) activeIndex = 0; // Default to Dashboard if not found (e.g. details pages)

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: StatusChip(
                label: user.role.label,
                color: _getRoleColor(user.role),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
      drawer: isMobile ? _buildDrawer(context, user, accessibleItems, currentRoute) : null,
      bottomNavigationBar: isMobile
          ? _buildBottomBar(context, accessibleItems, activeIndex)
          : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (!isMobile) ...[
            _buildNavigationRail(context, accessibleItems, activeIndex),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: SafeArea(child: body),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFE74C3C); // red
      case UserRole.procurementOfficer:
        return const Color(0xFF2E86AB); // accent blue
      case UserRole.manager:
        return const Color(0xFFF39C12); // warning yellow/orange
      case UserRole.vendor:
        return const Color(0xFF27AE60); // success green
    }
  }

  Widget _buildBottomBar(BuildContext context, List<NavigationItem> items, int activeIndex) {
    // BottomNavigationBar can only show up to 5 items comfortably.
    // If there are more than 5, show first 4 + a Drawer trigger (handled by default burger drawer icon in App Bar).
    final bottomItems = items.take(5).toList();
    if (activeIndex >= bottomItems.length) {
      activeIndex = 0; // Prevent out of range if on an overflow item like settings
    }

    return BottomNavigationBar(
      currentIndex: activeIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.outline,
      showUnselectedLabels: true,
      onTap: (index) {
        context.go(bottomItems[index].route);
      },
      items: bottomItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.title,
        );
      }).toList(),
    );
  }

  Widget _buildNavigationRail(BuildContext context, List<NavigationItem> items, int activeIndex) {
    return NavigationRail(
      selectedIndex: activeIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        context.go(items[index].route);
      },
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _handleLogout(context),
            ),
          ),
        ),
      ),
      destinations: items.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
          label: Text(item.title),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer(BuildContext context, UserProfile? user, List<NavigationItem> items, String currentRoute) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(user?.name ?? 'Guest User'),
            accountEmail: Text(user?.email ?? 'guest@vendorbridge.in'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text(
                (user?.name ?? 'G').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            otherAccountsPictures: [
              if (user != null)
                Chip(
                  label: Text(user.role.label, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: _getRoleColor(user.role),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...items.map((item) {
                  final isSelected = currentRoute.startsWith(item.route);
                  return ListTile(
                    leading: Icon(item.icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      context.go(item.route);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'VendorBridge ERP v1.0',
              style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out of VendorBridge?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Provider.of<AuthProvider>(context, listen: false).logout().then((_) {
                  context.go('/login');
                });
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
