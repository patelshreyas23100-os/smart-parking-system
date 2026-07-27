import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _showOtpField = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (!_showOtpField) {
        await authProvider.requestOtp(_emailController.text, type: 'signup');
        setState(() => _showOtpField = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification OTP sent to your email!'), backgroundColor: AppColors.success));
        return;
      }

      await authProvider.signupWithOtp(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        otp: _otpController.text,
        password: _passwordController.text,
        licenceNo: _licenceController.text,
      );
      
      if (mounted) {
        Navigator.pop(context); // Go back to Login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Please login.'), 
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), 
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      // Header
                      const Text(
                        'Join Smart Park',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        'Create your account to start booking',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      
                      // Form Card
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 450),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildField(
                                      label: 'Full Name',
                                      controller: _nameController,
                                      hint: 'Enter your name',
                                      icon: Icons.person_outline,
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildField(
                                      label: 'Email',
                                      controller: _emailController,
                                      hint: 'Enter your email',
                                      icon: Icons.email_outlined,
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildField(
                                      label: 'Phone Number',
                                      controller: _phoneController,
                                      hint: 'Enter phone number',
                                      icon: Icons.phone_outlined,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Required';
                                        if (v.length != 10) return 'Must be 10 digits';
                                        if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Digits only';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildField(
                                      label: 'Licence Number',
                                      controller: _licenceController,
                                      hint: 'Enter driving licence',
                                      icon: Icons.badge_outlined,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Required';
                                        final reg = RegExp(r'^[A-Za-z]{2}[0-9]{2}[ -]?[0-9]{4}[ -]?[0-9]{7}$');
                                        if (!reg.hasMatch(v.replaceAll(' ', '').replaceAll('-', ''))) {
                                          return 'Format: GJ01 2023 0000000';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildField(
                                      label: 'Password',
                                      controller: _passwordController,
                                      hint: 'Enter password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Password is required';
                                        if (v.length < 8) return 'Min 8 chars required';
                                        if (!RegExp(r'[!@#\$&*~%]').hasMatch(v)) return 'Must contain special char';
                                        return null;
                                      },
                                    ),
                                    if (_showOtpField) ...[
                                      const SizedBox(height: 20),
                                      _buildField(
                                        label: 'Verification OTP',
                                        controller: _otpController,
                                        hint: 'Enter 6-digit OTP',
                                        icon: Icons.vpn_key_outlined,
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                      ),
                                    ],
                                    if (!_showOtpField) ...[
                                      const SizedBox(height: 40),
                                      Consumer<AuthProvider>(
                                        builder: (context, auth, child) {
                                          return SizedBox(
                                            width: double.infinity,
                                            height: 60,
                                            child: ElevatedButton(
                                              onPressed: auth.isLoading ? null : _handleRegister,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                elevation: 5,
                                              ),
                                              child: auth.isLoading 
                                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                                : const Text('Generate OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            ),
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 40),
                                      Consumer<AuthProvider>(
                                        builder: (context, auth, child) {
                                          return Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                height: 60,
                                                child: ElevatedButton(
                                                  onPressed: auth.isLoading ? null : _handleRegister,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    elevation: 5,
                                                  ),
                                                  child: auth.isLoading 
                                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                                    : const Text('Complete Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => setState(() => _showOtpField = false),
                                                child: const Text('Edit Details', style: TextStyle(color: AppColors.textSecondary)),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 30),
                                    Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text("Already have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
