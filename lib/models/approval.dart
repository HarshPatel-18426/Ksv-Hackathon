enum ApprovalStatus {
  pending,
  underReview,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.underReview:
        return 'Under Review';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

enum ApprovalUrgency {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case ApprovalUrgency.low:
        return 'Low';
      case ApprovalUrgency.medium:
        return 'Medium';
      case ApprovalUrgency.high:
        return 'High';
      case ApprovalUrgency.critical:
        return 'Critical';
    }
  }
}

class ApprovalChainStep {
  final String userName;
  final String roleLabel;
  final ApprovalStatus status;
  final String? date;

  ApprovalChainStep({
    required this.userName,
    required this.roleLabel,
    required this.status,
    this.date,
  });

  factory ApprovalChainStep.fromJson(Map<String, dynamic> json) {
    return ApprovalChainStep(
      userName: json['userName'] as String,
      roleLabel: json['roleLabel'] as String,
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      date: json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'roleLabel': roleLabel,
      'status': status.name,
      'date': date,
    };
  }
}

class ApprovalComment {
  final String userName;
  final String text;
  final String timestamp;

  ApprovalComment({
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  factory ApprovalComment.fromJson(Map<String, dynamic> json) {
    return ApprovalComment(
      userName: json['userName'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class Approval {
  final String id;
  final String type; // e.g., "PO Award", "RFQ Launch"
  final String requester;
  final double amount;
  final ApprovalUrgency urgency;
  final ApprovalStatus status;
  final String description;
  final String targetId; // Reference to PO ID or RFQ ID
  final List<ApprovalChainStep> chain;
  final List<ApprovalComment> comments;

  Approval({
    required this.id,
    required this.type,
    required this.requester,
    required this.amount,
    required this.urgency,
    required this.status,
    required this.description,
    required this.targetId,
    required this.chain,
    required this.comments,
  });

  Approval copyWith({
    String? id,
    String? type,
    String? requester,
    double? amount,
    ApprovalUrgency? urgency,
    ApprovalStatus? status,
    String? description,
    String? targetId,
    List<ApprovalChainStep>? chain,
    List<ApprovalComment>? comments,
  }) {
    return Approval(
      id: id ?? this.id,
      type: type ?? this.type,
      requester: requester ?? this.requester,
      amount: amount ?? this.amount,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      description: description ?? this.description,
      targetId: targetId ?? this.targetId,
      chain: chain ?? this.chain,
      comments: comments ?? this.comments,
    );
  }

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'] as String,
      type: json['type'] as String,
      requester: json['requester'] as String,
      amount: (json['amount'] as num).toDouble(),
      urgency: ApprovalUrgency.values.firstWhere(
        (e) => e.name == json['urgency'],
        orElse: () => ApprovalUrgency.medium,
      ),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      description: json['description'] as String,
      targetId: json['targetId'] as String,
      chain: (json['chain'] as List<dynamic>)
          .map((e) => ApprovalChainStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => ApprovalComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'requester': requester,
      'amount': amount,
      'urgency': urgency.name,
      'status': status.name,
      'description': description,
      'targetId': targetId,
      'chain': chain.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}
