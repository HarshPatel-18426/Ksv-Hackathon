enum UserRole {
  admin,
  procurementOfficer,
  manager,
  vendor;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.procurementOfficer:
        return 'Procurement Officer';
      case UserRole.manager:
        return 'Manager';
      case UserRole.vendor:
        return 'Vendor';
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? companyName; // Used if they are a Vendor
  final String? gstNumber;   // Used if they are a Vendor

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.companyName,
    this.gstNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.procurementOfficer,
      ),
      avatarUrl: json['avatarUrl'] as String?,
      companyName: json['companyName'] as String?,
      gstNumber: json['gstNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'companyName': companyName,
      'gstNumber': gstNumber,
    };
  }
}
