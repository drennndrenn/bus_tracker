import 'package:flutter/material.dart';

import '../../../../core/project_entitlements.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/alert_models.dart';
import '../../data/alerts_service.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AlertsService.instance,
        ProjectEntitlements.instance,
      ]),
      builder: (context, _) {
        final service = AlertsService.instance;
        final alerts = service.alerts;
        final signedIn = ProjectEntitlements.instance.isSignedIn;

        if (!signedIn && alerts.isEmpty) {
          return _EmptyState(
            icon: Icons.login_rounded,
            title: 'Sign in to save alerts',
            subtitle:
                'You can still see trip updates here while tracking. Sign in to sync payment and traffic alerts across devices.',
          );
        }

        if (alerts.isEmpty) {
          return _EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No alerts right now',
            subtitle: ProjectEntitlements.instance.isPro
                ? 'Start tracking a trip on Home for live updates, or wait for payment and traffic alerts.'
                : 'Start tracking a trip on Home for basic trip updates, or submit a Pro payment to get status alerts.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (service.lastError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Cloud sync issue — showing alerts saved on this device. Deploy Firestore rules if this persists.',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            if (service.usingLocalFallbackOnly && service.lastError == null && signedIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Session alerts (sign in and deploy rules for cloud sync).',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12),
                ),
              ),
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlertCard(
                  alert: alert,
                  onTap: () => service.markRead(alert.id),
                  onDelete: () async {
                    final removed = await service.deleteAlert(alert.id);
                    if (!context.mounted) return;
                    if (!removed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not delete this alert. Try again.'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onDelete,
  });

  final CommuterAlert alert;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final style = _styleForType(alert.type);

    return Material(
      color: alert.read ? Colors.white : style.background,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alert.read ? AppColors.gray200 : style.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: style.iconBg,
                        child: Icon(style.icon, color: style.iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: alert.read
                                          ? AppColors.gray700
                                          : AppColors.gray900,
                                    ),
                                  ),
                                ),
                                if (!alert.read) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.blue600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.body,
                              style: const TextStyle(
                                color: AppColors.gray600,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            if (alert.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _formatWhen(alert.createdAt!),
                                style: const TextStyle(
                                  color: AppColors.gray400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: IconButton(
                tooltip: 'Delete alert',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.danger,
                splashRadius: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatWhen(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _AlertVisualStyle {
  const _AlertVisualStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color background;
  final Color border;
}

_AlertVisualStyle _styleForType(AlertType type) {
  switch (type) {
    case AlertType.paymentApproved:
      return _AlertVisualStyle(
        icon: Icons.verified_rounded,
        iconColor: AppColors.success,
        iconBg: AppColors.success.withValues(alpha: 0.15),
        background: AppColors.success.withValues(alpha: 0.08),
        border: AppColors.success.withValues(alpha: 0.35),
      );
    case AlertType.paymentRejected:
      return _AlertVisualStyle(
        icon: Icons.cancel_rounded,
        iconColor: AppColors.danger,
        iconBg: AppColors.danger.withValues(alpha: 0.12),
        background: AppColors.danger.withValues(alpha: 0.06),
        border: AppColors.danger.withValues(alpha: 0.3),
      );
    case AlertType.paymentPending:
      return _AlertVisualStyle(
        icon: Icons.hourglass_top_rounded,
        iconColor: AppColors.blue600,
        iconBg: AppColors.blue50,
        background: AppColors.blue50,
        border: AppColors.blue200,
      );
    case AlertType.traffic:
      return _AlertVisualStyle(
        icon: Icons.traffic_rounded,
        iconColor: AppColors.warning,
        iconBg: AppColors.warning.withValues(alpha: 0.15),
        background: AppColors.warning.withValues(alpha: 0.1),
        border: AppColors.warning.withValues(alpha: 0.35),
      );
    case AlertType.trip:
      return _AlertVisualStyle(
        icon: Icons.directions_bus_rounded,
        iconColor: AppColors.blue600,
        iconBg: AppColors.blue50,
        background: Colors.white,
        border: AppColors.blue100,
      );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gray400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray600,
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
