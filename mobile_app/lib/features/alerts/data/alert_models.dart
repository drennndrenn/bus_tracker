enum AlertType {
  paymentPending,
  paymentApproved,
  paymentRejected,
  trip,
  traffic,
}

AlertType alertTypeFromString(String? value) {
  switch (value) {
    case 'payment_pending':
      return AlertType.paymentPending;
    case 'payment_approved':
      return AlertType.paymentApproved;
    case 'payment_rejected':
      return AlertType.paymentRejected;
    case 'traffic':
      return AlertType.traffic;
    case 'trip':
    default:
      return AlertType.trip;
  }
}

String alertTypeToString(AlertType type) {
  switch (type) {
    case AlertType.paymentPending:
      return 'payment_pending';
    case AlertType.paymentApproved:
      return 'payment_approved';
    case AlertType.paymentRejected:
      return 'payment_rejected';
    case AlertType.traffic:
      return 'traffic';
    case AlertType.trip:
      return 'trip';
  }
}

class CommuterAlert {
  const CommuterAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.createdAt,
    this.routeFrom,
    this.routeTo,
  });

  final String id;
  final AlertType type;
  final String title;
  final String body;
  final bool read;
  final DateTime? createdAt;
  final String? routeFrom;
  final String? routeTo;

  factory CommuterAlert.fromFirestore(String id, Map<String, dynamic> data) {
    return CommuterAlert(
      id: id,
      type: alertTypeFromString(data['type'] as String?),
      title: data['title'] as String? ?? 'Alert',
      body: data['body'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
      routeFrom: data['routeFrom'] as String?,
      routeTo: data['routeTo'] as String?,
    );
  }
}
