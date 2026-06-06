import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;

  UserRole _selectedRole = UserRole.procurementOfficer;
  String _selectedCategory = 'Metals & Alloys';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo
                      Center(
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(
                            Icons.handshake_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VendorBridge',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin ? 'Login to your account' : 'Create an account',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      if (!_isLogin) ...[
                        // Name Field (Register only)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),

                        // Role Dropdown (Register only)
                        DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Account Role',
                            prefixIcon: const Icon(Icons.person_pin_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem<UserRole>(
                              value: role,
                              child: Text(role.label),
                            );
                          }).toList(),
                          onChanged: (role) {
                            if (role != null) setState(() => _selectedRole = role);
                          },
                        ),
                        const SizedBox(height: 16),

                        if (_selectedRole == UserRole.vendor) ...[
                          TextFormField(
                            controller: _companyController,
                            decoration: InputDecoration(
                              labelText: 'Company Name',
                              prefixIcon: const Icon(Icons.business_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter company name' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: ['Metals & Alloys', 'Engineering', 'Polymers', 'Cement', 'Unassigned'].map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _gstController,
                            decoration: InputDecoration(
                              labelText: 'GST Number',
                              hintText: 'e.g. 22AAAAA0000A1Z5',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter GST number';
                              // Loose validation for testing/demo
                              if (value.trim().length < 3) return 'GST number too short';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
                      ),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Action Button
                      ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Text(_isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),

                      // Toggle Login/Register
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              backgroundColor: theme.colorScheme.surface,
              title: Row(
                children: [
                  Icon(
                    Icons.lock_reset_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your registered email address below. We will send you a link to secure your account and reset your password.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      enabled: !isSending,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 24, bottom: 20),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            setStateDialog(() {
                              isSending = true;
                            });
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            auth.sendPasswordReset(emailController.text.trim()).then((_) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Password reset link successfully sent to ${emailController.text.trim()}',
                                  ),
                                  backgroundColor: const Color(0xFF27AE60),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }).catchError((error) {
                              setStateDialog(() {
                                isSending = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${error.toString()}'),
                                  backgroundColor: theme.colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSending
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Send Reset Link',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        if (_isLogin) {
          await auth.login(_emailController.text.trim(), _passwordController.text.trim());
        } else {
          await auth.register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
            companyName: _selectedRole == UserRole.vendor ? _companyController.text.trim() : null,
            gstNumber: _selectedRole == UserRole.vendor ? _gstController.text.trim().toUpperCase() : null,
            category: _selectedRole == UserRole.vendor ? _selectedCategory : null,
          );
        }
        if (mounted) context.go('/dashboard');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
