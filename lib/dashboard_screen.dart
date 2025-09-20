import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _temperature = '--';
  String _humidity = '--';
  String _waterTankLevel = '--';

  late DatabaseReference _databaseReference;
  late StreamSubscription<DatabaseEvent> _databaseSubscription;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  void _initDatabase() {
    _databaseReference = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://agrosmart-f1233-default-rtdb.asia-southeast1.firebasedatabase.app/')
        .ref('SensorData');

    _databaseSubscription = _databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        developer.log('Data received: $data');
        setState(() {
          _temperature = data['Temperature']?.toString() ?? '--';
          _humidity = data['Humidity']?.toString() ?? '--';
          final distance = data['Distance'];
          if (distance != null && distance is num) {
            final level = ((33 - distance) / 33) * 100;
            _waterTankLevel = level.toStringAsFixed(1);
          } else {
            _waterTankLevel = '--';
          }
        });
      } else {
        developer.log('No data received from Firebase');
      }
    }, onError: (error) {
      developer.log('Error listening to Firebase: $error');
    });
  }

  @override
  void dispose() {
    _databaseSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroTech Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Farmer!\n',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDashboardGrid(context),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              Text(
                'Crop Health Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildChartPlaceholder(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDashboardCard(
          context,
          icon: Icons.thermostat_outlined,
          title: 'Temperature',
          value: '$_temperature°C',
          color: Colors.orange,
        ),
        _buildDashboardCard(
          context,
          icon: Icons.water_drop_outlined,
          title: 'Humidity',
          value: '$_humidity%',
          color: Colors.blue,
        ),
        _buildDashboardCard(
          context,
          icon: Icons.storage_rounded,
          title: 'Water Tank Level (1000L)',
          value: '$_waterTankLevel%',
          color: Colors.lightBlue,
        ),
        _buildDashboardCard(
          context,
          icon: Icons.grass_outlined,
          title: 'Soil Moisture',
          value: '40%', // Placeholder
          color: Colors.brown,
        ),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(context, icon: Icons.water_damage_outlined, label: 'Irrigate'),
        _buildActionItem(context, icon: Icons.bug_report_outlined, label: 'Scout Pests'),
        _buildActionItem(context, icon: Icons.biotech_outlined, label: 'Add Nutrients'),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label}) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: () {},
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildChartPlaceholder(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 200,
        child: const Center(
          child: Text(
            'Chart will be displayed here',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
