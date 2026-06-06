class QuotationLineItem {
  final String item;
  final double qty;
  final String unit;
  final double price;

  QuotationLineItem({
    required this.item,
    required this.qty,
    required this.unit,
    required this.price,
  });

  double get total => qty * price;

  factory QuotationLineItem.fromJson(Map<String, dynamic> json) {
    return QuotationLineItem(
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

class Quotation {
  final String id;
  final String rfqId;
  final String vendorId;
  final String vendorName;
  final List<QuotationLineItem> lineItems;
  final int deliveryDays;
  final double priceScore;    // 0 to 100
  final double qualityScore;  // 0 to 100
  final double deliveryScore; // 0 to 100
  final String status;        // Pending, Awarded, Rejected

  Quotation({
    required this.id,
    required this.rfqId,
    required this.vendorId,
    required this.vendorName,
    required this.lineItems,
    required this.deliveryDays,
    required this.priceScore,
    required this.qualityScore,
    required this.deliveryScore,
    required this.status,
  });

  double get totalAmount => lineItems.fold(0, (sum, item) => sum + item.total);

  // Overall score: price 50%, quality 30%, delivery 20%
  double get overallScore => (priceScore * 0.5) + (qualityScore * 0.3) + (deliveryScore * 0.2);

  Quotation copyWith({
    String? id,
    String? rfqId,
    String? vendorId,
    String? vendorName,
    List<QuotationLineItem>? lineItems,
    int? deliveryDays,
    double? priceScore,
    double? qualityScore,
    double? deliveryScore,
    String? status,
  }) {
    return Quotation(
      id: id ?? this.id,
      rfqId: rfqId ?? this.rfqId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      lineItems: lineItems ?? this.lineItems,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      priceScore: priceScore ?? this.priceScore,
      qualityScore: qualityScore ?? this.qualityScore,
      deliveryScore: deliveryScore ?? this.deliveryScore,
      status: status ?? this.status,
    );
  }

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as String,
      rfqId: json['rfqId'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      lineItems: (json['lineItems'] as List<dynamic>)
          .map((e) => QuotationLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryDays: json['deliveryDays'] as int,
      priceScore: (json['priceScore'] as num).toDouble(),
      qualityScore: (json['qualityScore'] as num).toDouble(),
      deliveryScore: (json['deliveryScore'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rfqId': rfqId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'deliveryDays': deliveryDays,
      'priceScore': priceScore,
      'qualityScore': qualityScore,
      'deliveryScore': deliveryScore,
      'status': status,
    };
  }
}
