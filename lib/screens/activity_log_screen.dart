import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/erp_provider.dart';
import '../models/activity.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../utils/formatters.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String _selectedModule = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);

    // Apply Filters
    List<ActivityLogEntry> filteredLogs = erpProvider.activities.where((act) {
      final matchesModule = _selectedModule == 'All' || act.module.toLowerCase() == _selectedModule.toLowerCase();
      final matchesSearch = act.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          act.actionDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesModule && matchesSearch;
    }).toList();

    return ResponsiveScaffold(
      title: 'Audit Trail & Activity Log',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Bar Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Filter logs by user or description...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Module: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          _buildModuleFilterChip('All'),
                          const SizedBox(width: 6),
                          _buildModuleFilterChip('Vendor'),
                          const SizedBox(width: 6),
                          _buildModuleFilterChip('RFQ'),
                          const SizedBox(width: 6),
                          _buildModuleFilterChip('Approval'),
                          const SizedBox(width: 6),
                          _buildModuleFilterChip('PO'),
                          const SizedBox(width: 6),
                          _buildModuleFilterChip('Invoice'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logs Feed
            Expanded(
              child: filteredLogs.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_toggle_off,
                      title: 'No Logs Recorded',
                      subtitle: 'No system activities matches the filtered search criteria.',
                    )
                  : ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, idx) {
                        final act = filteredLogs[idx];
                        return _buildActivityTile(context, act, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleFilterChip(String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _selectedModule == label,
      onSelected: (val) {
        if (val) setState(() => _selectedModule = label);
      },
    );
  }

  Widget _buildActivityTile(BuildContext context, ActivityLogEntry act, ThemeData theme) {
    final hasDiff = act.beforeValues != null || act.afterValues != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: hasDiff
          ? ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(act.userName.substring(0, 1).toUpperCase(), style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
              ),
              title: Text(act.actionDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  Text(Formatters.formatDateTime(act.timestamp), style: TextStyle(color: theme.colorScheme.outline, fontSize: 11)),
                  const SizedBox(width: 8),
                  StatusChip(label: act.module, color: _getModuleColor(act.module, theme)),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Changes State Diff Snapshot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      _buildDiffTable(act.beforeValues, act.afterValues, theme),
                    ],
                  ),
                ),
              ],
            )
          : ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(act.userName.substring(0, 1).toUpperCase(), style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
              ),
              title: Text(act.actionDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  Text(Formatters.formatDateTime(act.timestamp), style: TextStyle(color: theme.colorScheme.outline, fontSize: 11)),
                  const SizedBox(width: 8),
                  StatusChip(label: act.module, color: _getModuleColor(act.module, theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildDiffTable(Map<String, dynamic>? before, Map<String, dynamic>? after, ThemeData theme) {
    // Collect all unique keys
    final keys = <String>{};
    if (before != null) keys.addAll(before.keys);
    if (after != null) keys.addAll(after.keys);

    final filteredKeys = keys.where((k) => k != 'id' && k != 'activityLog' && k != 'attachments').toList();

    return Table(
      border: TableBorder.all(color: theme.colorScheme.outlineVariant, width: 1),
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
          children: const [
            Padding(padding: EdgeInsets.all(6), child: Text('Field / Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6), child: Text('Before Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6), child: Text('After Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        ...filteredKeys.map((key) {
          final beforeVal = before?[key]?.toString() ?? 'N/A';
          final afterVal = after?[key]?.toString() ?? 'N/A';
          final isChanged = beforeVal != afterVal;

          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(6), child: Text(key, style: const TextStyle(fontSize: 11))),
              Padding(padding: const EdgeInsets.all(6), child: Text(beforeVal, style: TextStyle(fontSize: 11, color: isChanged ? Colors.red : null))),
              Padding(padding: const EdgeInsets.all(6), child: Text(afterVal, style: TextStyle(fontSize: 11, fontWeight: isChanged ? FontWeight.bold : null, color: isChanged ? Colors.green : null))),
            ],
          );
        }),
      ],
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
}
