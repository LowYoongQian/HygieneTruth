import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';

class VerifiedComplaintsListScreen extends StatelessWidget {
  const VerifiedComplaintsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final verifiedList = MockSeedData.complaints;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Assigned Cases'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: verifiedList.length,
        itemBuilder: (context, index) {
          final c = verifiedList[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.verified, color: Colors.white, size: 20),
              ),
              title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${c.id} • Category: ${c.category}'),
                  Text('GPS: Lat ${c.latitude}, Long ${c.longitude}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  StatusBadge.fromStatus(c.status.name),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.complaintFullDetail,
                  arguments: c,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
