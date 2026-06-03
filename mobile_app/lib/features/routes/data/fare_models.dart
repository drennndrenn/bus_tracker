class FareItem {
  const FareItem({
    required this.destination,
    required this.fare,
    this.id,
  });

  final String? id;
  final String destination;
  final int fare;
}

class RouteItem {
  const RouteItem({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.status,
  });

  final String id;
  final String name;
  final String origin;
  final String destination;
  final String status;
}
