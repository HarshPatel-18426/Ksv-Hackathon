import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/approval.dart';
import '../models/user_role.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../utils/formatters.dart';

class ApprovalWorkflowScreen extends StatefulWidget {
  const ApprovalWorkflowScreen({super.key});

  @override
  State<ApprovalWorkflowScreen> createState() => _ApprovalWorkflowScreenState();
}

class _ApprovalWorkflowScreenState extends State<ApprovalWorkflowScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    // Filter approvals
    final pending = erpProvider.approvals.where((a) => a.status == ApprovalStatus.pending).toList();
    final review = erpProvider.approvals.where((a) => a.status == ApprovalStatus.underReview).toList();
    final completed = erpProvider.approvals.where((a) => a.status == ApprovalStatus.approved || a.status == ApprovalStatus.rejected).toList();

    return ResponsiveScaffold(
      title: 'Approval Workflow',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _simulatePushNotification(context, erpProvider),
        icon: const Icon(Icons.notification_important_outlined),
        label: const Text('Simulate Notification'),
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
      ),
      body: isMobile
          ? Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Pending (${pending.length})'),
                    Tab(text: 'Review (${review.length})'),
                    Tab(text: 'Completed (${completed.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApprovalList(context, pending),
                      _buildApprovalList(context, review),
                      _buildApprovalList(context, completed),
                    ],
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildKanbanColumn(context, 'Pending Requests', pending, theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKanbanColumn(context, 'Under Review', review, theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKanbanColumn(context, 'Completed', completed, theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, List<Approval> list, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Badge(
                label: Text('${list.length}'),
                backgroundColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        const Divider(thickness: 2),
        Expanded(
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
            child: list.isEmpty
                ? const Center(child: Text('No items in this stage', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final app = list[idx];
                      return _buildApprovalCard(context, app);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalList(BuildContext context, List<Approval> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No approval requests found.', style: TextStyle(fontStyle: FontStyle.italic)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final app = list[idx];
        return _buildApprovalCard(context, app);
      },
    );
  }

  Widget _buildApprovalCard(BuildContext context, Approval app) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/approvals/${app.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusChip(label: app.urgency.label, color: _getUrgencyColor(app.urgency)),
                  StatusChip(label: app.status.label, color: _getStatusColor(app.status)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                app.type,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Requested by: ${app.requester}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Value:',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  Text(
                    Formatters.formatCurrency(app.amount),
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(ApprovalUrgency urgency) {
    switch (urgency) {
      case ApprovalUrgency.low:
        return Colors.green;
      case ApprovalUrgency.medium:
        return Colors.blue;
      case ApprovalUrgency.high:
        return const Color(0xFFF39C12); // warning orange
      case ApprovalUrgency.critical:
        return const Color(0xFFE74C3C); // red error
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.grey;
      case ApprovalStatus.underReview:
        return const Color(0xFF2E86AB);
      case ApprovalStatus.approved:
        return const Color(0xFF27AE60);
      case ApprovalStatus.rejected:
        return const Color(0xFFE74C3C);
    }
  }

  void _simulatePushNotification(BuildContext context, ErpProvider erp) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      backgroundColor: Theme.of(context).colorScheme.primary,
      content: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New Pending Approval Request!', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('PO-2026-002 requires manager review - Value: ${Formatters.formatCurrency(1050000)}'),
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'View',
        textColor: Colors.white,
        onPressed: () {
          context.go('/approvals/APP-2026-002');
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// --- Detail View Screen ---
class ApprovalDetailScreen extends StatefulWidget {
  final String approvalId;

  const ApprovalDetailScreen({super.key, required this.approvalId});

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Find Approval
    final appIdx = erpProvider.approvals.indexWhere((a) => a.id == widget.approvalId);
    if (appIdx == -1) {
      return const Scaffold(body: Center(child: Text('Approval Request not found.')));
    }
    final app = erpProvider.approvals[appIdx];

    final canApprove = app.status == ApprovalStatus.pending || app.status == ApprovalStatus.underReview;
    final showActions = canApprove && (role == UserRole.admin || role == UserRole.manager);

    return ResponsiveScaffold(
      title: 'Approval Request Details',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Approvals'),
                onPressed: () => context.go('/approvals'),
              ),
              const SizedBox(height: 12),

              // Overview Block
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('Req ID: ${app.id} | Reference: ${app.targetId}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                          StatusChip(label: app.status.label, color: _getStatusColor(app.status)),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(app.description, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Value Amount: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(Formatters.formatCurrency(app.amount), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16)),
                          const Spacer(),
                          StatusChip(label: '${app.urgency.label} Urgency', color: _getUrgencyColor(app.urgency)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visual Approval Chain Stepper
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
                      const Text('Approval Verification Nodes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 20),
                      Row(
                        children: List.generate(app.chain.length, (idx) {
                          final step = app.chain[idx];
                          final isLast = idx == app.chain.length - 1;

                          return Expanded(
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: theme.colorScheme.primaryContainer,
                                          child: Text(
                                            step.userName.substring(0, 1).toUpperCase(),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                                          ),
                                        ),
                                        CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            step.status == ApprovalStatus.approved
                                                ? Icons.check_circle
                                                : step.status == ApprovalStatus.rejected
                                                    ? Icons.cancel
                                                    : Icons.hourglass_top,
                                            size: 14,
                                            color: step.status == ApprovalStatus.approved
                                                ? Colors.green
                                                : step.status == ApprovalStatus.rejected
                                                    ? Colors.red
                                                    : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(step.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(step.roleLabel, style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                                    if (step.date != null)
                                      Text(step.date!, style: TextStyle(fontSize: 9, color: theme.colorScheme.outline)),
                                  ],
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      color: step.status == ApprovalStatus.approved
                                          ? Colors.green
                                          : theme.colorScheme.outlineVariant,
                                      margin: const EdgeInsets.only(bottom: 24),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Comments Section
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
                      const Text('Comments & Audit Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      if (app.comments.isEmpty)
                        const Text('No comments yet.', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
                      else
                        ...app.comments.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    child: Text(c.userName.substring(0, 1), style: const TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(c.timestamp, style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(c.text, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Write comment...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              final text = _commentController.text.trim();
                              if (text.isNotEmpty) {
                                erpProvider.addApprovalComment(app.id, user?.name ?? 'Procurement Officer', text);
                                _commentController.clear();
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons (Approve / Reject)
              if (showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () => _handleApproveReject(context, app.id, false, user!.name),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () => _handleApproveReject(context, app.id, true, user!.name),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleApproveReject(BuildContext context, String id, bool isApprove, String userName) {
    final act = isApprove ? 'Approve' : 'Reject';
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('$act Approval Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter any comments or validation remarks for this decision:'),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final erp = Provider.of<ErpProvider>(context, listen: false);
                final remarks = commentController.text.trim();

                if (isApprove) {
                  erp.approveApproval(id, userName, remarks).then((_) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request approved successfully!'), backgroundColor: Color(0xFF27AE60)),
                    );
                    context.go('/approvals');
                  });
                } else {
                  erp.rejectApproval(id, userName, remarks).then((_) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request rejected.'), backgroundColor: Colors.red),
                    );
                    context.go('/approvals');
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.red, foregroundColor: Colors.white),
              child: Text(act),
            )
          ],
        );
      },
    );
  }

  Color _getUrgencyColor(ApprovalUrgency urgency) {
    switch (urgency) {
      case ApprovalUrgency.low:
        return Colors.green;
      case ApprovalUrgency.medium:
        return Colors.blue;
      case ApprovalUrgency.high:
        return const Color(0xFFF39C12);
      case ApprovalUrgency.critical:
        return const Color(0xFFE74C3C);
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.grey;
      case ApprovalStatus.underReview:
        return const Color(0xFF2E86AB);
      case ApprovalStatus.approved:
        return const Color(0xFF27AE60);
      case ApprovalStatus.rejected:
        return const Color(0xFFE74C3C);
    }
  }
}
