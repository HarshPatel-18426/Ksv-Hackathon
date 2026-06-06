enum RfqStatus {
  draft,
  published,
  closed,
  awarded;

  String get label {
    switch (this) {
      case RfqStatus.draft:
        return 'Draft';
      case RfqStatus.published:
        return 'Published';
      case RfqStatus.closed:
        return 'Closed';
      case RfqStatus.awarded:
        return 'Awarded';
    }
  }
}

class RfqLineItem {
  final String item;
  final double qty;
  final String unit;
  final double estimatedPrice;

  RfqLineItem({
    required this.item,
    required this.qty,
    required this.unit,
    required this.estimatedPrice,
  });

  double get totalEstimate => qty * estimatedPrice;

  factory RfqLineItem.fromJson(Map<String, dynamic> json) {
    return RfqLineItem(
      item: json['item'] as String,
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] as String,
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'qty': qty,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
    };
  }
}

class Rfq {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final List<String> invitedVendorIds; // List of vendor ids
  final List<RfqLineItem> lineItems;
  final RfqStatus status;
  final int submittedQuotationsCount;

  Rfq({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.invitedVendorIds,
    required this.lineItems,
    required this.status,
    required this.submittedQuotationsCount,
  });

  Rfq copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    List<String>? invitedVendorIds,
    List<RfqLineItem>? lineItems,
    RfqStatus? status,
    int? submittedQuotationsCount,
  }) {
    return Rfq(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      invitedVendorIds: invitedVendorIds ?? this.invitedVendorIds,
      lineItems: lineItems ?? this.lineItems,
      status: status ?? this.status,
      submittedQuotationsCount: submittedQuotationsCount ?? this.submittedQuotationsCount,
    );
  }

  int get daysRemaining {
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory Rfq.fromJson(Map<String, dynamic> json) {
    return Rfq(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      invitedVendorIds: List<String>.from(json['invitedVendorIds'] as List<dynamic>),
      lineItems: (json['lineItems'] as List<dynamic>)
          .map((e) => RfqLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: RfqStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RfqStatus.draft,
      ),
      submittedQuotationsCount: json['submittedQuotationsCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'invitedVendorIds': invitedVendorIds,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'status': status.name,
      'submittedQuotationsCount': submittedQuotationsCount,
    };
  }
}
