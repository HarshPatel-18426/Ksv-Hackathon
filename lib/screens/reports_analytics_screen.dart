import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../utils/formatters.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 90)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    return ResponsiveScaffold(
      title: 'Reports & Analytics',
      body: Column(
        children: [
          // Filter & Export Header Bar
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Period: ${Formatters.formatDate(_dateRange.start)} - ${Formatters.formatDate(_dateRange.end)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text('Change Range'),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download_for_offline_outlined, size: 16),
                      label: const Text('Export CSV'),
                      onPressed: () => _exportCsv(context),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tab Bar headers
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Spend Analysis'),
              Tab(text: 'Vendor Volume'),
              Tab(text: 'Cycle Time'),
              Tab(text: 'Savings Report'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSpendAnalysisTab(context, theme, isMobile),
                _buildVendorVolumeTab(context, theme, isMobile),
                _buildCycleTimeTab(context, theme, isMobile),
                _buildSavingsReportTab(context, theme, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendAnalysisTab(BuildContext context, ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spend KPI metrics
          _buildKpiGrid(
            context,
            isMobile,
            c1: const KpiCard(title: 'Total Spend', value: '₹34,50,000', icon: Icons.monetization_on_outlined, iconColor: Colors.green),
            c2: const KpiCard(title: 'Average Order', value: '₹11,50,000', icon: Icons.payments_outlined, iconColor: Colors.blue),
            c3: const KpiCard(title: 'PO Count', value: '3 Active', icon: Icons.shopping_bag_outlined, iconColor: Colors.indigo),
            c4: const KpiCard(title: 'Invoiced value', value: '₹39,53,000', icon: Icons.receipt_long_outlined, iconColor: Colors.amber),
          ),
          const SizedBox(height: 20),

          // Pie Chart & Legend
          Card(
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
                  const Text('Spend by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Donut Pie chart
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(value: 55, color: Colors.blue[900], title: '55%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                                PieChartSectionData(value: 20, color: Colors.blue[500], title: '20%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                                PieChartSectionData(value: 15, color: Colors.green[500], title: '15%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                                PieChartSectionData(value: 10, color: Colors.orange[500], title: '10%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Legend
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Metals & Alloys', Colors.blue[900]!),
                            _buildLegendItem('Engineering', Colors.blue[500]!),
                            _buildLegendItem('Polymers', Colors.green[500]!),
                            _buildLegendItem('Cement', Colors.orange[500]!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorVolumeTab(BuildContext context, ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiGrid(
            context,
            isMobile,
            c1: const KpiCard(title: 'Top Vendor Spend', value: '₹22,50,000', icon: Icons.star_border, iconColor: Colors.orange),
            c2: const KpiCard(title: 'Active Vendors', value: '3 Active', icon: Icons.people_outline, iconColor: Colors.blue),
            c3: const KpiCard(title: 'Avg Quality Score', value: '96.2 / 100', icon: Icons.high_quality_outlined, iconColor: Colors.green),
            c4: const KpiCard(title: 'Avg Delivery Score', value: '94.0 / 100', icon: Icons.local_shipping_outlined, iconColor: Colors.indigo),
          ),
          const SizedBox(height: 20),

          // Bar Chart: Top Vendors by volume
          Card(
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
                  const Text('Top 5 Vendors by Volume (INR Lakhs)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const names = ['Tata Steel', 'Reliance', 'L&T', 'Birla', 'Standard'];
                                if (value.toInt() >= 0 && value.toInt() < names.length) {
                                  return SideTitleWidget(meta: meta, child: Text(names[value.toInt()], style: const TextStyle(fontSize: 10)));
                                }
                                return Container();
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 22.5, color: Colors.blue[900], width: 16)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 11.0, color: Colors.blue[700], width: 16)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1.0, color: Colors.blue[500], width: 16)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 0.0, color: Colors.grey, width: 16)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 0.0, color: Colors.grey, width: 16)]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleTimeTab(BuildContext context, ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiGrid(
            context,
            isMobile,
            c1: const KpiCard(title: 'RFQ to Award', value: '4.2 Days', icon: Icons.timer, iconColor: Colors.amber),
            c2: const KpiCard(title: 'PO to Delivery', value: '9.4 Days', icon: Icons.local_shipping, iconColor: Colors.blue),
            c3: const KpiCard(title: 'Invoice Payout', value: '18.5 Days', icon: Icons.monetization_on, iconColor: Colors.green),
            c4: const KpiCard(title: 'Total Cycle Time', value: '32.1 Days', icon: Icons.av_timer_outlined, iconColor: Colors.indigo),
          ),
          const SizedBox(height: 20),

          // Line chart: Cycle time trend
          Card(
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
                  const Text('Procurement Cycle Time Trend (Avg Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const weeks = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];
                                if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                                  return SideTitleWidget(meta: meta, child: Text(weeks[value.toInt()], style: const TextStyle(fontSize: 10)));
                                }
                                return Container();
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 15.2),
                              FlSpot(1, 14.1),
                              FlSpot(2, 11.5),
                              FlSpot(3, 12.8),
                              FlSpot(4, 9.4),
                              FlSpot(5, 8.2),
                            ],
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsReportTab(BuildContext context, ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiGrid(
            context,
            isMobile,
            c1: const KpiCard(title: 'Estimated Spend', value: '₹36,70,000', icon: Icons.calculate_outlined, iconColor: Colors.grey),
            c2: const KpiCard(title: 'Actual Award Spend', value: '₹34,50,000', icon: Icons.payments, iconColor: Colors.blue),
            c3: const KpiCard(title: 'Total Savings', value: '₹2,20,000', icon: Icons.savings_outlined, iconColor: Colors.green),
            c4: const KpiCard(title: 'Savings Margin', value: '6.0%', icon: Icons.trending_up, iconColor: Colors.teal),
          ),
          const SizedBox(height: 20),

          // Savings by month bar chart
          Card(
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
                  const Text('Savings Margin by Month (₹ Thousand)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return SideTitleWidget(meta: meta, child: Text(months[value.toInt()], style: const TextStyle(fontSize: 10)));
                                }
                                return Container();
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 30, color: Colors.green, width: 18)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 45, color: Colors.green, width: 18)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 20, color: Colors.green, width: 18)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 60, color: Colors.green, width: 18)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 35, color: Colors.green, width: 18)]),
                          BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 80, color: Colors.green, width: 18)]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, bool isMobile, {required Widget c1, required Widget c2, required Widget c3, required Widget c4}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final kpiWidth = isMobile ? (constraints.maxWidth - 8) / 2 : (constraints.maxWidth - 24) / 4;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(width: kpiWidth, child: c1),
            SizedBox(width: kpiWidth, child: c2),
            SizedBox(width: kpiWidth, child: c3),
            SizedBox(width: kpiWidth, child: c4),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _exportCsv(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated CSV Export: Downloaded report metrics successfully!'),
        backgroundColor: Color(0xFF27AE60),
      ),
    );
  }
}
