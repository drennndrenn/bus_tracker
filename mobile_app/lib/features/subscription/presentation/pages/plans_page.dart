import 'package:flutter/material.dart';

import '../../../../core/project_entitlements.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/commuter_auth_service.dart';
import '../pro_activation_flow.dart';

/// Subscription plans — layout aligned with product mockup.
class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  static const _brandBlue = Color(0xFF2563EB);
  static const _navy = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Plans',
          style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: ProjectEntitlements.instance,
            builder: (context, _) {
              if (!ProjectEntitlements.instance.isSignedIn) {
                return const SizedBox(width: 48);
              }
              return IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout, color: _navy),
                onPressed: () => _confirmSignOut(context),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ProjectEntitlements.instance,
        builder: (context, _) {
          final ent = ProjectEntitlements.instance;
          final isPro = ent.isPro;
          final isPending = ent.isPending;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text(
                "Choose the plan that's right for you",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Unlock powerful features for smarter bus tracking and greater control.',
                style: TextStyle(fontSize: 15, color: _muted, height: 1.45),
              ),
              if (ent.isSignedIn) ...[
                const SizedBox(height: 20),
                _SignedInBanner(email: ent.email ?? 'commuter'),
              ],
              if (isPending) ...[
                const SizedBox(height: 14),
                _StatusBanner(
                  icon: Icons.hourglass_top_rounded,
                  color: Color(0xFFEA580C),
                  background: Color(0xFFFFF7ED),
                  message: 'Payment pending super admin review.',
                ),
              ],
              if (ent.rejectReason != null && !isPro && !isPending) ...[
                const SizedBox(height: 14),
                _StatusBanner(
                  icon: Icons.info_outline_rounded,
                  color: Color(0xFFB91C1C),
                  background: Color(0xFFFEF2F2),
                  message: 'Last payment rejected: ${ent.rejectReason}',
                ),
              ],
              const SizedBox(height: 22),
              _FreePlanCard(isCurrent: !isPro && !isPending),
              const SizedBox(height: 16),
              _ProPlanCard(
                isPro: isPro,
                isPending: isPending,
                onActivate: isPending || isPro ? null : () => startProActivationFlow(context),
              ),
              const SizedBox(height: 28),
              const _SecurePaymentsFooter(),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You can sign in again anytime to check your subscription status.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
      ],
    ),
  );

  if (leave != true || !context.mounted) return;

  await CommuterAuthService.instance.signOut();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out.')),
    );
  }
}

class _SignedInBanner extends StatelessWidget {
  const _SignedInBanner({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.blue50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: PlansPage._brandBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Signed in as $email',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PlansPage._navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.background,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({required this.isCurrent});

  final bool isCurrent;

  static const _features = [
    'Real-time bus location tracking',
    'View estimated arrival times',
    'Route and stop information',
    'Basic trip notifications',
    'Access to nearby buses',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue200, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PlanHeader(
              icon: Icons.near_me_rounded,
              iconBg: PlansPage._brandBlue,
              title: 'Free Plan',
            ),
            const SizedBox(height: 10),
            const Text(
              'Perfect for daily commuters who want basic real-time bus tracking and route monitoring.',
              style: TextStyle(fontSize: 14, color: PlansPage._muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Free / Limited',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PlansPage._brandBlue,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.blue100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Current plan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PlansPage._brandBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            ..._features.map((f) => _FeatureRow(text: f)),
          ],
        ),
      ),
    );
  }
}

class _ProPlanCard extends StatelessWidget {
  const _ProPlanCard({
    required this.isPro,
    required this.isPending,
    this.onActivate,
  });

  final bool isPro;
  final bool isPending;
  final VoidCallback? onActivate;

  static const _features = [
    'All Free features',
    'Personalized route suggestions',
    'Delay and traffic alerts',
    'Save favorite routes and stops',
    'Ad-free experience',
    'Priority customer support',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PlanHeader(
              icon: Icons.workspace_premium_rounded,
              iconBg: Color(0xFF6366F1),
              title: 'Pro',
            ),
            const SizedBox(height: 10),
            const Text(
              'For commuters who rely heavily on public transportation every day.',
              style: TextStyle(fontSize: 14, color: PlansPage._muted, height: 1.45),
            ),
            const SizedBox(height: 14),
            const Text(
              'PHP 99 / month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PlansPage._brandBlue,
              ),
            ),
            const SizedBox(height: 18),
            ..._features.map((f) => _FeatureRow(text: f)),
            const SizedBox(height: 20),
            if (isPro)
              const Center(
                child: Text(
                  'Pro plan active',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: PlansPage._brandBlue,
                    fontSize: 15,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onActivate,
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: Text(isPending ? 'Pending review' : 'Activate Pro plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: PlansPage._brandBlue,
                    disabledBackgroundColor: AppColors.gray200,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.icon,
    required this.iconBg,
    required this.title,
  });

  final IconData icon;
  final Color iconBg;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: PlansPage._navy,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: PlansPage._brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: PlansPage._navy, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurePaymentsFooter extends StatelessWidget {
  const _SecurePaymentsFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 18, color: PlansPage._muted),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Secure payments powered by trusted partners. You can cancel anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: PlansPage._muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
