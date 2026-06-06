import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/rfq.dart';
import '../models/quotation.dart';
import '../models/approval.dart';
import '../models/user_role.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../widgets/confirm_dialog.dart';
import '../utils/formatters.dart';

class QuotationComparisonScreen extends StatefulWidget {
  final String rfqId;

  const QuotationComparisonScreen({super.key, required this.rfqId});

  @override
  State<QuotationComparisonScreen> createState() => _QuotationComparisonScreenState();
}

class _QuotationComparisonScreenState extends State<QuotationComparisonScreen> {
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Fetch RFQ
    final rfqIdx = erpProvider.rfqs.indexWhere((r) => r.id == widget.rfqId);
    if (rfqIdx == -1) {
      return const Scaffold(body: Center(child: Text('RFQ not found.')));
    }
    final rfq = erpProvider.rfqs[rfqIdx];

    // Fetch Quotations for this RFQ
    final quotes = erpProvider.quotations.where((q) => q.rfqId == widget.rfqId).toList();

    return ResponsiveScaffold(
      title: 'Quotation Comparison',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to RFQ Detail'),
                    onPressed: () => context.go('/rfqs/${rfq.id}'),
                  ),
                  if (quotes.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export Comparison PDF'),
                      onPressed: _isGeneratingPdf ? null : () => _exportPdf(rfq, quotes),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary Info Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compare Bids: ${rfq.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comparing ${quotes.length} submitted quotations against estimated unit prices.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (quotes.isEmpty)
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No quotations have been submitted for this RFQ yet.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                )
              else
                // Side-by-side Table Container
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          verticalInside: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                        ),
                        defaultColumnWidth: const FixedColumnWidth(180),
                        columnWidths: const {
                          0: FixedColumnWidth(220), // Line Item details column is wider
                        },
                        children: [
                          // Table Header Row: Vendor Names
                          TableRow(
                            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Vendor details / Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              ...quotes.map((q) => Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Center(
                                      child: Text(
                                        q.vendorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )),
                            ],
                          ),

                          // Line Item prices (Dynamic Rows)
                          ...List.generate(rfq.lineItems.length, (itemIdx) {
                            final reqItem = rfq.lineItems[itemIdx];

                            // Find the minimum price for this item among all quotes
                            double minPrice = double.infinity;
                            for (var q in quotes) {
                              if (itemIdx < q.lineItems.length) {
                                final quotedPrice = q.lineItems[itemIdx].price;
                                if (quotedPrice < minPrice) {
                                  minPrice = quotedPrice;
                                }
                              }
                            }

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reqItem.item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(
                                        'Qty: ${reqItem.qty} ${reqItem.unit} (Target: ${Formatters.formatCurrency(reqItem.estimatedPrice)})',
                                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                ...quotes.map((q) {
                                  final double price = itemIdx < q.lineItems.length ? q.lineItems[itemIdx].price : 0.0;
                                  final isLowest = price == minPrice && minPrice != double.infinity;

                                  return Container(
                                    color: isLowest ? Colors.green.withOpacity(0.08) : null,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    alignment: Alignment.center,
                                    child: Text(
                                      Formatters.formatCurrency(price),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isLowest ? FontWeight.bold : FontWeight.normal,
                                        color: isLowest ? Colors.green[800] : null,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),

                          // Total Amount Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text('Total Amount Quote (Excl. Tax)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              ...quotes.map((q) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    alignment: Alignment.center,
                                    child: Text(
                                      Formatters.formatCurrency(q.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  )),
                            ],
                          ),

                          // Delivery Days Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text('Delivery Timeline', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              ),
                              ...quotes.map((q) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${q.deliveryDays} Days',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )),
                            ],
                          ),

                          // Score Breakdown Header
                          TableRow(
                            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2)),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Score Card Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              ...quotes.map((q) => const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(),
                                  )),
                            ],
                          ),

                          // Price Score Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Text('Price Score (50%)', style: TextStyle(fontSize: 12)),
                              ),
                              ...quotes.map((q) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    alignment: Alignment.center,
                                    child: Text('${q.priceScore.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                          ),

                          // Quality Score Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Text('Quality Score (30%)', style: TextStyle(fontSize: 12)),
                              ),
                              ...quotes.map((q) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    alignment: Alignment.center,
                                    child: Text('${q.qualityScore.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                          ),

                          // Delivery Score Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Text('Delivery Score (20%)', style: TextStyle(fontSize: 12)),
                              ),
                              ...quotes.map((q) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    alignment: Alignment.center,
                                    child: Text('${q.deliveryScore.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                          ),

                          // Weighted Overall Score Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text('Overall Weighted Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              ...quotes.map((q) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${q.overallScore.toStringAsFixed(1)} / 100',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )),
                            ],
                          ),

                          // Award Status Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text('Quotation Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              ...quotes.map((q) {
                                final color = q.status == 'Awarded'
                                    ? const Color(0xFF27AE60)
                                    : q.status == 'Rejected'
                                        ? const Color(0xFFE74C3C)
                                        : const Color(0xFFF39C12);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  alignment: Alignment.center,
                                  child: StatusChip(label: q.status, color: color),
                                );
                              }),
                            ],
                          ),

                          // Action Award Button Row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                child: Text('Award Contract', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              ...quotes.map((q) {
                                final isAwardable = q.status == 'Pending' && rfq.status == RfqStatus.published;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    onPressed: (isAwardable && (role == UserRole.admin || role == UserRole.procurementOfficer))
                                        ? () => _awardContract(context, rfq, q, user!.name)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('Award Contract', style: TextStyle(fontSize: 11)),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _awardContract(BuildContext context, Rfq rfq, Quotation qtn, String requester) {
    ConfirmDialog.show(
      context,
      title: 'Award RFQ to ${qtn.vendorName}',
      content: 'Awarding this contract will trigger an approval workflow request of amount ${Formatters.formatCurrency(qtn.totalAmount)}. Proceed?',
      confirmLabel: 'Submit for Approval',
    ).then((confirmed) {
      if (confirmed == true) {
        final erp = Provider.of<ErpProvider>(context, listen: false);

        final appId = 'APP-2026-00${erp.approvals.length + 1}';
        final newApp = Approval(
          id: appId,
          type: 'RFQ Award Approval',
          requester: requester,
          amount: qtn.totalAmount,
          urgency: ApprovalUrgency.high,
          status: ApprovalStatus.pending,
          description: 'Awarding RFQ ${rfq.id} (${rfq.title}) to ${qtn.vendorName} based on side-by-side selection.',
          targetId: rfq.id,
          chain: [
            ApprovalChainStep(userName: requester, roleLabel: 'Procurement Officer', status: ApprovalStatus.approved, date: DateTime.now().toString().split(' ')[0]),
            ApprovalChainStep(userName: 'Vikram Malhotra', roleLabel: 'Manager', status: ApprovalStatus.pending, date: null),
          ],
          comments: [
            ApprovalComment(userName: requester, text: 'Quotation selected through side-by-side matrix. Score: ${qtn.overallScore.toStringAsFixed(1)}.', timestamp: 'Just now'),
          ],
        );

        erp.submitApproval(newApp, requester).then((_) {
          // Change RFQ status to Closed while awaiting approval
          erp.updateRfqStatus(rfq.id, RfqStatus.closed, requester).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contract award submitted for approval. Approval ID: $appId'),
                backgroundColor: const Color(0xFF27AE60),
              ),
            );
            context.go('/approvals');
          });
        });
      }
    });
  }

  Future<void> _exportPdf(Rfq rfq, List<Quotation> quotes) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header block
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VendorBridge ERP System', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        pw.Text('Quotation Comparison Report', style: pw.TextStyle(fontSize: 12)),
                        pw.Text('RFQ Ref: ${rfq.id} - ${rfq.title}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text('Date: 06 Jun 2026', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 12),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        ...quotes.map((q) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(q.vendorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
                            )),
                      ],
                    ),

                    // Items rows
                    ...List.generate(rfq.lineItems.length, (idx) {
                      final item = rfq.lineItems[idx];
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${item.item}\nQty: ${item.qty} ${item.unit}', style: const pw.TextStyle(fontSize: 7)),
                          ),
                          ...quotes.map((q) {
                            final price = idx < q.lineItems.length ? q.lineItems[idx].price : 0.0;
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('INR ${price.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                            );
                          }),
                        ],
                      );
                    }),

                    // Total Row
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total Price (Excl. Tax)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        ...quotes.map((q) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('INR ${q.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7), textAlign: pw.TextAlign.center),
                            )),
                      ],
                    ),

                    // Score Row
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Overall Rating Score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        ...quotes.map((q) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('${q.overallScore.toStringAsFixed(1)} / 100', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.blue700), textAlign: pw.TextAlign.center),
                            )),
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
        name: 'Quotation_Comparison_${rfq.id}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }
}
