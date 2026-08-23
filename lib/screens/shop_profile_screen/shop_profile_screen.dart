import 'package:flutter/material.dart';

import '../scan_invoice_screen/scan_invoice_screen.dart';
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
  late final TextEditingController _customBusinessTypeController;
  BusinessType _selectedBusinessType = BusinessType.kirana;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController()..addListener(_onFormChanged);
    _ownerNameController = TextEditingController()..addListener(_onFormChanged);
    _phoneNumberController = TextEditingController()
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
    _customBusinessTypeController.removeListener(_onFormChanged);

    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneNumberController.dispose();
    _customBusinessTypeController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
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
            onPressed: _isFormValid ? _handleContinue : null,
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    if (!_isFormValid) return;

    final shopName = _shopNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final businessTypeStr = _selectedBusinessType == BusinessType.other
        ? _customBusinessTypeController.text.trim()
        : _selectedBusinessType.name;

    debugPrint('Shop Name: $shopName');
    debugPrint('Owner Name: $ownerName');
    debugPrint('Phone Number: $phoneNumber');
    debugPrint('Business Type: $businessTypeStr');

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScanInvoiceScreen()),
    );
  }
}
