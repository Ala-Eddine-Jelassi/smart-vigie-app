import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  Future<void> saveSensorData({
    required double temperature,
    required double humidity,
    required DateTime timestamp,
  }) async {
    try {
      final dataRef = database.child('sensor_data').push();

      await dataRef.set({
        'temperature': temperature,
        'humidity': humidity,
        'timestamp': timestamp.toIso8601String(),
        'timestamp_ms': timestamp.millisecondsSinceEpoch,
      });

      print('Data saved to Firebase');
    } catch (e) {
      print('Error saving to Firebase: $e');
      rethrow;
    }
  }

  Future<List<SensorDataPoint>> getHistoricalData(String type, {int limit = 100}) async {
    try {
      final snapshot = await database
          .child('sensor_data')
          .orderByChild('timestamp_ms')
          .limitToLast(limit)
          .get();

      final List<SensorDataPoint> data = [];

      if (snapshot.exists) {
        final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

        values.forEach((key, value) {
          final double reading = type == 'temperature'
              ? (value['temperature'] as num).toDouble()
              : (value['humidity'] as num).toDouble();
          final DateTime timestamp = DateTime.parse(value['timestamp']);

          data.add(SensorDataPoint(
            value: reading,
            timestamp: timestamp,
          ));
        });

        // Sort by timestamp
        data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      return data;
    } catch (e) {
      print('Error getting historical data: $e');
      return [];
    }
  }

  Future<void> clearOldData(int daysToKeep) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffMs = cutoffDate.millisecondsSinceEpoch;

    try {
      final snapshot = await database
          .child('sensor_data')
          .orderByChild('timestamp_ms')
          .endBefore(cutoffMs)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

        for (var key in values.keys) {
          await database.child('sensor_data').child(key).remove();
        }

        print('Cleared old data older than $daysToKeep days');
      }
    } catch (e) {
      print('Error clearing old data: $e');
    }
  }
}