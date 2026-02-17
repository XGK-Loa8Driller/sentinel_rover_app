class ThreatModel {
  final String id;
  final String severity;
  final double latitude;
  final double longitude;
  final double distance;
  final DateTime timestamp;
  final bool neutralized;
  final List<String> alertsSent;

  ThreatModel({
    required this.id,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.timestamp,
    this.neutralized = false,
    this.alertsSent = const [],
  });

  factory ThreatModel.fromJson(Map<String, dynamic> json) {
    return ThreatModel(
      id: json['id'] ?? '',
      severity: json['severity'] ?? 'medium',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      neutralized: json['neutralized'] ?? false,
      alertsSent: json['alerts_sent'] != null
          ? List<String>.from(json['alerts_sent'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'timestamp': timestamp.toIso8601String(),
      'neutralized': neutralized,
      'alerts_sent': alertsSent,
    };
  }
}
