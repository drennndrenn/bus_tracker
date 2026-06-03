import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/project_entitlements.dart';
import '../../../alerts/data/alerts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/tracking_models.dart';
import '../../data/tracking_simulator.dart';
import '../widgets/free_tier_tracking_ad_dialog.dart';
import '../widgets/location_selector_card.dart';
import '../widgets/map_panel.dart';
import '../widgets/status_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _pollIntervalFree = Duration(seconds: 14);
  static const _pollIntervalPro = Duration(seconds: 8);

  String? fromLocation;
  String? toLocation;
  bool isTracking = false;
  String trackingError = '';
  LiveTrackingState? liveState;

  final _simulator = TrackingSimulator();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    ProjectEntitlements.instance.addListener(_onPlanChanged);
  }

  void _onPlanChanged() {
    if (!mounted) return;
    if (isTracking) {
      _restartPolling();
    }
    setState(() {});
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    if (!isTracking ||
        fromLocation == null ||
        toLocation == null ||
        fromLocation == toLocation) {
      return;
    }
    final interval =
        ProjectEntitlements.instance.isPro ? _pollIntervalPro : _pollIntervalFree;
    _pollTimer = Timer.periodic(interval, (_) {
      if (!mounted || liveState == null) return;
      final previous = liveState!;
      final next = _simulator.next(
        previous,
        fromLocation: fromLocation!,
        toLocation: toLocation!,
      );
      setState(() => liveState = next);
      _maybePublishTrackingAlerts(previous, next);
    });
  }

  void _maybePublishTrackingAlerts(LiveTrackingState previous, LiveTrackingState next) {
    if (fromLocation == null || toLocation == null) return;

    if (previous.status != next.status) {
      AlertsService.instance.publishTripStatusChange(
        from: fromLocation!,
        to: toLocation!,
        status: next.status,
        etaMinutes: next.etaMinutes,
      );
    }

    if (ProjectEntitlements.instance.isPro &&
        previous.trafficLevel != next.trafficLevel) {
      AlertsService.instance.publishTrafficAlert(
        from: fromLocation!,
        to: toLocation!,
        level: next.trafficLevel,
        etaMinutes: next.etaMinutes,
      );
    }
  }

  void _swapLocations() {
    if (isTracking) _stopTracking();
    setState(() {
      final temp = fromLocation;
      fromLocation = toLocation;
      toLocation = temp;
    });
  }

  Future<void> _onTrackPressed() async {
    if (fromLocation == null || toLocation == null || fromLocation == toLocation) {
      return;
    }

    if (!ProjectEntitlements.instance.isPro) {
      final proceed = await FreeTierTrackingAdDialog.show(context);
      if (!mounted || !proceed) return;
    }

    _startTracking();
  }

  void _startTracking() {
    if (fromLocation == null || toLocation == null || fromLocation == toLocation) {
      return;
    }

    final seeded = _simulator.seed(
      fromLocation: fromLocation!,
      toLocation: toLocation!,
    );

    setState(() {
      isTracking = true;
      trackingError = '';
      liveState = seeded;
    });

    AlertsService.instance.resetTrackingDedupe();
    AlertsService.instance.publishTripStatusChange(
      from: fromLocation!,
      to: toLocation!,
      status: seeded.status,
      etaMinutes: seeded.etaMinutes,
    );
    if (ProjectEntitlements.instance.isPro && seeded.trafficLevel != TrafficLevel.light) {
      AlertsService.instance.publishTrafficAlert(
        from: fromLocation!,
        to: toLocation!,
        level: seeded.trafficLevel,
        etaMinutes: seeded.etaMinutes,
      );
    }

    _restartPolling();
  }

  void _stopTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
    AlertsService.instance.resetTrackingDedupe();
    setState(() {
      isTracking = false;
      liveState = null;
      trackingError = '';
    });
  }

  void _onFromChanged(String? value) {
    if (isTracking) _stopTracking();
    setState(() => fromLocation = value);
  }

  void _onToChanged(String? value) {
    if (isTracking) _stopTracking();
    setState(() => toLocation = value);
  }

  String _statusLabel(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.onTime:
        return 'On Time';
      case ServiceStatus.delayed:
        return 'Delayed';
      case ServiceStatus.arriving:
        return 'Arriving';
    }
  }

  String _formatEta(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}m';
    }
    return '$minutes min';
  }

  @override
  void dispose() {
    ProjectEntitlements.instance.removeListener(_onPlanChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = liveState;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _HomeWelcomeHeader(),
        const SizedBox(height: 14),
        LocationSelectorCard(
          locations: AppConstants.locations,
          fromLocation: fromLocation,
          toLocation: toLocation,
          isTracking: isTracking,
          onFromChanged: _onFromChanged,
          onToChanged: _onToChanged,
          onSwapPressed: (fromLocation != null || toLocation != null) ? _swapLocations : null,
          onTrackPressed: () => _onTrackPressed(),
          onStopPressed: isTracking ? _stopTracking : null,
        ),
        const SizedBox(height: 14),
        _SectionLabel(
          icon: Icons.map_rounded,
          title: 'Live map',
          subtitle: isTracking ? 'Following your selected route' : 'Route preview',
        ),
        const SizedBox(height: 8),
        MapPanel(
          from: fromLocation,
          to: toLocation,
          isTracking: isTracking,
          progress: current?.progress ?? 0,
          statusLabel: current != null ? _statusLabel(current.status) : 'Idle',
        ),
        if (isTracking && fromLocation != null && toLocation != null && current != null) ...[
          const SizedBox(height: 14),
          const _SectionLabel(
            icon: Icons.insights_rounded,
            title: 'Trip status',
            subtitle: 'Updated in real time',
          ),
          const SizedBox(height: 8),
          TrackerStatusCard(
            from: fromLocation!,
            to: toLocation!,
            status: _statusLabel(current.status),
            eta: _formatEta(current.etaMinutes),
            progress: current.progress,
          ),
          if (trackingError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trackingError,
                        style: const TextStyle(
                          color: AppColors.gray700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

String _timeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'Good morning, commuter';
  }
  if (hour >= 12 && hour < 18) {
    return 'Good day, commuter';
  }
  if (hour >= 18 && hour < 22) {
    return 'Good evening, commuter';
  }
  return 'Good evening, commuter';
}

IconData _timeBasedGreetingIcon() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 18) {
    return Icons.wb_sunny_rounded;
  }
  if (hour >= 18 && hour < 22) {
    return Icons.wb_twilight_rounded;
  }
  return Icons.nightlight_round;
}

class _HomeWelcomeHeader extends StatelessWidget {
  const _HomeWelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final greeting = _timeBasedGreeting();
    final greetingIcon = _timeBasedGreetingIcon();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue50,
            AppColors.success.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue600, AppColors.success],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue600.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(greetingIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time bus tracking across ${AppConstants.appSubtitle}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray600,
                        height: 1.35,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.blue600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
