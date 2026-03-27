import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';

class SensorDataProvider extends ChangeNotifier {
  List<SensorDataPoint> _temperatureData = [];
  List<SensorDataPoint> _humidityData = [];
  double _currentTemperature = 0;
  double _currentHumidity = 0;
  bool _isConnected = false;

  MqttService? _mqttService;
  final FirebaseService _firebaseService = FirebaseService();

  List<SensorDataPoint> get temperatureData => _temperatureData;
  List<SensorDataPoint> get humidityData => _humidityData;
  double get currentTemperature => _currentTemperature;
  double get currentHumidity => _currentHumidity;
  bool get isConnected => _isConnected;

  SensorDataProvider() {
    initializeMqtt();
  }

  Future<void> initializeMqtt() async {
    _mqttService = MqttService(this);
    try {
      await _mqttService!.connect();
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      print('Failed to initialize MQTT: $e');
    }
  }

  void addTemperatureData(SensorDataPoint data) {
    _temperatureData.add(data);
    _currentTemperature = data.value;

    // Keep only last 100 points for chart
    if (_temperatureData.length > 100) {
      _temperatureData.removeAt(0);
    }

    // Save to Firebase with humidity data
    _saveToFirebase();
    notifyListeners();
  }

  void addHumidityData(SensorDataPoint data) {
    _humidityData.add(data);
    _currentHumidity = data.value;

    // Keep only last 100 points for chart
    if (_humidityData.length > 100) {
      _humidityData.removeAt(0);
    }

    // Save to Firebase with temperature data
    _saveToFirebase();
    notifyListeners();
  }

  Future<void> _saveToFirebase() async {
    if (_temperatureData.isNotEmpty && _humidityData.isNotEmpty) {
      // Save the latest reading
      final latestTemp = _temperatureData.last;
      final latestHumidity = _humidityData.last;

      // Check if timestamps are close (within 5 seconds)
      final timeDiff = latestTemp.timestamp.difference(latestHumidity.timestamp).abs();

      if (timeDiff.inSeconds <= 5) {
        await _firebaseService.saveSensorData(
          temperature: latestTemp.value,
          humidity: latestHumidity.value,
          timestamp: DateTime.now(),
        );
      }
    }
  }

  Future<void> loadHistoricalData() async {
    _temperatureData = await _firebaseService.getHistoricalData('temperature');
    _humidityData = await _firebaseService.getHistoricalData('humidity');
    notifyListeners();
  }

  void disconnect() {
    _mqttService?.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}