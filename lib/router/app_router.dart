import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';

// Screens placeholder imports (we will create these files shortly)
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/vendor_registry_screen.dart';
import '../screens/rfq_management_screen.dart';
import '../screens/quotation_comparison_screen.dart';
import '../screens/approval_workflow_screen.dart';
import '../screens/purchase_orders_screen.dart';
import '../screens/invoice_management_screen.dart';
import '../screens/reports_analytics_screen.dart';
import '../screens/activity_log_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> parentNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final initialized = authProvider.initialized;
        if (!initialized) return null; // Wait until session is loaded

        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.uri.path == '/login';

        // 1. Authentication check
        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }
        if (isLoggedIn && isLoggingIn) {
          return '/dashboard';
        }

        if (!isLoggedIn) return null;

        // 2. Role-based authorization guard
        final role = authProvider.currentUser!.role;
        final path = state.uri.path;

        if (path.startsWith('/vendors') && !_isAllowed(role, [UserRole.admin, UserRole.procurementOfficer, UserRole.manager])) {
          return '/dashboard';
        }
        if (path.startsWith('/approvals') && !_isAllowed(role, [UserRole.admin, UserRole.manager, UserRole.procurementOfficer])) {
          return '/dashboard';
        }
        if (path.startsWith('/purchase-orders') && !_isAllowed(role, [UserRole.admin, UserRole.procurementOfficer, UserRole.manager])) {
          return '/dashboard';
        }
        if (path.startsWith('/reports') && !_isAllowed(role, [UserRole.admin, UserRole.manager])) {
          return '/dashboard';
        }
        if (path.startsWith('/activity-log') && !_isAllowed(role, [UserRole.admin, UserRole.manager])) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/vendors',
          builder: (context, state) => const VendorRegistryScreen(),
        ),
        GoRoute(
          path: '/rfqs',
          builder: (context, state) => const RfqManagementScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return RfqDetailScreen(rfqId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/quotation-comparison/:rfqId',
          builder: (context, state) {
            final rfqId = state.pathParameters['rfqId']!;
            return QuotationComparisonScreen(rfqId: rfqId);
          },
        ),
        GoRoute(
          path: '/approvals',
          builder: (context, state) => const ApprovalWorkflowScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ApprovalDetailScreen(approvalId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/purchase-orders',
          builder: (context, state) => const PurchaseOrdersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return PurchaseOrderDetailScreen(poId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoiceManagementScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return InvoiceDetailScreen(invoiceId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsAnalyticsScreen(),
        ),
        GoRoute(
          path: '/activity-log',
          builder: (context, state) => const ActivityLogScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Route not found: ${state.error}'),
        ),
      ),
    );
  }

  static bool _isAllowed(UserRole role, List<UserRole> allowed) {
    return allowed.contains(role);
  }
}
