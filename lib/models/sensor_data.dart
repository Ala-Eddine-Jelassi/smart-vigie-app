class SensorDataPoint {
  final double value;
  final DateTime timestamp;

  SensorDataPoint({
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) => SensorDataPoint(
    value: json['value'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}