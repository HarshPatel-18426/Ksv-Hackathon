enum PoStatus {
  draft,
  approved,
  sent,
  acknowledged,
  delivered,
  closed;

  String get label {
    switch (this) {
      case PoStatus.draft:
        return 'Draft';
      case PoStatus.approved:
        return 'Approved';
      case PoStatus.sent:
        return 'Sent';
      case PoStatus.acknowledged:
        return 'Acknowledged';
      case PoStatus.delivered:
        return 'Delivered';
      case PoStatus.closed:
        return 'Closed';
    }
  }
}

class PoLineItem {
  final String item;
  final double qty;
  final String unit;
  final double price;

  PoLineItem({
    required this.item,
    required this.qty,
    required this.unit,
    required this.price,
  });

  double get total => qty * price;

  factory PoLineItem.fromJson(Map<String, dynamic> json) {
    return PoLineItem(
      item: json['item'] as String,
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'qty': qty,
      'unit': unit,
      'price': price,
    };
  }
}

class PurchaseOrder {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorGst;
  final List<PoLineItem> lineItems;
  final String deliveryAddress;
  final String paymentTerms;
  final PoStatus status;
  final DateTime createdAt;
  final bool isIgst; // True if IGST 18% is used, false for CGST 9% + SGST 9%

  PurchaseOrder({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorGst,
    required this.lineItems,
    required this.deliveryAddress,
    required this.paymentTerms,
    required this.status,
    required this.createdAt,
    required this.isIgst,
  });

  double get subtotal => lineItems.fold(0.0, (sum, item) => sum + item.total);

  double get cgst => isIgst ? 0.0 : subtotal * 0.09;
  double get sgst => isIgst ? 0.0 : subtotal * 0.09;
  double get igst => isIgst ? subtotal * 0.18 : 0.0;
  double get totalGst => cgst + sgst + igst;
  double get totalAmount => subtotal + totalGst;

  PurchaseOrder copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? vendorGst,
    List<PoLineItem>? lineItems,
    String? deliveryAddress,
    String? paymentTerms,
    PoStatus? status,
    DateTime? createdAt,
    bool? isIgst,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorGst: vendorGst ?? this.vendorGst,
      lineItems: lineItems ?? this.lineItems,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isIgst: isIgst ?? this.isIgst,
    );
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      vendorGst: json['vendorGst'] as String? ?? '22AAAAA0000A1Z5',
      lineItems: (json['lineItems'] as List<dynamic>)
          .map((e) => PoLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: json['deliveryAddress'] as String,
      paymentTerms: json['paymentTerms'] as String,
      status: PoStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PoStatus.draft,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isIgst: json['isIgst'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorGst': vendorGst,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      'paymentTerms': paymentTerms,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'isIgst': isIgst,
    };
  }
}
