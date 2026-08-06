import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';

class RestaurantVerificationDetailScreen extends StatefulWidget {
  const RestaurantVerificationDetailScreen({super.key});

  @override
  State<RestaurantVerificationDetailScreen> createState() => _RestaurantVerificationDetailScreenState();
}

class _RestaurantVerificationDetailScreenState extends State<RestaurantVerificationDetailScreen> {
  final _revisionNoteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final r = args is RestaurantModel ? args : MockSeedData.restaurants.last;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Outlet Review'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge.fromStatus(r.status.name),
            const SizedBox(height: 12),
            Text(r.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(r.category, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Address'),
                      subtitle: Text(r.address),
                    ),
                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: const Text('Coordinates'),
                      subtitle: Text('Lat: ${r.latitude}, Long: ${r.longitude}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _revisionNoteCtrl,
              decoration: const InputDecoration(
                labelText: 'Revision Note',
                hintText: 'Enter notes...',
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Approve Outlet',
              icon: Icons.check_circle,
              backgroundColor: Colors.green.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${r.name} Approved!')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Request Revision',
              icon: Icons.edit_note,
              backgroundColor: Colors.amber.shade800,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revision requested!')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Reject Entry',
              icon: Icons.cancel,
              backgroundColor: Colors.red.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submission rejected.')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
