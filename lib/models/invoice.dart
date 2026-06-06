enum InvoiceStatus {
  unpaid,
  partial,
  paid,
  overdue;

  String get label {
    switch (this) {
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.partial:
        return 'Partial';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }
}

class InvoiceLineItem {
  final String item;
  final double qty;
  final String unit;
  final double price;

  InvoiceLineItem({
    required this.item,
    required this.qty,
    required this.unit,
    required this.price,
  });

  double get total => qty * price;

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
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

class Invoice {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorGst;
  final String poReference;
  final List<InvoiceLineItem> lineItems;
  final DateTime dueDate;
  final InvoiceStatus status;
  final bool isIgst;

  Invoice({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorGst,
    required this.poReference,
    required this.lineItems,
    required this.dueDate,
    required this.status,
    required this.isIgst,
  });

  double get subtotal => lineItems.fold(0.0, (sum, item) => sum + item.total);

  double get cgst => isIgst ? 0.0 : subtotal * 0.09;
  double get sgst => isIgst ? 0.0 : subtotal * 0.09;
  double get igst => isIgst ? subtotal * 0.18 : 0.0;
  double get totalGst => cgst + sgst + igst;
  double get totalAmount => subtotal + totalGst;

  int get daysOverdue {
    if (status != InvoiceStatus.paid && dueDate.isBefore(DateTime.now())) {
      return DateTime.now().difference(dueDate).inDays;
    }
    return 0;
  }

  Invoice copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? vendorGst,
    String? poReference,
    List<InvoiceLineItem>? lineItems,
    DateTime? dueDate,
    InvoiceStatus? status,
    bool? isIgst,
  }) {
    return Invoice(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorGst: vendorGst ?? this.vendorGst,
      poReference: poReference ?? this.poReference,
      lineItems: lineItems ?? this.lineItems,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      isIgst: isIgst ?? this.isIgst,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.parse(val);
    if (val is DateTime) return val;
    try {
      return (val as dynamic).toDate();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      vendorGst: json['vendorGst'] as String? ?? '22AAAAA0000A1Z5',
      poReference: json['poReference'] as String,
      lineItems: json['lineItems'] != null
          ? (json['lineItems'] as List<dynamic>)
              .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      dueDate: _parseDateTime(json['dueDate']),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.unpaid,
      ),
      isIgst: json['isIgst'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorGst': vendorGst,
      'poReference': poReference,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'isIgst': isIgst,
    };
  }
}
