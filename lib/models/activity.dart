class ActivityLogEntry {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String actionDescription;
  final DateTime timestamp;
  final String module; // "Vendor", "RFQ", "PO", "Invoice", "Approval", "User"
  final Map<String, dynamic>? beforeValues;
  final Map<String, dynamic>? afterValues;

  ActivityLogEntry({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.actionDescription,
    required this.timestamp,
    required this.module,
    this.beforeValues,
    this.afterValues,
  });

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

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      actionDescription: json['actionDescription'] as String,
      timestamp: _parseDateTime(json['timestamp']),
      module: json['module'] as String,
      beforeValues: json['beforeValues'] as Map<String, dynamic>?,
      afterValues: json['afterValues'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'actionDescription': actionDescription,
      'timestamp': timestamp.toIso8601String(),
      'module': module,
      'beforeValues': beforeValues,
      'afterValues': afterValues,
    };
  }
}
