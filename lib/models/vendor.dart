enum VendorStatus {
  active,
  blacklisted,
  pendingVerification;

  String get label {
    switch (this) {
      case VendorStatus.active:
        return 'Active';
      case VendorStatus.blacklisted:
        return 'Blacklisted';
      case VendorStatus.pendingVerification:
        return 'Pending Verification';
    }
  }
}

class VendorPerformance {
  final double priceScore;    // 0 to 100
  final double qualityScore;  // 0 to 100
  final double deliveryScore; // 0 to 100

  VendorPerformance({
    required this.priceScore,
    required this.qualityScore,
    required this.deliveryScore,
  });

  double get overallScore => (priceScore * 0.5) + (qualityScore * 0.3) + (deliveryScore * 0.2);

  factory VendorPerformance.fromJson(Map<String, dynamic> json) {
    return VendorPerformance(
      priceScore: (json['priceScore'] as num).toDouble(),
      qualityScore: (json['qualityScore'] as num).toDouble(),
      deliveryScore: (json['deliveryScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priceScore': priceScore,
      'qualityScore': qualityScore,
      'deliveryScore': deliveryScore,
    };
  }
}

class VendorAttachment {
  final String name;
  final String uploadDate;
  final String size;

  VendorAttachment({
    required this.name,
    required this.uploadDate,
    required this.size,
  });

  factory VendorAttachment.fromJson(Map<String, dynamic> json) {
    return VendorAttachment(
      name: json['name'] as String,
      uploadDate: json['uploadDate'] as String,
      size: json['size'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uploadDate': uploadDate,
      'size': size,
    };
  }
}

class Vendor {
  final String id;
  final String name;
  final String category;
  final String gstNumber;
  final double rating; // 1 to 5 stars
  final VendorStatus status;
  final String email;
  final String phone;
  final String address;
  final VendorPerformance performance;
  final List<VendorAttachment> attachments;
  final List<String> activityLog;

  Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.gstNumber,
    required this.rating,
    required this.status,
    required this.email,
    required this.phone,
    required this.address,
    required this.performance,
    required this.attachments,
    required this.activityLog,
  });

  Vendor copyWith({
    String? id,
    String? name,
    String? category,
    String? gstNumber,
    double? rating,
    VendorStatus? status,
    String? email,
    String? phone,
    String? address,
    VendorPerformance? performance,
    List<VendorAttachment>? attachments,
    List<String>? activityLog,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      gstNumber: gstNumber ?? this.gstNumber,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      performance: performance ?? this.performance,
      attachments: attachments ?? this.attachments,
      activityLog: activityLog ?? this.activityLog,
    );
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      gstNumber: json['gstNumber'] as String? ?? 'NOT_PROVIDED',
      rating: (json['rating'] as num).toDouble(),
      status: VendorStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VendorStatus.pendingVerification,
      ),
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      performance: VendorPerformance.fromJson(json['performance'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => VendorAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      activityLog: List<String>.from(json['activityLog'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'gstNumber': gstNumber,
      'rating': rating,
      'status': status.name,
      'email': email,
      'phone': phone,
      'address': address,
      'performance': performance.toJson(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'activityLog': activityLog,
    };
  }
}
