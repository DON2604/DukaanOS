import 'package:flutter/material.dart';

import 'widgets/welcome_app_bar.dart';
import 'widgets/welcome_hero_content.dart';
import 'widgets/welcome_action_buttons.dart';
import '../shop_profile_screen/shop_profile_screen.dart';
import '../sign_in_screen/sign_in_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EB),
      appBar: const WelcomeAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Expanded(
                child: SingleChildScrollView(child: WelcomeHeroContent()),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40, top: 12),
                child: WelcomeActionButtons(
                  onSetupShopPressed: () {
                    _handleSetupShop(context);
                  },
                  onSignInPressed: () {
                    _handleSignIn(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSetupShop(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ShopProfileScreen()));
  }

  void _handleSignIn(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SignInScreen()));
  }
}
