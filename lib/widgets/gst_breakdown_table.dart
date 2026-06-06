import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class GstBreakdownTable extends StatelessWidget {
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalAmount;

  const GstBreakdownTable({
    super.key,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax & Total Summary (GST)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildRow('Subtotal', Formatters.formatCurrency(subtotal), theme),
            const SizedBox(height: 8),
            if (cgst > 0) ...[
              _buildRow('CGST (9%)', Formatters.formatCurrency(cgst), theme),
              const SizedBox(height: 8),
            ],
            if (sgst > 0) ...[
              _buildRow('SGST (9%)', Formatters.formatCurrency(sgst), theme),
              const SizedBox(height: 8),
            ],
            if (igst > 0) ...[
              _buildRow('IGST (18%)', Formatters.formatCurrency(igst), theme),
              const SizedBox(height: 8),
            ],
            const Divider(height: 16),
            _buildRow(
              'Grand Total',
              Formatters.formatCurrency(totalAmount),
              theme,
              isBold: true,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            fontSize: isBold ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
            fontSize: isBold ? 16 : 13,
          ),
        ),
      ],
    );
  }
}
