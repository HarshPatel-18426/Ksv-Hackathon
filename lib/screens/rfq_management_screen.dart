import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/rfq.dart';
import '../models/quotation.dart';
import '../models/user_role.dart';
import '../models/vendor.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../utils/formatters.dart';

class RfqManagementScreen extends StatefulWidget {
  const RfqManagementScreen({super.key});

  @override
  State<RfqManagementScreen> createState() => _RfqManagementScreenState();
}

class _RfqManagementScreenState extends State<RfqManagementScreen> {
  RfqStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Filter based on role
    List<Rfq> rfqs = erpProvider.rfqs;
    if (role == UserRole.vendor) {
      // Vendors only see RFQs they are invited to
      rfqs = rfqs.where((r) => r.invitedVendorIds.contains(user!.id)).toList();
    }

    // Filter based on status selection
    if (_selectedStatus != null) {
      rfqs = rfqs.where((r) => r.status == _selectedStatus).toList();
    }

    return ResponsiveScaffold(
      title: 'RFQ Management',
      floatingActionButton: (role == UserRole.admin || role == UserRole.procurementOfficer)
          ? FloatingActionButton(
              onPressed: () => _openCreateRfqForm(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All RFQs'),
                    selected: _selectedStatus == null,
                    onSelected: (val) => setState(() => _selectedStatus = null),
                  ),
                  const SizedBox(width: 8),
                  ...RfqStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(status.label),
                        selected: _selectedStatus == status,
                        onSelected: (val) => setState(() => _selectedStatus = val ? status : null),
                      ),
                    );
                  })
                ],
              ),
            ),
            const SizedBox(height: 16),

            // RFQ List
            Expanded(
              child: rfqs.isEmpty
                  ? EmptyState(
                      icon: Icons.request_quote_outlined,
                      title: 'No RFQs Found',
                      subtitle: 'Create a Request for Quotation to start receiving vendor bids.',
                      ctaLabel: (role == UserRole.admin || role == UserRole.procurementOfficer) ? 'New RFQ' : null,
                      onCta: (role == UserRole.admin || role == UserRole.procurementOfficer)
                          ? () => _openCreateRfqForm(context)
                          : null,
                    )
                  : ListView.builder(
                      itemCount: rfqs.length,
                      itemBuilder: (context, idx) {
                        final rfq = rfqs[idx];
                        return _buildRfqCard(context, rfq, role);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRfqCard(BuildContext context, Rfq rfq, UserRole role) {
    final theme = Theme.of(context);
    final daysLeft = rfq.daysRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/rfqs/${rfq.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      rfq.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(label: rfq.status.label, color: _getRfqStatusColor(rfq.status)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rfq.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${Formatters.formatDate(rfq.deadline)}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.gavel_outlined, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${rfq.submittedQuotationsCount} Quotes',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (rfq.status == RfqStatus.published) ...[
                    Icon(Icons.timer_outlined, size: 14, color: daysLeft <= 2 ? Colors.red : Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      daysLeft == 0 ? 'Closed' : '$daysLeft days left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: daysLeft <= 2 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRfqStatusColor(RfqStatus status) {
    switch (status) {
      case RfqStatus.draft:
        return Colors.grey;
      case RfqStatus.published:
        return const Color(0xFF2E86AB); // accent blue
      case RfqStatus.closed:
        return const Color(0xFFF39C12); // warning yellow
      case RfqStatus.awarded:
        return const Color(0xFF27AE60); // success green
    }
  }

  void _openCreateRfqForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    final List<String> selectedVendors = [];
    final List<RfqLineItem> items = [];

    // Temporary values for adding items
    final itemController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController(text: 'MT');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final erp = Provider.of<ErpProvider>(context, listen: false);

        return StatefulBuilder(
          builder: (context, setFormState) {
            return AlertDialog(
              title: const Text('Create RFQ'),
              constraints: const BoxConstraints(maxWidth: 600),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'RFQ Title'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 16),

                      // Deadline Date Picker
                      Row(
                        children: [
                          const Text('Deadline: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(Formatters.formatDate(deadline)),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Select Date'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: deadline,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 180)),
                              );
                              if (picked != null) {
                                setFormState(() => deadline = picked);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),

                      // Vendor Invitation Multi-select
                      const Text('Invite Vendors', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (erp.vendors.isEmpty)
                        const Text('No vendors found. Please add vendors first.', style: TextStyle(color: Colors.red, fontSize: 12))
                      else
                        Wrap(
                          spacing: 8,
                          children: erp.vendors.map((v) {
                            final isSelected = selectedVendors.contains(v.id);
                            return FilterChip(
                              label: Text(v.name, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              onSelected: (val) {
                                setFormState(() {
                                  if (val) {
                                    selectedVendors.add(v.id);
                                  } else {
                                    selectedVendors.remove(v.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const Divider(),

                      // Add Line Items Table
                      const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (items.isNotEmpty)
                        Table(
                          border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                          children: [
                            const TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(4), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(4), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(4), child: Text('Est. Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(4), child: Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              ],
                            ),
                            ...items.map((it) {
                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(4), child: Text(it.item, style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(4), child: Text('${it.qty} ${it.unit}', style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(4), child: Text(Formatters.formatCurrency(it.estimatedPrice), style: const TextStyle(fontSize: 11))),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                    onPressed: () {
                                      setFormState(() => items.remove(it));
                                    },
                                  )
                                ],
                              );
                            })
                          ],
                        ),

                      const SizedBox(height: 12),
                      // Inline Item Adder
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: itemController,
                              decoration: const InputDecoration(labelText: 'Item Name', labelStyle: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qty', labelStyle: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Est. Price', labelStyle: TextStyle(fontSize: 12)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () {
                              final name = itemController.text.trim();
                              final qty = double.tryParse(qtyController.text) ?? 0.0;
                              final price = double.tryParse(priceController.text) ?? 0.0;
                              if (name.isNotEmpty && qty > 0 && price > 0) {
                                setFormState(() {
                                  items.add(RfqLineItem(item: name, qty: qty, unit: unitController.text, estimatedPrice: price));
                                  itemController.clear();
                                  qtyController.clear();
                                  priceController.clear();
                                });
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() && items.isNotEmpty && selectedVendors.isNotEmpty) {
                      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                      final rfqId = 'RFQ-${DateTime.now().millisecondsSinceEpoch % 1000000}';
                      final r = Rfq(
                        id: rfqId,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        deadline: deadline,
                        invitedVendorIds: selectedVendors,
                        lineItems: items,
                        status: RfqStatus.published, // Instantly publish for ease of testing
                        submittedQuotationsCount: 0,
                      );

                      erp.createRfq(r, user?.name ?? 'Procurement Officer').then((_) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('RFQ published successfully!'), backgroundColor: Color(0xFF27AE60)),
                        );
                      });
                    }
                  },
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- RFQ Detail Screen Class ---
class RfqDetailScreen extends StatelessWidget {
  final String rfqId;

  const RfqDetailScreen({super.key, required this.rfqId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Find RFQ
    final rfqIdx = erpProvider.rfqs.indexWhere((r) => r.id == rfqId);
    if (rfqIdx == -1) {
      return const Scaffold(body: Center(child: Text('RFQ not found.')));
    }
    final rfq = erpProvider.rfqs[rfqIdx];
    final daysLeft = rfq.daysRemaining;

    // Timeline stepper index
    int currentStep = 0;
    if (rfq.status == RfqStatus.published) currentStep = 1;
    if (rfq.status == RfqStatus.closed) currentStep = 2;
    if (rfq.status == RfqStatus.awarded) currentStep = 3;

    // Check if current vendor user has already submitted a quotation
    final bool hasVendorSubmitted = erpProvider.quotations.any((q) => q.rfqId == rfqId && q.vendorId == user?.id);

    return ResponsiveScaffold(
      title: 'RFQ Detail - ${rfq.id}',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Row
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to RFQs'),
                onPressed: () => context.go('/rfqs'),
              ),
              const SizedBox(height: 12),

              // Overview Section Card
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
                          Expanded(
                            child: Text(
                              rfq.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          StatusChip(label: rfq.status.label, color: _getRfqStatusColor(rfq.status)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(rfq.description, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Text('Deadline: ${Formatters.formatDate(rfq.deadline)}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 24),
                          Icon(Icons.gavel_outlined, size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Text('${rfq.submittedQuotationsCount} bids received', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      if (rfq.status == RfqStatus.published) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: daysLeft <= 2 ? Colors.red : Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              daysLeft == 0 ? 'Deadline has passed' : '$daysLeft days remaining to submit quotes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: daysLeft <= 2 ? Colors.red : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lifecycle Timeline Stepper
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
                      const Text('RFQ Lifecycle Stepper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStepItem('Draft', currentStep >= 0, theme),
                          _buildStepDivider(currentStep >= 1, theme),
                          _buildStepItem('Published', currentStep >= 1, theme),
                          _buildStepDivider(currentStep >= 2, theme),
                          _buildStepItem('Closed', currentStep >= 2, theme),
                          _buildStepDivider(currentStep >= 3, theme),
                          _buildStepItem('Awarded', currentStep >= 3, theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Line Items
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
                      const Text('Requested Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 16),
                      Table(
                        border: TableBorder(horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Item Description', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Est. Price (Unit)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                            ],
                          ),
                          ...rfq.lineItems.map((item) {
                            return TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${item.qty}', style: const TextStyle(fontSize: 13))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.unit, style: const TextStyle(fontSize: 13))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(Formatters.formatCurrency(item.estimatedPrice), style: const TextStyle(fontSize: 13))),
                              ],
                            );
                          })
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons based on Role
              if (role == UserRole.vendor) ...[
                if (rfq.status != RfqStatus.published)
                  const Center(child: Text('This RFQ is not accepting quotations at this time.', style: TextStyle(fontStyle: FontStyle.italic)))
                else if (hasVendorSubmitted)
                  const Center(child: Card(color: Colors.greenAccent, child: Padding(padding: EdgeInsets.all(12), child: Text('✓ Proposal Submitted successfully. Awaiting buyer review.', style: TextStyle(fontWeight: FontWeight.bold)))))
                else
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Submit Quotation Proposal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () => _openSubmitQuoteModal(context, rfq, user!),
                    ),
                  ),
              ] else ...[
                // Procurement Officer / Manager Action
                if (rfq.status == RfqStatus.published || rfq.status == RfqStatus.closed || rfq.status == RfqStatus.awarded)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Compare Submitted Quotations'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () => context.go('/quotation-comparison/${rfq.id}'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String title, bool isCompleted, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isCompleted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          child: Icon(
            isCompleted ? Icons.check : Icons.circle_outlined,
            size: 14,
            color: isCompleted ? theme.colorScheme.onPrimary : theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepDivider(bool isCompleted, ThemeData theme) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        margin: const EdgeInsets.only(bottom: 18),
      ),
    );
  }

  Color _getRfqStatusColor(RfqStatus status) {
    switch (status) {
      case RfqStatus.draft:
        return Colors.grey;
      case RfqStatus.published:
        return const Color(0xFF2E86AB);
      case RfqStatus.closed:
        return const Color(0xFFF39C12);
      case RfqStatus.awarded:
        return const Color(0xFF27AE60);
    }
  }

  void _openSubmitQuoteModal(BuildContext context, Rfq rfq, UserProfile vendorUser) {
    final formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> priceControllers = {};
    for (var item in rfq.lineItems) {
      priceControllers[item.item] = TextEditingController();
    }
    final deliveryController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Submit Quotation Proposal'),
          constraints: const BoxConstraints(maxWidth: 500),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submit pricing for RFQ: ${rfq.title}'),
                  const Divider(height: 24),
                  ...rfq.lineItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.item} (${item.qty} ${item.unit}):')),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: priceControllers[item.item],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Unit Price (₹)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (double.tryParse(val) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  TextFormField(
                    controller: deliveryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Time (Days)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter delivery days';
                      if (int.tryParse(val) == null) return 'Invalid days';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final erp = Provider.of<ErpProvider>(context, listen: false);

                  // Map to Quotation Line Items
                  final qItems = rfq.lineItems.map((item) {
                    final price = double.parse(priceControllers[item.item]!.text);
                    return QuotationLineItem(
                      item: item.item,
                      qty: item.qty,
                      unit: item.unit,
                      price: price,
                    );
                  }).toList();

                  final qId = 'QTN-2026-00${erp.quotations.length + 1}';
                  final q = Quotation(
                    id: qId,
                    rfqId: rfq.id,
                    vendorId: vendorUser.id,
                    vendorName: vendorUser.companyName ?? vendorUser.name,
                    lineItems: qItems,
                    deliveryDays: int.parse(deliveryController.text),
                    priceScore: 90, // mock scores
                    qualityScore: 95,
                    deliveryScore: 88,
                    status: 'Pending',
                  );

                  erp.submitQuotation(q, vendorUser.name).then((_) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quotation submitted successfully!'), backgroundColor: Color(0xFF27AE60)),
                    );
                  });
                }
              },
              child: const Text('Submit Proposal'),
            ),
          ],
        );
      },
    );
  }
}
