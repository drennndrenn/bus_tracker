import 'dart:math';

import 'tracking_models.dart';

class TrackingSimulator {
  TrackingSimulator() : _rng = Random();

  final Random _rng;

  LiveTrackingState seed({
    required String fromLocation,
    required String toLocation,
  }) {
    return _buildState(
      baseProgress: _rng.nextDouble() * 0.25,
      routeBaseMinutes: _routeBaseMinutes(fromLocation, toLocation),
    );
  }

  LiveTrackingState next(
    LiveTrackingState current, {
    required String fromLocation,
    required String toLocation,
  }) {
    final currentProgress = current.progress;
    final traffic = _pickTraffic();
    final currentStatus = _pickStatus(currentProgress, traffic);
    final progressStep = switch (currentStatus) {
      ServiceStatus.delayed => 0.004 + (_rng.nextDouble() * 0.012),
      ServiceStatus.onTime => 0.012 + (_rng.nextDouble() * 0.020),
      ServiceStatus.arriving => 0.006 + (_rng.nextDouble() * 0.012),
    };
    final nextProgress = (currentProgress + progressStep).clamp(0.02, 0.99);
    return _buildState(
      baseProgress: nextProgress,
      traffic: traffic,
      previousEtaMinutes: current.etaMinutes,
      routeBaseMinutes: _routeBaseMinutes(fromLocation, toLocation),
    );
  }

  LiveTrackingState _buildState({
    required double baseProgress,
    required int routeBaseMinutes,
    TrafficLevel? traffic,
    int? previousEtaMinutes,
  }) {
    final resolvedTraffic = traffic ?? _pickTraffic();
    final status = _pickStatus(baseProgress, resolvedTraffic);
    final baseEta = max(2, ((1.0 - baseProgress) * routeBaseMinutes).round());
    final eta = _resolveEta(
      status: status,
      baseEta: baseEta,
      previousEtaMinutes: previousEtaMinutes,
    );
    final speed = switch (resolvedTraffic) {
      TrafficLevel.light => 34 + _rng.nextInt(12),
      TrafficLevel.moderate => 24 + _rng.nextInt(10),
      TrafficLevel.heavy => 12 + _rng.nextInt(10),
    };

    return LiveTrackingState(
      status: status,
      etaMinutes: eta,
      progress: baseProgress,
      speedKmh: speed,
      trafficLevel: resolvedTraffic,
      updatedAt: DateTime.now(),
    );
  }

  int _resolveEta({
    required ServiceStatus status,
    required int baseEta,
    int? previousEtaMinutes,
  }) {
    if (previousEtaMinutes == null) return baseEta;

    if (status == ServiceStatus.delayed) {
      // Delay should visibly push ETA up, even if progress moved.
      final increaseBy = 2 + _rng.nextInt(4); // +2 to +5 minutes
      final delayedFloor = previousEtaMinutes + increaseBy;
      final delayedBase = baseEta + (3 + _rng.nextInt(5));
      return max(delayedFloor, delayedBase);
    }

    if (status == ServiceStatus.arriving) {
      // Keep dropping smoothly near destination.
      final reduced = previousEtaMinutes - (1 + _rng.nextInt(3));
      return max(1, min(baseEta, reduced));
    }

    // On-time should generally trend down, with minor variance.
    final reduced = previousEtaMinutes - (1 + _rng.nextInt(2));
    return max(2, min(baseEta, reduced));
  }

  TrafficLevel _pickTraffic() {
    final value = _rng.nextDouble();
    if (value < 0.3) return TrafficLevel.light;
    if (value < 0.75) return TrafficLevel.moderate;
    return TrafficLevel.heavy;
  }

  ServiceStatus _pickStatus(double progress, TrafficLevel traffic) {
    if (progress > 0.85) return ServiceStatus.arriving;
    if (traffic == TrafficLevel.heavy) return ServiceStatus.delayed;
    return ServiceStatus.onTime;
  }

  int _routeBaseMinutes(String from, String to) {
    final key = _routeKey(from, to);
    return _routeDurationMinutes[key] ?? 45;
  }

  String _routeKey(String a, String b) {
    return a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
  }

  static const Map<String, int> _routeDurationMinutes = {
    'Tagum City|Panabo City': 22,
    'Carmen|Tagum City': 14,
    'Sto. Tomas|Tagum City': 31,
    'Kapalong|Tagum City': 93,
    'New Corella|Tagum City': 23,
    'Asuncion|Tagum City': 32,
    'Carmen|Panabo City': 8,
    'Panabo City|Sto. Tomas': 31,
    'Kapalong|Panabo City': 110,
    'New Corella|Panabo City': 42,
    'Asuncion|Panabo City': 44,
    'Carmen|Sto. Tomas': 28,
    'Carmen|Kapalong': 105,
    'Carmen|New Corella': 35,
    'Asuncion|Carmen': 41,
    'Kapalong|Sto. Tomas': 83,
    'New Corella|Sto. Tomas': 37,
    'Asuncion|Sto. Tomas': 17,
    'Kapalong|New Corella': 94,
    'Asuncion|Kapalong': 80,
    'Asuncion|New Corella': 34,
  };
}
