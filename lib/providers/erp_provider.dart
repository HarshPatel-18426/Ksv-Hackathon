import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';
import '../models/rfq.dart';
import '../models/quotation.dart';
import '../models/approval.dart';
import '../models/purchase_order.dart';
import '../models/invoice.dart';
import '../models/activity.dart';
import '../models/user_role.dart';

class ErpProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Vendor> _vendors = [];
  List<Rfq> _rfqs = [];
  List<Quotation> _quotations = [];
  List<Approval> _approvals = [];
  List<PurchaseOrder> _purchaseOrders = [];
  List<Invoice> _invoices = [];
  List<ActivityLogEntry> _activities = [];

  List<Vendor> get vendors => List.unmodifiable(_vendors);
  List<Rfq> get rfqs => List.unmodifiable(_rfqs);
  List<Quotation> get quotations => List.unmodifiable(_quotations);
  List<Approval> get approvals => List.unmodifiable(_approvals);
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  List<ActivityLogEntry> get activities => List.unmodifiable(_activities);

  ErpProvider();

  Future<void> loadAllData(UserProfile? user) async {
    if (user == null) return;
    _isLoading = true;
    notifyListeners();

    // 1. Fetch Vendors
    try {
      final vendorSnap = await _db.collection('vendors').get();
      _vendors = vendorSnap.docs
          .map((doc) {
            try {
              return Vendor.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing Vendor document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Vendor>()
          .toList();
    } catch (e) {
      debugPrint("Error loading Vendors: $e");
    }

    // 2. Fetch RFQs
    try {
      final rfqSnap = await _db.collection('rfqs').get();
      final allRfqs = rfqSnap.docs
          .map((doc) {
            try {
              return Rfq.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing RFQ document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Rfq>()
          .toList();
      if (user.role == UserRole.vendor) {
        _rfqs = allRfqs.where((r) => r.invitedVendorIds.contains(user.id) || r.invitedVendorIds.contains('VEN-001') || r.invitedVendorIds.contains('VEN-002')).toList();
      } else {
        _rfqs = allRfqs;
      }
    } catch (e) {
      debugPrint("Error loading RFQs: $e");
    }

    // 3. Fetch Quotations
    try {
      final qtnSnap = await _db.collection('quotations').get();
      final allQtns = qtnSnap.docs
          .map((doc) {
            try {
              return Quotation.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing Quotation document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Quotation>()
          .toList();
      if (user.role == UserRole.vendor) {
        _quotations = allQtns.where((q) => q.vendorId == user.id || q.vendorId == 'VEN-001' || q.vendorId == 'VEN-002').toList();
      } else {
        _quotations = allQtns;
      }
    } catch (e) {
      debugPrint("Error loading Quotations: $e");
    }

    // 4. Fetch Approvals
    try {
      final appSnap = await _db.collection('approvals').get();
      _approvals = appSnap.docs
          .map((doc) {
            try {
              return Approval.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing Approval document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Approval>()
          .toList();
    } catch (e) {
      debugPrint("Error loading Approvals: $e");
    }

    // 5. Fetch POs
    try {
      final poSnap = await _db.collection('purchase_orders').get();
      final allPos = poSnap.docs
          .map((doc) {
            try {
              return PurchaseOrder.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing PurchaseOrder document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<PurchaseOrder>()
          .toList();
      if (user.role == UserRole.vendor) {
        _purchaseOrders = allPos.where((po) => po.vendorId == user.id || po.vendorId == 'VEN-001' || po.vendorId == 'VEN-002' || (user.companyName != null && po.vendorName.toLowerCase().contains(user.companyName!.toLowerCase()))).toList();
      } else {
        _purchaseOrders = allPos;
      }
    } catch (e) {
      debugPrint("Error loading POs: $e");
    }

    // 6. Fetch Invoices
    try {
      final invSnap = await _db.collection('invoices').get();
      final allInvoices = invSnap.docs
          .map((doc) {
            try {
              return Invoice.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing Invoice document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Invoice>()
          .toList();
      if (user.role == UserRole.vendor) {
        _invoices = allInvoices.where((inv) => inv.vendorId == user.id || inv.vendorId == 'VEN-001' || inv.vendorId == 'VEN-002' || (user.companyName != null && inv.vendorName.toLowerCase().contains(user.companyName!.toLowerCase()))).toList();
      } else {
        _invoices = allInvoices;
      }
    } catch (e) {
      debugPrint("Error loading Invoices: $e");
    }

    // 7. Fetch Activities
    try {
      final actSnap = await _db.collection('activities').orderBy('timestamp', descending: true).limit(50).get();
      _activities = actSnap.docs
          .map((doc) {
            try {
              return ActivityLogEntry.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id});
            } catch (e) {
              debugPrint("Error parsing Activity document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<ActivityLogEntry>()
          .toList();
    } catch (e) {
      debugPrint("Error loading Activities: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- CRUD Operations ---

  Future<void> addVendor(Vendor vendor, String actionBy, {String? password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendorJson = vendor.toJson();
      if (password != null) {
        vendorJson['password'] = password;
      }
      await _db.collection('vendors').doc(vendor.id).set(vendorJson);
      _vendors.add(vendor);
      await _logAction(actionBy, 'Added new vendor: ${vendor.name}', 'Vendor', afterValues: vendorJson);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVendor(Vendor vendor, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      final old = _vendors.firstWhere((v) => v.id == vendor.id);
      await _db.collection('vendors').doc(vendor.id).update(vendor.toJson());
      final idx = _vendors.indexWhere((v) => v.id == vendor.id);
      if (idx != -1) _vendors[idx] = vendor;
      await _logAction(actionBy, 'Updated vendor: ${vendor.name}', 'Vendor', beforeValues: old.toJson(), afterValues: vendor.toJson());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBlacklistVendor(String id, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendor = _vendors.firstWhere((v) => v.id == id);
      final newStatus = vendor.status == VendorStatus.blacklisted ? VendorStatus.active : VendorStatus.blacklisted;
      await _db.collection('vendors').doc(id).update({'status': newStatus.name});
      
      final updated = vendor.copyWith(status: newStatus);
      final idx = _vendors.indexWhere((v) => v.id == id);
      if (idx != -1) _vendors[idx] = updated;

      await _logAction(actionBy, 'Changed status of ${vendor.name} to ${newStatus.label}', 'Vendor');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRfq(Rfq rfq, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('rfqs').doc(rfq.id).set(rfq.toJson());
      _rfqs.add(rfq);
      await _logAction(actionBy, 'Created RFQ: ${rfq.title}', 'RFQ', afterValues: rfq.toJson());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRfqStatus(String id, RfqStatus status, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('rfqs').doc(id).update({'status': status.name});
      final idx = _rfqs.indexWhere((r) => r.id == id);
      if (idx != -1) _rfqs[idx] = _rfqs[idx].copyWith(status: status);
      await _logAction(actionBy, 'Updated RFQ $id status to ${status.label}', 'RFQ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitQuotation(Quotation qtn, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('quotations').doc(qtn.id).set(qtn.toJson());
      _quotations.add(qtn);
      await _db.collection('rfqs').doc(qtn.rfqId).update({'submittedQuotationsCount': FieldValue.increment(1)});
      
      final rfqIdx = _rfqs.indexWhere((r) => r.id == qtn.rfqId);
      if (rfqIdx != -1) {
        _rfqs[rfqIdx] = _rfqs[rfqIdx].copyWith(submittedQuotationsCount: _rfqs[rfqIdx].submittedQuotationsCount + 1);
      }

      await _logAction(actionBy, 'Submitted quotation for RFQ ${qtn.rfqId}', 'RFQ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitApproval(Approval app, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('approvals').doc(app.id).set(app.toJson());
      _approvals.add(app);
      await _logAction(actionBy, 'Submitted ${app.type} for approval', 'Approval');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveApproval(String id, String actionBy, String comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      final appIdx = _approvals.indexWhere((a) => a.id == id);
      if (appIdx == -1) return;
      final approval = _approvals[appIdx];

      await _db.collection('approvals').doc(id).update({'status': ApprovalStatus.approved.name});
      _approvals[appIdx] = approval.copyWith(status: ApprovalStatus.approved);

      // Automated Workflows based on Approval Type
      if (approval.type == 'RFQ Award Approval') {
        final rfqId = approval.targetId;
        
        // 1. Award RFQ
        await _db.collection('rfqs').doc(rfqId).update({'status': RfqStatus.awarded.name});
        final rIdx = _rfqs.indexWhere((r) => r.id == rfqId);
        if (rIdx != -1) _rfqs[rIdx] = _rfqs[rIdx].copyWith(status: RfqStatus.awarded);

        // 2. Award Winning Quotation (and reject others)
        final winningQtn = _quotations.firstWhere((q) => q.rfqId == rfqId && q.status == 'Pending', orElse: () => _quotations.firstWhere((q) => q.rfqId == rfqId));
        
        await _db.collection('quotations').where('rfqId', isEqualTo: rfqId).get().then((snap) {
          for (var doc in snap.docs) {
            final status = doc.id == winningQtn.id ? 'Awarded' : 'Rejected';
            doc.reference.update({'status': status});
          }
        });

        // 3. Create PO automatically
        final poId = 'PO-${DateTime.now().millisecondsSinceEpoch % 100000}';
        final vendor = _vendors.firstWhere((v) => v.id == winningQtn.vendorId);
        final newPo = PurchaseOrder(
          id: poId,
          vendorId: winningQtn.vendorId,
          vendorName: winningQtn.vendorName,
          vendorGst: vendor.gstNumber,
          lineItems: winningQtn.lineItems.map((qi) => PoLineItem(item: qi.item, qty: qi.qty, unit: qi.unit, price: qi.price)).toList(),
          deliveryAddress: 'Main Plant, Sector 4, Jamshedpur',
          paymentTerms: '45 Days Net',
          status: PoStatus.approved,
          createdAt: DateTime.now(),
          isIgst: false,
        );
        await createPo(newPo, 'System');
      } 
      else if (approval.type == 'Purchase Order Approval') {
        await updatePoStatus(approval.targetId, PoStatus.approved, 'System');
      }

      await _logAction(actionBy, 'Approved request: $id', 'Approval');
    } catch (e) {
      debugPrint("Error approving: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectApproval(String id, String actionBy, String comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('approvals').doc(id).update({'status': ApprovalStatus.rejected.name});
      final idx = _approvals.indexWhere((a) => a.id == id);
      if (idx != -1) _approvals[idx] = _approvals[idx].copyWith(status: ApprovalStatus.rejected);
      await _logAction(actionBy, 'Rejected request: $id', 'Approval');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addApprovalComment(String id, String userName, String comment) async {
    try {
      final newComment = {'userName': userName, 'text': comment, 'timestamp': 'Just now'};
      await _db.collection('approvals').doc(id).update({'comments': FieldValue.arrayUnion([newComment])});
      final idx = _approvals.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final comments = List<ApprovalComment>.from(_approvals[idx].comments)..add(ApprovalComment(userName: userName, text: comment, timestamp: 'Just now'));
        _approvals[idx] = _approvals[idx].copyWith(comments: comments);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error adding comment: $e");
    }
  }

  Future<void> createPo(PurchaseOrder po, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('purchase_orders').doc(po.id).set(po.toJson());
      _purchaseOrders.add(po);
      await _logAction(actionBy, 'Created PO: ${po.id}', 'PO');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePoStatus(String id, PoStatus status, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('purchase_orders').doc(id).update({'status': status.name});
      final idx = _purchaseOrders.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final oldPo = _purchaseOrders[idx];
        _purchaseOrders[idx] = oldPo.copyWith(status: status);

        // Auto-create Invoice if PO is delivered
        if (status == PoStatus.delivered) {
          final invId = 'INV-${DateTime.now().millisecondsSinceEpoch % 100000}';
          final newInv = Invoice(
            id: invId,
            vendorId: oldPo.vendorId,
            vendorName: oldPo.vendorName,
            vendorGst: oldPo.vendorGst,
            poReference: oldPo.id,
            lineItems: oldPo.lineItems.map((pi) => InvoiceLineItem(item: pi.item, qty: pi.qty, unit: pi.unit, price: pi.price)).toList(),
            dueDate: DateTime.now().add(const Duration(days: 30)),
            status: InvoiceStatus.unpaid,
            isIgst: oldPo.isIgst,
          );
          await _db.collection('invoices').doc(invId).set(newInv.toJson());
          _invoices.add(newInv);
          await _logAction('System', 'Auto-generated Invoice $invId for delivered PO ${oldPo.id}', 'Invoice');
        }
      }
      await _logAction(actionBy, 'Updated PO $id status to ${status.label}', 'PO');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInvoiceStatus(String id, InvoiceStatus status, String actionBy) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('invoices').doc(id).update({'status': status.name});
      final idx = _invoices.indexWhere((i) => i.id == id);
      if (idx != -1) _invoices[idx] = _invoices[idx].copyWith(status: status);
      await _logAction(actionBy, 'Updated Invoice $id status to ${status.label}', 'Invoice');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Internal Logger ---
  Future<void> _logAction(String userName, String desc, String module, {Map<String, dynamic>? beforeValues, Map<String, dynamic>? afterValues}) async {
    final entry = ActivityLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userName,
      userName: userName,
      actionDescription: desc,
      timestamp: DateTime.now(),
      module: module,
      beforeValues: beforeValues,
      afterValues: afterValues,
    );
    await _db.collection('activities').add(entry.toJson());
    _activities.insert(0, entry);
  }
}
