import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';
import '../main_shell/main_shell.dart';
import '../shop_profile_screen/widgets/shop_profile_app_bar.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool get _canVerify =>
      !_isVerifying && _otpController.text.trim().length == 6;

  Future<void> _verifyOtp() async {
    if (!_canVerify) return;

    setState(() => _isVerifying = true);
    try {
      await _authService.verifyCreateAccountOtp(
        phone: widget.phone,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not verify OTP. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending || _isVerifying) return;

    setState(() => _isResending = true);
    try {
      await _authService.requestCreateAccountOtp(widget.phone);
      if (!mounted) return;
      _showMessage('A new OTP was sent to your Telegram');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not resend OTP. Try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: const ShopProfileAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          color: Color(0xFF171917),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code we sent to your Telegram for ${widget.phone}',
                        style: const TextStyle(
                          color: Color(0xFF60645F),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        width: double.infinity,
                        borderRadius: 24,
                        backgroundColor: const Color(0xC8FFFFFF),
                        borderColor: const Color(0x80FFFFFF),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OTP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF171917),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 20,
                                letterSpacing: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF171917),
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xF2F7F5EE),
                                hintText: '000000',
                                hintStyle: TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 8,
                                  color: const Color(0xFF60645F)
                                      .withValues(alpha: 0.4),
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF1F6F46),
                                    size: 22,
                                  ),
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(minWidth: 36),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E4DE),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFB8490C),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isResending ? null : _resendOtp,
                                child: Text(
                                  _isResending ? 'Sending...' : 'Resend OTP',
                                  style: const TextStyle(
                                    color: Color(0xFFB8490C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canVerify ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canVerify
                    ? const Color(0xFFB8490C)
                    : const Color(0xFFE2E4DE),
                foregroundColor:
                    _canVerify ? Colors.white : const Color(0xFF8A8E88),
                elevation: _canVerify ? 2 : 0,
                shadowColor: _canVerify
                    ? const Color(0xFFB8490C).withValues(alpha: 0.3)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
