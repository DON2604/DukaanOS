import 'package:flutter/material.dart';

import '../../../widgets/glass_container.dart';
import '../models/business_type.dart';
import 'business_type_card.dart';

class ShopProfileForm extends StatefulWidget {
  final TextEditingController shopNameController;
  final TextEditingController ownerNameController;
  final TextEditingController phoneNumberController;
  final TextEditingController telegramChatIdController;
  final TextEditingController customBusinessTypeController;
  final BusinessType selectedBusinessType;
  final ValueChanged<BusinessType> onBusinessTypeChanged;

  const ShopProfileForm({
    super.key,
    required this.shopNameController,
    required this.ownerNameController,
    required this.phoneNumberController,
    required this.telegramChatIdController,
    required this.customBusinessTypeController,
    required this.selectedBusinessType,
    required this.onBusinessTypeChanged,
  });

  @override
  State<ShopProfileForm> createState() => _ShopProfileFormState();
}

class _ShopProfileFormState extends State<ShopProfileForm> {
  @override
  Widget build(BuildContext context) {
    final isOtherSelected = widget.selectedBusinessType == BusinessType.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Basic Details'),
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
              _buildLabel('Shop Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: widget.shopNameController,
                hintText: 'e.g. Sharma General Store',
                prefixIcon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 20),
              _buildLabel('Owner Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: widget.ownerNameController,
                hintText: 'e.g. Ramesh Sharma',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: widget.phoneNumberController,
                hintText: '+91',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildLabel('Telegram Chat ID'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: widget.telegramChatIdController,
                hintText: 'e.g. 123456789',
                prefixIcon: Icons.telegram,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('Business Category'),
        const SizedBox(height: 6),
        _buildHelperText('Select the type that best describes your store'),
        const SizedBox(height: 16),
        _buildBusinessTypeGrid(),
        if (isOtherSelected) ...[
          const SizedBox(height: 16),
          GlassContainer(
            width: double.infinity,
            borderRadius: 20,
            backgroundColor: const Color(0xC8FFFFFF),
            borderColor: const Color(0xFFB8490C).withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Specify Your Business Type'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: widget.customBusinessTypeController,
                  hintText: 'e.g. Mobile Repair, Pharmacy, Dairy...',
                  prefixIcon: Icons.edit_note_outlined,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF171917),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildHelperText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF60645F),
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF171917),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF171917),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xF2F7F5EE),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: const Color(0xFF60645F).withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(prefixIcon, color: const Color(0xFF1F6F46), size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E4DE), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB8490C), width: 2),
        ),
      ),
    );
  }

  Widget _buildBusinessTypeGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BusinessTypeCard(
                icon: Icons.shopping_basket_outlined,
                label: 'Kirana / Groceries',
                isSelected: widget.selectedBusinessType == BusinessType.kirana,
                showCheckmark: true,
                onTap: () => widget.onBusinessTypeChanged(BusinessType.kirana),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BusinessTypeCard(
                icon: Icons.restaurant_outlined,
                label: 'Bakery & Sweets',
                isSelected: widget.selectedBusinessType == BusinessType.bakery,
                showCheckmark: true,
                onTap: () => widget.onBusinessTypeChanged(BusinessType.bakery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BusinessTypeCard(
                icon: Icons.local_florist_outlined,
                label: 'Vegetables & Fruits',
                isSelected:
                    widget.selectedBusinessType == BusinessType.vegetable,
                showCheckmark: true,
                onTap: () =>
                    widget.onBusinessTypeChanged(BusinessType.vegetable),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BusinessTypeCard(
                icon: Icons.handyman_outlined,
                label: 'Hardware & Tools',
                isSelected:
                    widget.selectedBusinessType == BusinessType.hardware,
                showCheckmark: true,
                onTap: () =>
                    widget.onBusinessTypeChanged(BusinessType.hardware),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BusinessTypeCard(
          icon: Icons.add_circle_outline,
          label: 'Other Business Type',
          isSelected: widget.selectedBusinessType == BusinessType.other,
          showCheckmark: true,
          onTap: () => widget.onBusinessTypeChanged(BusinessType.other),
        ),
      ],
    );
  }
}
