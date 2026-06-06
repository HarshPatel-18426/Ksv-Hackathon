import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/user_role.dart';
import '../models/vendor.dart';
import '../models/rfq.dart';
import '../models/approval.dart';
import '../models/purchase_order.dart';
import '../models/activity.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final erp = Provider.of<ErpProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        erp.loadAllData(auth.currentUser);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final erpProvider = Provider.of<ErpProvider>(context);

    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // 1. Calculate KPI Metrics
    final totalVendorsCount = erpProvider.vendors.length;
    final activeRfqsCount = erpProvider.rfqs.where((r) => r.status == RfqStatus.published).length;
    final pendingApprovalsCount = erpProvider.approvals.where((a) => a.status == ApprovalStatus.pending || a.status == ApprovalStatus.underReview).length;
    final totalSpendAmount = erpProvider.purchaseOrders
        .where((po) => po.status != PoStatus.draft)
        .fold(0.0, (sum, po) => sum + po.totalAmount);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    return ResponsiveScaffold(
      title: 'Procurement Dashboard',
      floatingActionButton: _buildSpeedDial(context, role),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header Card
              _buildWelcomeCard(context, user),
              const SizedBox(height: 20),

              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final kpiWidth = isMobile ? (constraints.maxWidth - 8) / 2 : (constraints.maxWidth - 24) / 4;
                  final List<Widget> kpiCards = [
                    SizedBox(
                      width: kpiWidth,
                      child: KpiCard(
                        title: 'Total Vendors',
                        value: '$totalVendorsCount',
                        icon: Icons.people,
                        iconColor: const Color(0xFF2E86AB),
                        trend: '+2 new this month',
                        isPositiveTrend: true,
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: KpiCard(
                        title: 'Active RFQs',
                        value: '$activeRfqsCount',
                        icon: Icons.assignment_outlined,
                        iconColor: const Color(0xFFF39C12),
                        trend: '3 closing soon',
                        isPositiveTrend: null,
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: KpiCard(
                        title: 'Pending Approvals',
                        value: '$pendingApprovalsCount',
                        icon: Icons.fact_check_outlined,
                        iconColor: const Color(0xFFE74C3C),
                        trend: pendingApprovalsCount > 0 ? '$pendingApprovalsCount action required' : 'All clear',
                        isPositiveTrend: pendingApprovalsCount > 0 ? false : true,
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: KpiCard(
                        title: 'Total Spend',
                        value: Formatters.formatCurrency(totalSpendAmount),
                        icon: Icons.monetization_on_outlined,
                        iconColor: const Color(0xFF27AE60),
                        trend: '+8.4% vs last quarter',
                        isPositiveTrend: false, // high spend is usually red/negative trend
                      ),
                    ),
                  ];

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kpiCards,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Charts Layout
              if (isMobile) ...[
                _buildSpendChartCard(context, erpProvider.purchaseOrders),
                const SizedBox(height: 16),
                _buildVendorPerformanceChartCard(context, erpProvider.vendors),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildSpendChartCard(context, erpProvider.purchaseOrders)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildVendorPerformanceChartCard(context, erpProvider.vendors)),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Recent Activities Feed & Shortcuts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildRecentActivityFeed(context, erpProvider.activities),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildWorkflowShortcuts(context, role),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, UserProfile? user) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user?.name ?? 'User'}!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You are logged in as ${user?.role.label}. Here is an overview of the procurement pipeline today.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (user?.role == UserRole.vendor)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: StatusChip(
                  label: user?.companyName ?? 'Tata Steel',
                  color: theme.colorScheme.primary,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSpendChartCard(BuildContext context, List<PurchaseOrder> pos) {
    final theme = Theme.of(context);
    
    // Calculate actual spend per month for the last 6 months
    final now = DateTime.now();
    final Map<int, double> monthlySpend = {};
    for (int i = 0; i < 6; i++) {
      monthlySpend[now.month - i] = 0.0;
    }

    for (var po in pos) {
      if (po.status != PoStatus.draft) {
        final month = po.createdAt.month;
        if (monthlySpend.containsKey(month)) {
          monthlySpend[month] = monthlySpend[month]! + (po.totalAmount / 100000); // In Lakhs
        }
      }
    }

    final spots = List.generate(6, (i) {
      final month = now.month - (5 - i);
      return FlSpot(i.toDouble(), monthlySpend[month] ?? 0.0);
    });

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spend Analysis (Last 6 Months)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly procurement spend in INR (Lakhs)',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          int monthIdx = (now.month - (5 - value.toInt()) - 1) % 12;
                          if (monthIdx < 0) monthIdx += 12;
                          
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(months[monthIdx], style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorPerformanceChartCard(BuildContext context, List<Vendor> vendors) {
    final theme = Theme.of(context);
    final activeVendors = vendors.take(3).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Rating & Score',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Comparative score (Price, Quality, Delivery)',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < activeVendors.length) {
                            final name = activeVendors[value.toInt()].name.split(' ')[0]; // Tata, Reliance, Larsen
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(activeVendors.length, (idx) {
                    final vendor = activeVendors[idx];
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: vendor.performance.overallScore,
                          color: theme.colorScheme.secondary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        )
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityFeed(BuildContext context, List<ActivityLogEntry> activities) {
    final theme = Theme.of(context);
    final displayedActivities = activities.take(5).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recent Activity Feed',
              actionLabel: 'View All',
              onAction: () => context.go('/activity-log'),
            ),
            const Divider(),
            if (displayedActivities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text('No activities recorded yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedActivities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final act = displayedActivities[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Text(
                        act.userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      act.actionDescription,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          Formatters.formatDateTime(act.timestamp),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: act.module,
                          color: _getModuleColor(act.module, theme),
                        )
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getModuleColor(String module, ThemeData theme) {
    switch (module.toLowerCase()) {
      case 'vendor':
        return const Color(0xFF2E86AB);
      case 'rfq':
        return const Color(0xFFF39C12);
      case 'approval':
        return const Color(0xFFE74C3C);
      case 'po':
        return const Color(0xFF27AE60);
      case 'invoice':
        return theme.colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildWorkflowShortcuts(BuildContext context, UserRole role) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Quick Workflow Access',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildShortcutTile(
              context,
              icon: Icons.assignment_outlined,
              title: 'Request for Quotations',
              subtitle: 'Create RFQs & invite vendors',
              route: '/rfqs',
            ),
            if (role != UserRole.vendor) ...[
              _buildShortcutTile(
                context,
                icon: Icons.people_outline,
                title: 'Vendor Registry',
                subtitle: 'Manage and rate suppliers',
                route: '/vendors',
              ),
              _buildShortcutTile(
                context,
                icon: Icons.rule_folder_outlined,
                title: 'Approval Center',
                subtitle: 'Approve POs & RFQ awards',
                route: '/approvals',
              ),
            ],
            _buildShortcutTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Invoice Tracking',
              subtitle: 'Upload and monitor payouts',
              route: '/invoices',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required String route}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.go(route),
    );
  }

  Widget? _buildSpeedDial(BuildContext context, UserRole role) {
    // Only show FAB with speed dial for Admin and Procurement Officer
    if (role != UserRole.admin && role != UserRole.procurementOfficer) {
      return null;
    }

    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          FloatingActionButton.small(
            heroTag: 'add_vendor_fab',
            onPressed: () {
              setState(() => _isSpeedDialOpen = false);
              context.go('/vendors');
              // Trigger vendor dialog addition in next screen
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'create_rfq_fab',
            onPressed: () {
              setState(() => _isSpeedDialOpen = false);
              context.go('/rfqs');
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: const Icon(Icons.note_add_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'create_po_fab',
            onPressed: () {
              setState(() => _isSpeedDialOpen = false);
              context.go('/purchase-orders');
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: const Icon(Icons.shopping_cart_checkout),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          heroTag: 'main_speed_dial_fab',
          onPressed: () {
            setState(() {
              _isSpeedDialOpen = !_isSpeedDialOpen;
            });
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: AnimatedRotation(
            turns: _isSpeedDialOpen ? 0.125 : 0.0, // Rotate a little
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
