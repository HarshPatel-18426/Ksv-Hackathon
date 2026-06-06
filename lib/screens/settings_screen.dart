import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _companyNameController = TextEditingController(text: 'VendorBridge Enterprise');
  final _companyGstController = TextEditingController(text: '22AAAAA0000A1Z5');
  final _companyAddressController = TextEditingController(text: 'Plot 42, Chakan MIDC Phase 2, Pune, Maharashtra - 410501');
  final _companyPaymentTermsController = TextEditingController(text: '30 Days Net');

  bool _emailNotify = true;
  bool _pushNotify = true;
  bool _smsNotify = false;

  // Mock User Registry for User Management table
  final List<Map<String, dynamic>> _usersList = [
    {'name': 'Rajesh Kumar', 'email': 'rajesh.kumar@vendorbridge.in', 'role': UserRole.admin, 'active': true},
    {'name': 'Ananya Sharma', 'email': 'ananya.sharma@vendorbridge.in', 'role': UserRole.procurementOfficer, 'active': true},
    {'name': 'Manager', 'email': 'manager@vendorbridge.in', 'role': UserRole.manager, 'active': true},
    {'name': 'Aarav Mehta', 'email': 'aarav.mehta@vendorbridge.in', 'role': UserRole.vendor, 'active': true},
  ];

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _companyNameController.dispose();
    _companyGstController.dispose();
    _companyAddressController.dispose();
    _companyPaymentTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    final isAdmin = role == UserRole.admin;

    return ResponsiveScaffold(
      title: 'Settings & Profiles',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        (user?.name ?? 'G').substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Guest User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(user?.email ?? 'guest@vendorbridge.in', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                          const SizedBox(height: 8),
                          StatusChip(label: role.label, color: _getRoleColor(role)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tabs/Expanders for Settings categories
            // 1. Change Password Expander
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Security & Password', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _oldPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Enter current password' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.length < 6 ? 'New password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_passwordFormKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Color(0xFF27AE60)),
                                );
                                _oldPasswordController.clear();
                                _newPasswordController.clear();
                              }
                            },
                            child: const Text('Update Password'),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Notification Preferences
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  SwitchListTile(
                    title: const Text('Email Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Send emails on purchase order issuances and RFQ launches', style: TextStyle(fontSize: 11)),
                    value: _emailNotify,
                    onChanged: (val) => setState(() => _emailNotify = val),
                  ),
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Send mobile alerts when approvals require actions', style: TextStyle(fontSize: 11)),
                    value: _pushNotify,
                    onChanged: (val) => setState(() => _pushNotify = val),
                  ),
                  SwitchListTile(
                    title: const Text('SMS / WhatsApp Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Send SMS updates for invoice payouts status changes', style: TextStyle(fontSize: 11)),
                    value: _smsNotify,
                    onChanged: (val) => setState(() => _smsNotify = val),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Company Details (Admin Only)
            if (isAdmin) ...[
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text('Company Organization Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _companyFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(labelText: 'Company Legal Name', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _companyGstController,
                              decoration: const InputDecoration(labelText: 'Company GSTIN', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _companyAddressController,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _companyPaymentTermsController,
                              decoration: const InputDecoration(labelText: 'Default Payment Terms', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Company profile details saved!'), backgroundColor: Color(0xFF27AE60)),
                                );
                              },
                              child: const Text('Save Organization Details'),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. User Administration Management (Admin Only)
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text('User Administration & Roles', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Portal Users:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Invite User', style: TextStyle(fontSize: 11)),
                                onPressed: () => _openInviteUserDialog(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                              rows: _usersList.map((usr) {
                                return DataRow(
                                  cells: [
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(usr['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text(usr['email'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    )),
                                    DataCell(Text((usr['role'] as UserRole).label, style: const TextStyle(fontSize: 11))),
                                    DataCell(StatusChip(
                                      label: usr['active'] ? 'Active' : 'Inactive',
                                      color: usr['active'] ? const Color(0xFF27AE60) : Colors.grey,
                                    )),
                                    DataCell(
                                      TextButton(
                                        onPressed: usr['role'] == UserRole.admin
                                            ? null // Cannot toggle main admin
                                            : () {
                                                setState(() {
                                                  usr['active'] = !usr['active'];
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('User ${usr['name']} access updated.')),
                                                );
                                              },
                                        child: Text(
                                          usr['active'] ? 'Deactivate' : 'Activate',
                                          style: TextStyle(
                                            color: usr['active'] ? Colors.red : Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFE74C3C);
      case UserRole.procurementOfficer:
        return const Color(0xFF2E86AB);
      case UserRole.manager:
        return const Color(0xFFF39C12);
      case UserRole.vendor:
        return const Color(0xFF27AE60);
    }
  }

  void _openInviteUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.procurementOfficer;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Invite Portal User'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                      validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Assigned Role'),
                      items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                      onChanged: (role) {
                        if (role != null) {
                          setDialogState(() => selectedRole = role);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _usersList.add({
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim().toLowerCase(),
                          'role': selectedRole,
                          'active': true,
                        });
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User invitation dispatched!'), backgroundColor: Color(0xFF27AE60)),
                      );
                    }
                  },
                  child: const Text('Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
