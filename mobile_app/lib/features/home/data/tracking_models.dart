enum ServiceStatus { onTime, delayed, arriving }

enum TrafficLevel { light, moderate, heavy }

class LiveTrackingState {
  const LiveTrackingState({
    required this.status,
    required this.etaMinutes,
    required this.progress,
    required this.speedKmh,
    required this.trafficLevel,
    required this.updatedAt,
  });

  final ServiceStatus status;
  final int etaMinutes;
  final double progress;
  final int speedKmh;
  final TrafficLevel trafficLevel;
  final DateTime updatedAt;
}
