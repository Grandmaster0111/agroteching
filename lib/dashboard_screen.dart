import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myapp/irrigation_control_card.dart';
import 'package:myapp/water_tank_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _temperature = '--';
  String _humidity = '--';
  String _waterTankLevel = '--';
  String? _selectedCrop;
  String _irrigationSuggestion = "Select a crop to get suggestions.";

  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: "https://agrosmart-f1233-default-rtdb.asia-southeast1.firebasedatabase.app/",
  ).ref();

  late StreamSubscription<DatabaseEvent> _sensorSubscription;

  // Simulation variables
  Timer? _simulationTimer;
  double _simulatedSoilMoisture = 70.0;
  bool _isValveOpen = false;

  @override
  void initState() {
    super.initState();
    _checkAndCreateCropsData();
    _listenToSensorData();
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        if (_isValveOpen) {
          _simulatedSoilMoisture = min(100, _simulatedSoilMoisture + 2);
        } else {
          _simulatedSoilMoisture = max(0, _simulatedSoilMoisture - 1);
        }
      });
    });
  }

  void _listenToSensorData() {
    _sensorSubscription = _database.child('SensorData').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final distance = data['Distance'] ?? 0;
        final double waterLevel = (1.0 - (distance / 30.0)).clamp(0.0, 1.0) * 100.0;

        setState(() {
          _temperature = data['Temperature']?.toString() ?? '--';
          _humidity = data['Humidity']?.toString() ?? '--';
          _waterTankLevel = waterLevel.toStringAsFixed(1);
        });
      }
    }, onError: (error) {
      developer.log('Error listening to Firebase: $error');
    });
  }

  Future<void> _checkAndCreateCropsData() async {
    final snapshot = await _database.child('crops').get();
    if (!snapshot.exists) {
      await _database.child('crops').set({
        'wheat': {
          'minMoisture': 30,
          'maxMoisture': 60,
          'minTemp': 10,
          'maxTemp': 25,
        },
        'corn': {
          'minMoisture': 50,
          'maxMoisture': 80,
          'minTemp': 20,
          'maxTemp': 35,
        }
      });
    }
  }


  @override
  void dispose() {
    _sensorSubscription.cancel();
    _simulationTimer?.cancel();
    super.dispose();
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
            final sensors = data['SensorData'] as Map<dynamic, dynamic>?;

            if (sensors == null) {
              return const Center(
                child: Text(
                    "Waiting for sensor data... Ensure your device is connected."),
              );
            }

            final distance = sensors['Distance'] ?? 0;
            final double waterLevel = (1.0 - (distance / 30.0)).clamp(0.0, 1.0) * 100.0;

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
                IrrigationControlCard(
                  onValveToggled: (isOpen) {
                    setState(() {
                      _isValveOpen = isOpen;
                    });
                  },
                ),
                const SizedBox(height: 16),
                WaterTankCard(waterLevel: waterLevel, tankCapacity: 1000),
                const SizedBox(height: 16),
                _buildSensorCard(
                  icon: Icons.opacity,
                  title: 'Soil Moisture',
                  value: '${_simulatedSoilMoisture.toStringAsFixed(1)}%',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildSensorCard(
                  icon: Icons.thermostat,
                  title: 'Temperature & Humidity',
                  value:
                      '${sensors['Temperature']}°C / ${sensors['Humidity']}%',
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

  void _getIrrigationSuggestion(
      Map<dynamic, dynamic> sensors, Map<dynamic, dynamic> crop) {
    final moisture = _simulatedSoilMoisture;
    final temp = sensors['Temperature'];

    if (temp is! num) {
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
  
  Widget _buildCropSelector(Map<dynamic, dynamic> crops) {
    return DropdownButtonFormField<String>(
      value: _selectedCrop,
      hint: const Text("Select a crop"),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCrop = newValue;
        });
      },
      items: crops.keys.map<DropdownMenuItem<String>>((key) {
        return DropdownMenuItem<String>(
          value: key,
          child: Text(key),
        );
      }).toList(),
    );
  }
  
  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
        title: const Text('System Status', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: const ListTile(
        leading: Icon(Icons.wb_sunny, color: Colors.yellow),
        title: Text('Weather Forecast', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Sunny, 28°C', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
