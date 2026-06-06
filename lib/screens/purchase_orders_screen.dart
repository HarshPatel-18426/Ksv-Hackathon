import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/purchase_order.dart';
import '../models/user_role.dart';
import '../models/approval.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/gst_breakdown_table.dart';
import '../utils/formatters.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  PoStatus? _selectedStatus;
  String _selectedVendor = 'All';
  double _minAmount = 0.0;
  double _maxAmount = 5000000.0;

  @override
  Widget build(BuildContext context) {
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Filter purchase orders
    List<PurchaseOrder> pos = erpProvider.purchaseOrders;
    if (role == UserRole.vendor) {
      // Vendors only see POs assigned to them
      pos = pos.where((po) => po.vendorName.contains(user!.companyName ?? '') || po.vendorId == 'VEN-001' || po.vendorId == 'VEN-002').toList();
    }

    // Apply Filters
    if (_selectedStatus != null) {
      pos = pos.where((po) => po.status == _selectedStatus).toList();
    }
    if (_selectedVendor != 'All') {
      pos = pos.where((po) => po.vendorName == _selectedVendor).toList();
    }
    pos = pos.where((po) => po.totalAmount >= _minAmount && po.totalAmount <= _maxAmount).toList();

    // Get unique vendor names for filter dropdown
    final vendorsList = erpProvider.vendors.map((v) => v.name).toSet().toList();

    return ResponsiveScaffold(
      title: 'Purchase Orders',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Controls Panel
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Status Filter
                    DropdownButton<PoStatus?>(
                      value: _selectedStatus,
                      hint: const Text('All Statuses'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...PoStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                      ],
                      onChanged: (val) => setState(() => _selectedStatus = val),
                    ),
                    // Vendor Filter
                    DropdownButton<String>(
                      value: _selectedVendor,
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Vendors')),
                        ...vendorsList.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedVendor = val);
                      },
                    ),
                    // Amount Range filters slider simulation trigger
                    ActionChip(
                      avatar: const Icon(Icons.tune, size: 16),
                      label: Text('Amount: < ${Formatters.formatCurrency(_maxAmount)}'),
                      onPressed: () => _showAmountFilterDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PO List
            Expanded(
              child: pos.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'No Purchase Orders Found',
                      subtitle: 'Filters may be too restrictive or no orders are currently generated.',
                      ctaLabel: (role == UserRole.admin || role == UserRole.procurementOfficer) ? 'Create PO' : null,
                      onCta: (role == UserRole.admin || role == UserRole.procurementOfficer)
                          ? () => _openCreatePoForm(context)
                          : null,
                    )
                  : ListView.builder(
                      itemCount: pos.length,
                      itemBuilder: (context, idx) {
                        final po = pos[idx];
                        return _buildPoCard(context, po);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoCard(BuildContext context, PurchaseOrder po) {
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
        onTap: () => context.go('/purchase-orders/${po.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(po.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  StatusChip(label: po.status.label, color: _getPoStatusColor(po.status)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Vendor: ${po.vendorName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                'Created: ${Formatters.formatDate(po.createdAt)}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total (incl. GST):', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                  Text(
                    Formatters.formatCurrency(po.totalAmount),
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

  Color _getPoStatusColor(PoStatus status) {
    switch (status) {
      case PoStatus.draft:
        return Colors.grey;
      case PoStatus.approved:
        return const Color(0xFF2E86AB); // accent blue
      case PoStatus.sent:
        return const Color(0xFFF39C12); // warning orange
      case PoStatus.acknowledged:
        return Colors.indigo;
      case PoStatus.delivered:
        return const Color(0xFF27AE60); // success green
      case PoStatus.closed:
        return Colors.teal;
    }
  }

  void _showAmountFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        double tempMax = _maxAmount;
        return AlertDialog(
          title: const Text('Filter by Maximum Amount'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formatters.formatCurrency(tempMax), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Slider(
                    value: tempMax,
                    min: 5000.0,
                    max: 5000000.0,
                    divisions: 100,
                    onChanged: (val) {
                      setDialogState(() => tempMax = val);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => _maxAmount = tempMax);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            )
          ],
        );
      },
    );
  }

  void _openCreatePoForm(BuildContext context) {
    // Standard creation form simulation:
    // Simply prefill or open a dialog and add mock PO for ease of testing
    final erp = Provider.of<ErpProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (erp.vendors.isEmpty) return;
    final targetVendor = erp.vendors.first;

    final newPo = PurchaseOrder(
      id: 'PO-2026-00${erp.purchaseOrders.length + 1}',
      vendorId: targetVendor.id,
      vendorName: targetVendor.name,
      vendorGst: targetVendor.gstNumber,
      lineItems: [
        PoLineItem(item: 'Structural Carbon Steel Plates', qty: 25, unit: 'MT', price: 44000),
      ],
      deliveryAddress: 'Plant Gate 2 Site C, Pune, Maharashtra',
      paymentTerms: '30 Days Net',
      status: PoStatus.draft,
      createdAt: DateTime.now(),
      isIgst: false,
    );

    erp.createPo(newPo, user?.name ?? 'Procurement Officer').then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Draft Purchase Order ${newPo.id} created!'), backgroundColor: const Color(0xFF27AE60)),
      );
    });
  }
}

// --- Purchase Order Detail Screen ---
class PurchaseOrderDetailScreen extends StatefulWidget {
  final String poId;

  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Find PO
    final poIdx = erpProvider.purchaseOrders.indexWhere((p) => p.id == widget.poId);
    if (poIdx == -1) {
      return const Scaffold(body: Center(child: Text('Purchase Order not found.')));
    }
    final po = erpProvider.purchaseOrders[poIdx];

    return ResponsiveScaffold(
      title: 'PO Details - ${po.id}',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header navigation row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to POs'),
                    onPressed: () => context.go('/purchase-orders'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print / Preview PO'),
                    onPressed: _isPrinting ? null : () => _printPurchaseOrder(po),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Overview card
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
                              Text('Purchase Order', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 13)),
                              Text(po.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          StatusChip(label: po.status.label, color: _getPoStatusColor(po.status)),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.business, 'Vendor', po.vendorName),
                      _buildDetailRow(Icons.badge, 'Vendor GSTIN', po.vendorGst),
                      _buildDetailRow(Icons.location_on_outlined, 'Delivery Site', po.deliveryAddress),
                      _buildDetailRow(Icons.payment, 'Payment Terms', po.paymentTerms),
                      _buildDetailRow(Icons.calendar_today, 'Created Date', Formatters.formatDate(po.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items table
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
                      const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 16),
                      Table(
                        border: TableBorder(horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                            ],
                          ),
                          ...po.lineItems.map((item) {
                            return TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${item.qty} ${item.unit}', style: const TextStyle(fontSize: 13))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(Formatters.formatCurrency(item.price), style: const TextStyle(fontSize: 13))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(Formatters.formatCurrency(item.total), style: const TextStyle(fontSize: 13))),
                              ],
                            );
                          })
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // GST Breakdown Table Widget
              GstBreakdownTable(
                subtotal: po.subtotal,
                cgst: po.cgst,
                sgst: po.sgst,
                igst: po.igst,
                totalAmount: po.totalAmount,
              ),
              const SizedBox(height: 24),

              // Lifecycle status progression controls
              _buildLifecycleWorkflowControls(context, po, erpProvider, role, user?.name ?? 'User'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLifecycleWorkflowControls(BuildContext context, PurchaseOrder po, ErpProvider erp, UserRole role, String userName) {
    // Define active actions depending on current PO status and User Role
    final theme = Theme.of(context);

    if (po.status == PoStatus.draft && (role == UserRole.admin || role == UserRole.procurementOfficer)) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('Submit Draft PO for Approval'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: () {
            // Trigger approval chain creation
            final appId = 'APP-2026-00${erp.approvals.length + 1}';
            final app = Approval(
              id: appId,
              type: 'Purchase Order Approval',
              requester: userName,
              amount: po.totalAmount,
              urgency: ApprovalUrgency.medium,
              status: ApprovalStatus.pending,
              description: 'Approval needed for Purchase Order ${po.id} to ${po.vendorName}.',
              targetId: po.id,
              chain: [
                ApprovalChainStep(userName: userName, roleLabel: 'Procurement Officer', status: ApprovalStatus.approved, date: DateTime.now().toString().split(' ')[0]),
                ApprovalChainStep(userName: 'Vikram Malhotra', roleLabel: 'Manager', status: ApprovalStatus.pending, date: null),
              ],
              comments: [
                ApprovalComment(userName: userName, text: 'PO drafted and ready for Manager payout authorization.', timestamp: 'Just now')
              ],
            );
            erp.submitApproval(app, userName).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PO submitted for Approval. Approval ID: $appId'), backgroundColor: const Color(0xFF27AE60)),
              );
              context.go('/approvals');
            });
          },
        ),
      );
    }

    if (po.status == PoStatus.approved && (role == UserRole.admin || role == UserRole.procurementOfficer)) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.mark_email_read_outlined),
          label: const Text('Transmit/Send PO to Vendor'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: () {
            erp.updatePoStatus(po.id, PoStatus.sent, userName).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PO successfully transmitted to Vendor.'), backgroundColor: Color(0xFF27AE60)),
              );
            });
          },
        ),
      );
    }

    if (po.status == PoStatus.sent && (role == UserRole.admin || role == UserRole.vendor)) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.thumb_up_alt_outlined),
          label: const Text('Acknowledge PO Receipt'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: () {
            erp.updatePoStatus(po.id, PoStatus.acknowledged, userName).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PO receipt acknowledged by Vendor.'), backgroundColor: Color(0xFF27AE60)),
              );
            });
          },
        ),
      );
    }

    if (po.status == PoStatus.acknowledged && (role == UserRole.admin || role == UserRole.vendor || role == UserRole.procurementOfficer)) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Mark Materials as Delivered'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: () {
            erp.updatePoStatus(po.id, PoStatus.delivered, userName).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Materials marked as Delivered. Invoice auto-generated!'), backgroundColor: Color(0xFF27AE60)),
              );
            });
          },
        ),
      );
    }

    if (po.status == PoStatus.delivered && (role == UserRole.admin || role == UserRole.procurementOfficer)) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Close Purchase Order'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: () {
            erp.updatePoStatus(po.id, PoStatus.closed, userName).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchase Order closed.'), backgroundColor: Color(0xFF27AE60)),
              );
            });
          },
        ),
      );
    }

    return const SizedBox();
  }

  Color _getPoStatusColor(PoStatus status) {
    switch (status) {
      case PoStatus.draft:
        return Colors.grey;
      case PoStatus.approved:
        return const Color(0xFF2E86AB);
      case PoStatus.sent:
        return const Color(0xFFF39C12);
      case PoStatus.acknowledged:
        return Colors.indigo;
      case PoStatus.delivered:
        return const Color(0xFF27AE60);
      case PoStatus.closed:
        return Colors.teal;
    }
  }

  Future<void> _printPurchaseOrder(PurchaseOrder po) async {
    setState(() => _isPrinting = true);

    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header block / Letterhead
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VENDORBRIDGE ENTERPRISE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blue900)),
                        pw.Text('Procurement Division', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('GSTIN: 22AAAAA0000A1Z5', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text('Corporate Office, Chakan MIDC, Pune', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('PURCHASE ORDER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.grey900)),
                        pw.Text('PO Ref: ${po.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('Date: ${Formatters.formatDate(po.createdAt)}', style: pw.TextStyle(fontSize: 9)),
                        pw.Text('Status: ${po.status.label.toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 16),

                // Vendor & Delivery details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ORDER TO (VENDOR):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(po.vendorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.Text('GSTIN: ${po.vendorGst}', style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DELIVER TO / SHIP TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(po.deliveryAddress, style: pw.TextStyle(fontSize: 10)),
                          pw.Text('Payment Terms: ${po.paymentTerms}', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Line Items Table
                pw.Text('ORDERED ITEMS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total (INR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    ...po.lineItems.map((item) => pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.item, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.qty} ${item.unit}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.formatCurrency(item.price).replaceAll('₹', ''), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Formatters.formatCurrency(item.total).replaceAll('₹', ''), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Calculations
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 250,
                      child: pw.Column(
                        children: [
                          _buildPdfCalculationsRow('Subtotal:', Formatters.formatCurrency(po.subtotal)),
                          if (po.cgst > 0) _buildPdfCalculationsRow('CGST (9%):', Formatters.formatCurrency(po.cgst)),
                          if (po.sgst > 0) _buildPdfCalculationsRow('SGST (9%):', Formatters.formatCurrency(po.sgst)),
                          if (po.igst > 0) _buildPdfCalculationsRow('IGST (18%):', Formatters.formatCurrency(po.igst)),
                          pw.Divider(thickness: 1),
                          _buildPdfCalculationsRow('GRAND TOTAL (INR):', Formatters.formatCurrency(po.totalAmount), isBold: true),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 48),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.grey900),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorized Buyer Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.grey900),
                        pw.SizedBox(height: 4),
                        pw.Text('Supplier Acknowledgment', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Purchase_Order_${po.id}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print PO: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  pw.Widget _buildPdfCalculationsRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value.replaceAll('₹', 'INR '), style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
