import 'package:flutter/material.dart';

class WaterTankCard extends StatelessWidget {
  final num waterLevel;
  final int tankCapacity;

  const WaterTankCard({
    super.key,
    required this.waterLevel,
    this.tankCapacity = 1000, // Default to 1000L
  });

  @override
  Widget build(BuildContext context) {
    String alertMessage = '';
    Color progressColor = Colors.blue;
    IconData alertIcon = Icons.info_outline;

    if (waterLevel < 20) {
      alertMessage = 'Water level is low. Consider saving water.';
      progressColor = Colors.red;
      alertIcon = Icons.warning_amber_rounded;
    } else if (waterLevel > 95) {
      alertMessage = 'Tank is nearly full. Risk of overflowing.';
      progressColor = Colors.orange;
      alertIcon = Icons.warning_amber_rounded;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Tank Level (${tankCapacity}L)', // Display capacity
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.storage, size: 40, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${waterLevel.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: waterLevel / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (alertMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(alertIcon, color: progressColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alertMessage,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: progressColor),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
