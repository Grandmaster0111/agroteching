import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class IrrigationControlCard extends StatefulWidget {
  const IrrigationControlCard({super.key});

  @override
  State<IrrigationControlCard> createState() => _IrrigationControlCardState();
}

class _IrrigationControlCardState extends State<IrrigationControlCard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final ValueNotifier<bool> _autoMode = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _valveStatus = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _database.child('system/autoMode').onValue.listen((event) {
      if (event.snapshot.exists) {
        _autoMode.value = event.snapshot.value as bool;
      }
    });
    _database.child('system/valveOpen').onValue.listen((event) {
      if (event.snapshot.exists) {
        _valveStatus.value = event.snapshot.value as bool;
      }
    });
  }

  void _toggleAutoMode(bool value) {
    _database.child('system/autoMode').set(value);
  }

  void _toggleValve(bool value) {
    _database.child('system/valveOpen').set(value);
  }

  Future<void> _showTimerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _database.child('system/timer').set(picked.format(context));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Irrigation scheduled for ${picked.format(context)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Irrigation Control',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: _autoMode,
              builder: (context, autoMode, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Auto Mode'),
                    Switch(
                      value: autoMode,
                      onChanged: _toggleAutoMode,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: _autoMode,
              builder: (context, autoMode, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _valveStatus,
                  builder: (context, valveOpen, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Manual Valve Control'),
                        ElevatedButton(
                          onPressed: autoMode ? null : () => _toggleValve(!valveOpen),
                          child: Text(valveOpen ? 'Turn OFF' : 'Turn ON'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scheduled Irrigation'),
                TextButton(
                  onPressed: _showTimerDialog,
                  child: const Text('Set Timer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
