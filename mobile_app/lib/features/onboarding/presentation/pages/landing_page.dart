import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Welcome screen shown before the main app shell.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onTrackBus});

  final VoidCallback onTrackBus;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final compact = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blue50,
              Colors.white,
              Color(0xFFECFDF5),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: _DecorCircle(
                  size: 160,
                  color: AppColors.blue300.withValues(alpha: 0.35),
                ),
              ),
              Positioned(
                top: 120,
                left: -50,
                child: _DecorCircle(
                  size: 120,
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              Positioned(
                bottom: 80,
                right: -20,
                child: _DecorCircle(
                  size: 90,
                  color: AppColors.blue400.withValues(alpha: 0.25),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          const _TopBadge(),
                          SizedBox(height: compact ? 16 : 24),
                          _LogoHero(compact: compact),
                          SizedBox(height: compact ? 16 : 22),
                          _BrandTitle(compact: compact),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.appSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: compact ? 16 : 20),
                          const _FeatureHighlights(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + bottomInset),
                    child: _TrackBusButton(onPressed: onTrackBus),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.blue100),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.radar_rounded, color: AppColors.blue600, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Live bus tracking for commuters',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoHero extends StatelessWidget {
  const _LogoHero({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 120.0 : 140.0;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(color: AppColors.blue100, width: 3),
      ),
      child: Image.asset(
        'assets/logo.png',
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.directions_bus_rounded,
          size: logoSize * 0.65,
          color: AppColors.blue600,
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: compact ? 30 : 34,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.8,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.blue700, AppColors.blue500],
              ).createShader(bounds),
              child: Text('Bus Tracking', style: titleStyle.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.success, Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'PH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'TRACK · RIDE · ARRIVE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.blue700.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _FeatureTile(
          icon: Icons.my_location_rounded,
          color: AppColors.blue600,
          title: 'Real-time tracking',
          subtitle: 'See buses and ETAs on your route',
        ),
        const SizedBox(height: 10),
        _FeatureTile(
          icon: Icons.alt_route_rounded,
          color: AppColors.success,
          title: 'Routes & fares',
          subtitle: 'Browse stops across ${AppConstants.appSubtitle}',
        ),
        const SizedBox(height: 10),
        const _FeatureTile(
          icon: Icons.notifications_active_rounded,
          color: AppColors.warning,
          title: 'Trip alerts',
          subtitle: 'Get updates while you commute',
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackBusButton extends StatelessWidget {
  const _TrackBusButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.blue700, AppColors.blue500, Color(0xFF38BDF8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.directions_bus_filled, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'Start tracking buses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
