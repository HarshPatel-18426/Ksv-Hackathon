import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/invoice.dart';
import '../models/user_role.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/gst_breakdown_table.dart';
import '../widgets/confirm_dialog.dart';
import '../utils/formatters.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Filter list based on role
    List<Invoice> invoices = erpProvider.invoices;
    if (role == UserRole.vendor) {
      invoices = invoices.where((inv) => inv.vendorName.contains(user!.companyName ?? '') || inv.vendorId == 'VEN-001' || inv.vendorId == 'VEN-002').toList();
    }

    // Apply Search
    if (_searchQuery.isNotEmpty) {
      invoices = invoices.where((inv) {
        return inv.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            inv.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            inv.poReference.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    final unpaid = invoices.where((i) => i.status == InvoiceStatus.unpaid).toList();
    final partial = invoices.where((i) => i.status == InvoiceStatus.partial).toList();
    final paid = invoices.where((i) => i.status == InvoiceStatus.paid).toList();
    final overdue = invoices.where((i) => i.status == InvoiceStatus.overdue || (i.status != InvoiceStatus.paid && i.dueDate.isBefore(DateTime.now()))).toList();

    return ResponsiveScaffold(
      title: 'Invoice Management',
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Invoice ID, Vendor, PO reference...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Unpaid (${unpaid.length})'),
              Tab(text: 'Partial (${partial.length})'),
              Tab(text: 'Paid (${paid.length})'),
              Tab(text: 'Overdue (${overdue.length})'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoiceList(context, unpaid),
                _buildInvoiceList(context, partial),
                _buildInvoiceList(context, paid),
                _buildInvoiceList(context, overdue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, List<Invoice> list) {
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Invoices Found',
        subtitle: 'No records exist in this payment category.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final inv = list[idx];
        return _buildInvoiceCard(context, inv);
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice inv) {
    final theme = Theme.of(context);
    final isOverdue = inv.status == InvoiceStatus.overdue || (inv.status != InvoiceStatus.paid && inv.dueDate.isBefore(DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/invoices/${inv.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(inv.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Row(
                    children: [
                      if (isOverdue) ...[
                        StatusChip(label: 'Overdue', color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                      ],
                      StatusChip(label: inv.status.label, color: _getStatusColor(inv.status)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Vendor: ${inv.vendorName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('PO Ref: ${inv.poReference}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                  const Spacer(),
                  Text('Due Date: ${Formatters.formatDate(inv.dueDate)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Invoice Amount (incl. Tax):', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                  Text(
                    Formatters.formatCurrency(inv.totalAmount),
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

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.unpaid:
        return const Color(0xFFF39C12); // warning orange
      case InvoiceStatus.partial:
        return Colors.blue;
      case InvoiceStatus.paid:
        return const Color(0xFF27AE60); // success green
      case InvoiceStatus.overdue:
        return const Color(0xFFE74C3C); // red error
    }
  }
}

// --- Invoice Detail Screen ---
class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Find Invoice
    final invIdx = erpProvider.invoices.indexWhere((i) => i.id == widget.invoiceId);
    if (invIdx == -1) {
      return const Scaffold(body: Center(child: Text('Invoice not found.')));
    }
    final inv = erpProvider.invoices[invIdx];
    final isOverdue = inv.status == InvoiceStatus.overdue || (inv.status != InvoiceStatus.paid && inv.dueDate.isBefore(DateTime.now()));

    return ResponsiveScaffold(
      title: 'Invoice Details - ${inv.id}',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button & Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Invoices'),
                    onPressed: () => context.go('/invoices'),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.email_outlined),
                        tooltip: 'Email Vendor Inquiry',
                        onPressed: () => _showEmailInquiryDialog(context, inv),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Generate PDF Invoice'),
                        onPressed: _isPrinting ? null : () => _printInvoice(inv),
                      ),
                    ],
                  )
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
                              Text('Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 13)),
                              Text(inv.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Row(
                            children: [
                              if (isOverdue) ...[
                                StatusChip(label: '${inv.daysOverdue} Days Overdue', color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                              ],
                              StatusChip(label: inv.status.label, color: _getStatusColor(inv.status)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.business, 'Supplier', inv.vendorName),
                      _buildDetailRow(Icons.description, 'Supplier GSTIN', inv.vendorGst),
                      _buildDetailRow(Icons.shopping_bag_outlined, 'PO Reference', inv.poReference),
                      _buildDetailRow(Icons.calendar_today, 'Due Date', Formatters.formatDate(inv.dueDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items Table
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
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Item Description', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline, fontSize: 12))),
                            ],
                          ),
                          ...inv.lineItems.map((item) {
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

              // Gst Breakdown
              GstBreakdownTable(
                subtotal: inv.subtotal,
                cgst: inv.cgst,
                sgst: inv.sgst,
                igst: inv.igst,
                totalAmount: inv.totalAmount,
              ),
              const SizedBox(height: 24),

              // Record Payment (Admin/Manager only)
              if (inv.status != InvoiceStatus.paid && (role == UserRole.admin || role == UserRole.manager))
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment_outlined),
                    label: const Text('Record Payout / Process Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () {
                      ConfirmDialog.show(
                        context,
                        title: 'Confirm Payment Settlement',
                        content: 'Are you sure you want to mark this invoice ${inv.id} as PAID? This will transfer funds to ${inv.vendorName}.',
                        confirmLabel: 'Confirm Payout',
                      ).then((confirmed) {
                        if (confirmed == true) {
                          erpProvider.updateInvoiceStatus(inv.id, InvoiceStatus.paid, user?.name ?? 'Manager').then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment processed successfully!'), backgroundColor: Color(0xFF27AE60)),
                            );
                          });
                        }
                      });
                    },
                  ),
                ),
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

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.unpaid:
        return const Color(0xFFF39C12);
      case InvoiceStatus.partial:
        return Colors.blue;
      case InvoiceStatus.paid:
        return const Color(0xFF27AE60);
      case InvoiceStatus.overdue:
        return const Color(0xFFE74C3C);
    }
  }

  void _showEmailInquiryDialog(BuildContext context, Invoice inv) {
    final theme = Theme.of(context);
    final email = '${inv.vendorName.toLowerCase().replaceAll(' ', '')}@vendorbridge.in';
    final subject = 'VendorBridge: Payment Inquiry for Invoice ${inv.id}';
    final body = 'Dear Account Team,\n\nWe are writing regarding Tax Invoice ${inv.id} linked to PO Reference ${inv.poReference} for the amount of ${Formatters.formatCurrency(inv.totalAmount)}.\n\nPlease update us on the disbursement status.\n\nBest Regards,\nProcurement Team\nVendorBridge';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Email Invoice Inquiry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient: $email', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text('Subject: $subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Divider(height: 20),
              Container(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                padding: const EdgeInsets.all(12),
                child: Text(body, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton.icon(
              icon: const Icon(Icons.mail_outline),
              label: const Text('Send via Mailto Client'),
              onPressed: () {
                final mailtoUri = Uri(
                  scheme: 'mailto',
                  path: email,
                  queryParameters: {
                    'subject': subject,
                    'body': body,
                  },
                );
                // Attempt to open the link - this generates the system trigger
                if (kIsWeb) {
                  // We would open a new tab or trigger a link
                  // Since url_launcher isn't present, print for the user or log
                  debugPrint('Opening mail client: $mailtoUri');
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mailto link compiled! Recipient: $email')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _printInvoice(Invoice inv) async {
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
                        pw.Text('TAX INVOICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.green900)),
                        pw.Text('Supplier Billing Document', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('Ref: ${inv.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(inv.vendorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text('GSTIN: ${inv.vendorGst}', style: pw.TextStyle(fontSize: 9)),
                        pw.Text('Date: ${Formatters.formatDate(DateTime.now())}', style: pw.TextStyle(fontSize: 9)),
                        pw.Text('Due Date: ${Formatters.formatDate(inv.dueDate)}', style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5, color: PdfColors.green900),
                pw.SizedBox(height: 16),

                // PO reference details
                pw.Text('PO Reference: ${inv.poReference}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 16),

                // Table
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
                    ...inv.lineItems.map((item) => pw.TableRow(
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
                          _buildPdfCalculationsRow('Subtotal:', Formatters.formatCurrency(inv.subtotal)),
                          if (inv.cgst > 0) _buildPdfCalculationsRow('CGST (9%):', Formatters.formatCurrency(inv.cgst)),
                          if (inv.sgst > 0) _buildPdfCalculationsRow('SGST (9%):', Formatters.formatCurrency(inv.sgst)),
                          if (inv.igst > 0) _buildPdfCalculationsRow('IGST (18%):', Formatters.formatCurrency(inv.igst)),
                          pw.Divider(thickness: 1),
                          _buildPdfCalculationsRow('GRAND TOTAL (INR):', Formatters.formatCurrency(inv.totalAmount), isBold: true),
                        ],
                      ),
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
        name: 'Invoice_${inv.id}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print Invoice: $e'), backgroundColor: Colors.red),
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
