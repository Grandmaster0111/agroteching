import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/notification_service.dart';

import 'irrigation_control_card.dart';
import 'water_tank_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: "https://agrotech-2c731-default-rtdb.firebaseio.com/",
  ).ref();

  late StreamSubscription<DatabaseEvent> _sensorSubscription;
  final NotificationService _notificationService = NotificationService();

  String? _selectedCrop;
  String _irrigationSuggestion = "Select a crop to get a suggestion.";

  @override
  void initState() {
    super.initState();
    _checkAndCreateCropsData();
    _listenToSensorData();
  }

  void _listenToSensorData() {
    _sensorSubscription = _database.child('sensors').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final waterLevel = data['water_tank_level'] ?? 0;
        if (waterLevel < 20) {
          _notificationService.showNotification(
            'Low Water Level',
            'Water tank level is critically low: $waterLevel%',
          );
        }
      }
    });
  }

  Future<void> _checkAndCreateCropsData() async {
    final snapshot = await _database.child('crops').get();
    if (!snapshot.exists || snapshot.value == null) {
      await _database.child('crops').set({
        "Tomato": {
          "minMoisture": 60,
          "maxMoisture": 80,
          "minTemp": 21,
          "maxTemp": 29,
          "watering_frequency": "Every 2-3 days"
        },
        "Lettuce": {
          "minMoisture": 50,
          "maxMoisture": 70,
          "minTemp": 15,
          "maxTemp": 22,
          "watering_frequency": "Every 1-2 days"
        },
        "Bell Pepper": {
          "minMoisture": 55,
          "maxMoisture": 75,
          "minTemp": 23,
          "maxTemp": 32,
          "watering_frequency": "Every 2-3 days"
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Irrigation Dashboard')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _database.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Fetching data...'),
                ],
              ),
            );
          }
          if (snapshot.hasData &&
              !snapshot.hasError &&
              snapshot.data!.snapshot.value != null) {
            final data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final crops = data['crops'] as Map<dynamic, dynamic>?;
            final sensors = data['sensors'] as Map<dynamic, dynamic>?;

            if (sensors == null) {
              return const Center(
                child: Text(
                    "Waiting for sensor data... Ensure your device is connected."),
              );
            }

            if (crops != null && _selectedCrop != null) {
              final selectedCropData =
                  crops[_selectedCrop] as Map<dynamic, dynamic>?;
              if (selectedCropData != null) {
                _getIrrigationSuggestion(sensors, selectedCropData);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (crops != null) _buildCropSelector(crops),
                const SizedBox(height: 16),
                _buildSuggestionCard(),
                const SizedBox(height: 16),
                const IrrigationControlCard(),
                const SizedBox(height: 16),
                WaterTankCard(waterLevel: sensors['water_tank_level'] ?? 0),
                const SizedBox(height: 16),
                _buildSensorCard(
                  icon: Icons.opacity,
                  title: 'Soil Moisture',
                  value: '${sensors['soil_moisture']}%',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildSensorCard(
                  icon: Icons.thermostat,
                  title: 'Temperature & Humidity',
                  value:
                      '${sensors['temperature']}°C / ${sensors['humidity']}%',
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildStatusCard(sensors['status'] ?? 'N/A'),
                const SizedBox(height: 16),
                _buildWeatherCard(),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('No data available.'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCropSelector(Map<dynamic, dynamic> crops) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButton<String>(
          hint: const Text('Select a crop'),
          value: _selectedCrop,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: crops.keys.map<DropdownMenuItem<String>>((key) {
            return DropdownMenuItem<String>(
              value: key as String,
              child: Text(key),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCrop = newValue;
            });
          },
        ),
      ),
    );
  }

  void _getIrrigationSuggestion(
      Map<dynamic, dynamic> sensors, Map<dynamic, dynamic> crop) {
    final moisture = sensors['soil_moisture'];
    final temp = sensors['temperature'];

    if (moisture is! num || temp is! num) {
      _irrigationSuggestion = "Waiting for valid sensor data.";
      return;
    }

    final minMoisture = crop['minMoisture'] as num;
    final maxMoisture = crop['maxMoisture'] as num;
    final minTemp = crop['minTemp'] as num;
    final maxTemp = crop['maxTemp'] as num;

    if (moisture < minMoisture) {
      _irrigationSuggestion =
          "Water needed. Soil moisture is below the ideal range.";
    } else if (moisture > maxMoisture) {
      _irrigationSuggestion =
          "Too much water. Soil moisture is above the ideal range.";
    } else if (temp < minTemp) {
      _irrigationSuggestion = "Conditions are too cold for this crop.";
    } else if (temp > maxTemp) {
      _irrigationSuggestion = "Conditions are too hot for this crop.";
    } else {
      _irrigationSuggestion =
          "Conditions are ideal. No irrigation needed.";
    }
  }

  Widget _buildSuggestionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 40, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _irrigationSuggestion,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.yellow[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 40, color: Colors.amber),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                status,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Forecast',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeatherDay('Mon', Icons.wb_sunny, '30°'),
                _buildWeatherDay('Tue', Icons.cloud, '28°'),
                _buildWeatherDay('Wed', Icons.grain, '26°'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildWeatherDay(String day, IconData icon, String temp) {
    return Column(
      children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(temp),
      ],
    );
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    super.dispose();
  }
}
