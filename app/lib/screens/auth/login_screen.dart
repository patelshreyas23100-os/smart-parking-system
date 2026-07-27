import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _showOtpField = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleGetOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email')));
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.requestOtp(_emailController.text, type: 'login');
      setState(() => _showOtpField = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email!'), backgroundColor: AppColors.success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (_showOtpField) {
        await authProvider.loginWithOtp(_emailController.text, _otpController.text, _passwordController.text);
      } else {
        await authProvider.login(_emailController.text, _passwordController.text);
      }
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } catch (e) {
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
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: const Icon(Icons.local_parking, size: 60, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'SMART PARKING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const Text(
                            'Premium Parking Management',
                            style: TextStyle(color: Colors.white70, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    
                    // Form Section
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5)),
                          ],
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome Back',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Login to manage your slots & vehicles',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                                  ),
                                  const SizedBox(height: 48),
                                  
                                  // Email Field
                                  _buildLabel('Email Address'),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: _inputDecoration(
                                      hint: 'name@example.com',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Always show Password Field
                                  _buildLabel('Password'),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: _inputDecoration(
                                      hint: '••••••••',
                                      icon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                                  ),
                                  
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                      child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),

                                  if (!_showOtpField) ...[
                                    const SizedBox(height: 8),
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, child) {
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 60,
                                          child: ElevatedButton(
                                            onPressed: auth.isLoading ? null : _handleGetOtp,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              elevation: 8,
                                            ),
                                            child: auth.isLoading 
                                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                              : const Text('Generate OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          ),
                                        );
                                      },
                                    ),
                                  ] else ...[
                                    // OTP Field
                                    _buildLabel('Enter 6-digit OTP'),
                                    TextFormField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration(
                                        hint: '••••••',
                                        icon: Icons.vpn_key_outlined,
                                      ),
                                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Login Button
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, child) {
                                        return Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              height: 60,
                                              child: ElevatedButton(
                                                onPressed: auth.isLoading ? null : _handleLogin,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.success,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  elevation: 8,
                                                ),
                                                child: auth.isLoading 
                                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                                  : const Text('Verify & Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => setState(() => _showOtpField = false),
                                              child: const Text('Change Details', style: TextStyle(color: AppColors.textSecondary)),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                  
                                  const Spacer(),
                                  const SizedBox(height: 40),
                                  
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
                                        TextButton(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                          child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
