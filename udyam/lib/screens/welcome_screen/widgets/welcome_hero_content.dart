import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/glass_container.dart';

class WelcomeHeroContent extends StatelessWidget {
  const WelcomeHeroContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const AnimatedFeatureHeroCard(),
        const SizedBox(height: 128),
        _buildHeroHeadline(),
        const SizedBox(height: 12),
        _buildHeroSubtext(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeroHeadline() {
    return const Text(
      "Your shop. Your phone.\nThat's enough.",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF171917),
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildHeroSubtext() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        'DukaanOS keeps track of stock, sales and customers without making you do manual data entry.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF60645F),
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }
}

class AnimatedFeatureHeroCard extends StatefulWidget {
  const AnimatedFeatureHeroCard({super.key});

  @override
  State<AnimatedFeatureHeroCard> createState() =>
      _AnimatedFeatureHeroCardState();
}

class _AnimatedFeatureHeroCardState extends State<AnimatedFeatureHeroCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  final List<_FeatureSlideData> _slides = const [
    _FeatureSlideData(
      tag: 'CAMERA OBSERVES',
      icon: Icons.center_focus_strong,
      accentColor: Color(0xFFB8490C),
      softBgColor: Color(0xFFFFF0E6),
      title: 'Smart Camera Billing',
      description: 'Point phone camera at shop items & counters. DukaanOS recognizes stock and bills in seconds.',
    ),
    _FeatureSlideData(
      tag: 'MICROPHONE LISTENS',
      icon: Icons.graphic_eq,
      accentColor: Color(0xFF1F6F46),
      softBgColor: Color(0xFFE8F4EC),
      title: 'Voice-Activated Sales',
      description: 'Say "Added 2kg sugar for Ramesh" to log sales & customer udhar instantly with zero typing.',
    ),
    _FeatureSlideData(
      tag: 'AI UNDERSTANDS',
      icon: Icons.auto_awesome_outlined,
      accentColor: Color(0xFF2B5B84),
      softBgColor: Color(0xFFEBF3FA),
      title: 'Self-Updating ERP',
      description: 'Real shop activity automatically updates your inventory, profit margins and ledgers in real-time.',
    ),
    _FeatureSlideData(
      tag: 'PREDICTS & ALERTS',
      icon: Icons.insights_outlined,
      accentColor: Color(0xFF8C4A00),
      softBgColor: Color(0xFFFFF6E5),
      title: 'Predictive Inventory',
      description: 'Know what is selling fast before stock runs out. Get daily automatic reorder recommendations.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) return;
      final nextIndex = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassContainer(
          width: double.infinity,
          height: 310,
          borderRadius: 28,
          backgroundColor: const Color(0xEBF8F6F0),
          borderColor: const Color(0x99FFFFFF),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlideItem(slide);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildPageIndicator(),
            ],
          ),
        ),
        Positioned(
          top: -12,
          right: 14,
          child: _buildBadgeIcon(
            icon: Icons.storefront_outlined,
            color: const Color(0xFFB8490C),
            size: 24,
            width: 58,
            height: 58,
            borderRadius: 18,
          ),
        ),
        Positioned(
          left: -8,
          bottom: -10,
          child: _buildBadgeIcon(
            icon: Icons.trending_up,
            color: const Color(0xFF1F6F46),
            size: 26,
            width: 60,
            height: 60,
            isCircle: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSlideItem(_FeatureSlideData slide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: slide.softBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: slide.accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(slide.icon, size: 16, color: slide.accentColor),
              const SizedBox(width: 6),
              Text(
                slide.tag,
                style: TextStyle(
                  color: slide.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF171917),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF60645F),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isSelected = _currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isSelected ? 24 : 6,
          decoration: BoxDecoration(
            color: isSelected
                ? _slides[_currentIndex].accentColor
                : const Color(0xFFCDD0C8),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildBadgeIcon({
    required IconData icon,
    required Color color,
    required double size,
    required double width,
    required double height,
    double borderRadius = 16,
    bool isCircle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _FeatureSlideData {
  final String tag;
  final IconData icon;
  final Color accentColor;
  final Color softBgColor;
  final String title;
  final String description;

  const _FeatureSlideData({
    required this.tag,
    required this.icon,
    required this.accentColor,
    required this.softBgColor,
    required this.title,
    required this.description,
  });
}
