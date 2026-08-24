import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';
import '../shop_profile_screen/widgets/shop_profile_app_bar.dart';
import '../verify_otp_screen/verify_otp_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.requestSignInOtp(phone);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(phone: phone, flow: AuthFlow.signIn),
        ),
      );
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not sign in. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShopProfileAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the phone number registered with your shop.',
                style: TextStyle(color: Color(0xFF60645F)),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                width: double.infinity,
                borderRadius: 24,
                backgroundColor: const Color(0xC8FFFFFF),
                borderColor: const Color(0x80FFFFFF),
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _phoneController.text.trim().isNotEmpty && !_isSubmitting
                      ? _continue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8490C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
