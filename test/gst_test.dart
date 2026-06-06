import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_bridge/models/purchase_order.dart';

void main() {
  group('Purchase Order GST Calculations Tests', () {
    test('Intra-state GST Calculation (CGST 9% + SGST 9%)', () {
      final po = PurchaseOrder(
        id: 'PO-TEST-001',
        vendorId: 'VEN-001',
        vendorName: 'Test Vendor',
        vendorGst: '22AAAAA0000A1Z5',
        lineItems: [
          PoLineItem(item: 'Industrial Steel Plates', qty: 10, unit: 'MT', price: 10000), // 100,000
          PoLineItem(item: 'Machine Calibration Job', qty: 1, unit: 'Job', price: 20000), // 20,000
        ],
        deliveryAddress: 'Pune Site',
        paymentTerms: '30 Days Net',
        status: PoStatus.draft,
        createdAt: DateTime.now(),
        isIgst: false, // 9% CGST + 9% SGST
      );

      // Subtotal should be 120,000
      expect(po.subtotal, 120000.0);

      // CGST should be 9% of 120,000 = 10,800
      expect(po.cgst, 10800.0);

      // SGST should be 9% of 120,000 = 10,800
      expect(po.sgst, 10800.0);

      // IGST should be 0
      expect(po.igst, 0.0);

      // Total GST should be 21,600
      expect(po.totalGst, 21600.0);

      // Total Amount should be 141,600
      expect(po.totalAmount, 141600.0);
    });

    test('Inter-state GST Calculation (IGST 18%)', () {
      final po = PurchaseOrder(
        id: 'PO-TEST-002',
        vendorId: 'VEN-002',
        vendorName: 'Test Inter Vendor',
        vendorGst: '24AAACR5678A1Z0',
        lineItems: [
          PoLineItem(item: 'Chemical Polymers', qty: 1000, unit: 'Kg', price: 150), // 150,000
        ],
        deliveryAddress: 'Mumbai Depot',
        paymentTerms: '15 Days Net',
        status: PoStatus.draft,
        createdAt: DateTime.now(),
        isIgst: true, // 18% IGST
      );

      // Subtotal should be 150,000
      expect(po.subtotal, 150000.0);

      // CGST & SGST should be 0
      expect(po.cgst, 0.0);
      expect(po.sgst, 0.0);

      // IGST should be 18% of 150,000 = 27,000
      expect(po.igst, 27000.0);

      // Total Amount should be 177,000
      expect(po.totalAmount, 177000.0);
    });
  });
}
