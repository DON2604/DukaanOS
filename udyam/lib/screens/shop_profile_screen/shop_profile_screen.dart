import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../verify_otp_screen/verify_otp_screen.dart';
import 'models/business_type.dart';
import 'widgets/shop_profile_app_bar.dart';
import 'widgets/shop_profile_form.dart';
import 'widgets/shop_profile_continue_button.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  late final TextEditingController _shopNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _telegramChatIdController;
  late final TextEditingController _customBusinessTypeController;
  final AuthService _authService = AuthService();
  BusinessType _selectedBusinessType = BusinessType.kirana;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController()..addListener(_onFormChanged);
    _ownerNameController = TextEditingController()..addListener(_onFormChanged);
    _phoneNumberController = TextEditingController()
      ..addListener(_onFormChanged);
    _telegramChatIdController = TextEditingController()
      ..addListener(_onFormChanged);
    _customBusinessTypeController = TextEditingController()
      ..addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _shopNameController.removeListener(_onFormChanged);
    _ownerNameController.removeListener(_onFormChanged);
    _phoneNumberController.removeListener(_onFormChanged);
    _telegramChatIdController.removeListener(_onFormChanged);
    _customBusinessTypeController.removeListener(_onFormChanged);

    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneNumberController.dispose();
    _telegramChatIdController.dispose();
    _customBusinessTypeController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final hasBasics =
        _shopNameController.text.trim().isNotEmpty &&
        _ownerNameController.text.trim().isNotEmpty &&
        _phoneNumberController.text.trim().isNotEmpty &&
        int.tryParse(_telegramChatIdController.text.trim()) != null;

    if (!hasBasics) return false;
    if (_selectedBusinessType == BusinessType.other) {
      return _customBusinessTypeController.text.trim().isNotEmpty;
    }
    return true;
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
                  child: ShopProfileForm(
                    shopNameController: _shopNameController,
                    ownerNameController: _ownerNameController,
                    phoneNumberController: _phoneNumberController,
                    telegramChatIdController: _telegramChatIdController,
                    customBusinessTypeController: _customBusinessTypeController,
                    selectedBusinessType: _selectedBusinessType,
                    onBusinessTypeChanged: (type) {
                      setState(() {
                        _selectedBusinessType = type;
                      });
                    },
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
          child: ShopProfileContinueButton(
            isLoading: _isSubmitting,
            onPressed: _isFormValid && !_isSubmitting ? _handleContinue : null,
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (!_isFormValid || _isSubmitting) return;

    final ownerName = _ownerNameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final telegramChatId = int.parse(_telegramChatIdController.text.trim());
    final shopName = _shopNameController.text.trim();
    final shopType = _selectedBusinessType.toApiValue(
      _customBusinessTypeController.text,
    );

    setState(() => _isSubmitting = true);
    try {
      await _authService.createAccount(
        name: ownerName,
        phone: phoneNumber,
        telegramChatId: telegramChatId,
        shopName: shopName,
        shopType: shopType,
      );
      await _authService.requestCreateAccountOtp(phoneNumber);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              VerifyOtpScreen(phone: phoneNumber, flow: AuthFlow.signUp),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Could not create the account. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
