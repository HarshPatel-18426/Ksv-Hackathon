import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/auth_provider.dart';
import '../providers/erp_provider.dart';
import '../models/vendor.dart';
import '../models/user_role.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/status_chip.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/confirm_dialog.dart';

class VendorRegistryScreen extends StatefulWidget {
  const VendorRegistryScreen({super.key});

  @override
  State<VendorRegistryScreen> createState() => _VendorRegistryScreenState();
}

class _VendorRegistryScreenState extends State<VendorRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  VendorStatus? _selectedStatus;
  bool _sortAscending = true;
  int _sortColumnIndex = 1;

  @override
  Widget build(BuildContext context) {
    final erpProvider = Provider.of<ErpProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final role = user?.role ?? UserRole.procurementOfficer;

    // Filter Vendors
    List<Vendor> filteredVendors = erpProvider.vendors.where((vendor) {
      final matchesSearch = vendor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.gstNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' || vendor.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null || vendor.status == _selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    // Sort Vendors
    if (_sortColumnIndex == 1) {
      filteredVendors.sort((a, b) => _sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    } else if (_sortColumnIndex == 2) {
      filteredVendors.sort((a, b) => _sortAscending ? a.category.compareTo(b.category) : b.category.compareTo(a.category));
    } else if (_sortColumnIndex == 4) {
      filteredVendors.sort((a, b) => _sortAscending ? a.rating.compareTo(b.rating) : b.rating.compareTo(a.rating));
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    return ResponsiveScaffold(
      title: 'Vendor Registry',
      floatingActionButton: (role == UserRole.admin || role == UserRole.procurementOfficer)
          ? FloatingActionButton(
              onPressed: () => _openVendorForm(context, null),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hintText: 'Search vendors by name, GST, category...',
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    onFilterPressed: () => _showFilterDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Filter Chips
            if (_selectedCategory != 'All' || _selectedStatus != null)
              _buildFilterChipsRow(context),

            // Main Registry Layout
            Expanded(
              child: filteredVendors.isEmpty
                  ? Center(
                      child: Text(
                        'No vendors found matching criteria.',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    )
                  : isMobile
                      ? _buildMobileListView(context, filteredVendors)
                      : _buildDesktopTableView(context, filteredVendors, role),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Text('Filters: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (_selectedCategory != 'All')
            Chip(
              label: Text(_selectedCategory, style: const TextStyle(fontSize: 11)),
              onDeleted: () => setState(() => _selectedCategory = 'All'),
            ),
          const SizedBox(width: 8),
          if (_selectedStatus != null)
            Chip(
              label: Text(_selectedStatus!.label, style: const TextStyle(fontSize: 11)),
              onDeleted: () => setState(() => _selectedStatus = null),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileListView(BuildContext context, List<Vendor> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final vendor = list[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vendor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(label: vendor.status.label, color: _getStatusColor(vendor.status)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Category: ${vendor.category}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('GSTIN: ${vendor.gstNumber}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${vendor.rating.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showVendorDetails(context, vendor),
                      child: const Text('View Details', style: TextStyle(fontSize: 13)),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTableView(BuildContext context, List<Vendor> list, UserRole role) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 900,
        sortAscending: _sortAscending,
        sortColumnIndex: _sortColumnIndex,
        columns: [
          const DataColumn2(label: Text('ID'), size: ColumnSize.S),
          DataColumn2(
            label: const Text('Vendor Name'),
            size: ColumnSize.L,
            onSort: (colIdx, asc) {
              setState(() {
                _sortColumnIndex = colIdx;
                _sortAscending = asc;
              });
            },
          ),
          DataColumn2(
            label: const Text('Category'),
            size: ColumnSize.M,
            onSort: (colIdx, asc) {
              setState(() {
                _sortColumnIndex = colIdx;
                _sortAscending = asc;
              });
            },
          ),
          const DataColumn2(label: Text('GST Number'), size: ColumnSize.M),
          DataColumn2(
            label: const Text('Rating'),
            size: ColumnSize.S,
            numeric: true,
            onSort: (colIdx, asc) {
              setState(() {
                _sortColumnIndex = colIdx;
                _sortAscending = asc;
              });
            },
          ),
          const DataColumn2(label: Text('Status'), size: ColumnSize.M),
          const DataColumn2(label: Text('Actions'), size: ColumnSize.M),
        ],
        rows: list.map((vendor) {
          return DataRow2(
            onTap: () => _showVendorDetails(context, vendor),
            cells: [
              DataCell(Text(vendor.id, style: const TextStyle(fontSize: 12))),
              DataCell(Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(vendor.category)),
              DataCell(Text(vendor.gstNumber, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
              DataCell(
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(vendor.rating.toStringAsFixed(1)),
                  ],
                ),
              ),
              DataCell(StatusChip(label: vendor.status.label, color: _getStatusColor(vendor.status))),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Vendor',
                      onPressed: (role == UserRole.admin || role == UserRole.procurementOfficer)
                          ? () => _openVendorForm(context, vendor)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(
                        vendor.status == VendorStatus.blacklisted ? Icons.check_circle_outline : Icons.block_outlined,
                        size: 18,
                        color: vendor.status == VendorStatus.blacklisted ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                      ),
                      tooltip: vendor.status == VendorStatus.blacklisted ? 'Unblacklist' : 'Blacklist',
                      onPressed: role == UserRole.admin
                          ? () => _handleBlacklistToggle(context, vendor)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(VendorStatus status) {
    switch (status) {
      case VendorStatus.active:
        return const Color(0xFF27AE60);
      case VendorStatus.blacklisted:
        return const Color(0xFFE74C3C);
      case VendorStatus.pendingVerification:
        return const Color(0xFFF39C12);
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String tempCategory = _selectedCategory;
        VendorStatus? tempStatus = _selectedStatus;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Vendors'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: (() {
                      final list = ['All', 'Metals & Alloys', 'Engineering', 'Polymers', 'Cement', 'Unassigned'];
                      if (!list.contains(tempCategory)) {
                        list.add(tempCategory);
                      }
                      return list.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList();
                    })(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => tempCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<VendorStatus?>(
                    value: tempStatus,
                    decoration: const InputDecoration(labelText: 'Verification Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...VendorStatus.values.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status.label));
                      })
                    ],
                    onChanged: (val) {
                      setDialogState(() => tempStatus = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = tempCategory;
                      _selectedStatus = tempStatus;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleBlacklistToggle(BuildContext context, Vendor vendor) {
    final isBlacklisted = vendor.status == VendorStatus.blacklisted;
    final action = isBlacklisted ? 'activate' : 'blacklist';

    ConfirmDialog.show(
      context,
      title: '${isBlacklisted ? 'Activate' : 'Blacklist'} Vendor',
      content: 'Are you sure you want to $action ${vendor.name}?',
      confirmLabel: isBlacklisted ? 'Activate' : 'Blacklist',
      isDestructive: !isBlacklisted,
    ).then((confirmed) {
      if (confirmed == true) {
        final erp = Provider.of<ErpProvider>(context, listen: false);
        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
        erp.toggleBlacklistVendor(vendor.id, user?.name ?? 'Admin').then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vendor.name} status updated successfully.'),
              backgroundColor: const Color(0xFF27AE60),
            ),
          );
        });
      }
    });
  }

  void _showVendorDetails(BuildContext context, Vendor vendor) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 4),
                          Text('ID: ${vendor.id} | Category: ${vendor.category}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                    StatusChip(label: vendor.status.label, color: _getStatusColor(vendor.status)),
                  ],
                ),
                const Divider(height: 32),

                // Contact Information
                const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.email_outlined, 'Email', vendor.email),
                _buildDetailRow(Icons.phone_outlined, 'Phone', vendor.phone),
                _buildDetailRow(Icons.location_on_outlined, 'Address', vendor.address),
                _buildDetailRow(Icons.description_outlined, 'GSTIN', vendor.gstNumber),
                const Divider(height: 32),

                // Performance History
                const Text('Vendor Performance Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _buildPerformanceItem('Pricing Score (50%)', vendor.performance.priceScore, theme),
                _buildPerformanceItem('Quality Score (30%)', vendor.performance.qualityScore, theme),
                _buildPerformanceItem('Delivery Score (20%)', vendor.performance.deliveryScore, theme),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weighted Overall Rating:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${vendor.performance.overallScore.toStringAsFixed(1)} / 100',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Document Attachments
                const Text('Document Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                if (vendor.attachments.isEmpty)
                  const Text('No documents uploaded.', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
                else
                  ...vendor.attachments.map((file) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.red),
                        title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Uploaded: ${file.uploadDate} | Size: ${file.size}', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Downloading ${file.name}...')),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                const Divider(height: 32),

                // Onboarding/Verification History
                const Text('System Logs & Verification Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                ...vendor.activityLog.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(log, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, double score, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text('${score.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(score > 80 ? Colors.green : (score > 60 ? Colors.orange : Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openVendorForm(BuildContext context, Vendor? existingVendor) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingVendor?.name ?? '');
    final categoryController = TextEditingController(text: existingVendor?.category ?? 'Metals & Alloys');
    final gstController = TextEditingController(text: existingVendor?.gstNumber ?? '');
    final emailController = TextEditingController(text: existingVendor?.email ?? '');
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: existingVendor?.phone ?? '');
    final addressController = TextEditingController(text: existingVendor?.address ?? '');
    VendorStatus status = existingVendor?.status ?? VendorStatus.pendingVerification;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingVendor == null ? 'Add Vendor' : 'Edit Vendor'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Vendor Name'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter vendor name' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: categoryController.text,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: (() {
                          final list = ['Metals & Alloys', 'Engineering', 'Polymers', 'Cement', 'Unassigned'];
                          if (!list.contains(categoryController.text)) {
                            list.add(categoryController.text);
                          }
                          return list.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList();
                        })(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              categoryController.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number',
                          hintText: 'e.g. 22AAAAA0000A1Z5',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter GST number';
                          if (val.trim().length < 3) return 'GST number too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email Address'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter email';
                          if (!val.contains('@') || !val.contains('.')) return 'Enter valid email address';
                          return null;
                        },
                      ),
                      if (existingVendor == null) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter password';
                            if (val.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter phone number';
                          if (val.trim().length < 10) return 'Enter 10-digit phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<VendorStatus>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Verification Status'),
                        items: VendorStatus.values.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              status = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);
                      final erp = Provider.of<ErpProvider>(context, listen: false);
                      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

                      if (existingVendor == null) {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        auth.registerNewVendorFromAdmin(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          gstNumber: gstController.text.trim().toUpperCase(),
                        ).then((uid) {
                          final v = Vendor(
                            id: uid,
                            name: nameController.text.trim(),
                            category: categoryController.text,
                            gstNumber: gstController.text.trim().toUpperCase(),
                            rating: 4.0,
                            status: status,
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            performance: VendorPerformance(priceScore: 85, qualityScore: 85, deliveryScore: 85),
                            attachments: [],
                            activityLog: ['Vendor registered on ${DateTime.now().toString().split(' ')[0]}'],
                          );

                          erp.addVendor(v, user?.name ?? 'Admin', password: passwordController.text.trim()).then((_) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vendor registered successfully!'), backgroundColor: Color(0xFF27AE60)),
                            );
                          });
                        }).catchError((err) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to register vendor: $err'), backgroundColor: Colors.red),
                          );
                        });
                      } else {
                        final v = Vendor(
                          id: existingVendor.id,
                          name: nameController.text.trim(),
                          category: categoryController.text,
                          gstNumber: gstController.text.trim().toUpperCase(),
                          rating: existingVendor.rating,
                          status: status,
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          address: addressController.text.trim(),
                          performance: existingVendor.performance,
                          attachments: existingVendor.attachments,
                          activityLog: existingVendor.activityLog,
                        );

                        erp.updateVendor(v, user?.name ?? 'Admin').then((_) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vendor updated successfully!'), backgroundColor: Color(0xFF27AE60)),
                          );
                        }).catchError((err) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update vendor: $err'), backgroundColor: Colors.red),
                          );
                        });
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
