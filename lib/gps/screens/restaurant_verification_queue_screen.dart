import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';

class RestaurantVerificationQueueScreen extends StatelessWidget {
  const RestaurantVerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingList = MockSeedData.restaurants
        .where((r) => r.status == RestaurantStatus.pendingVerification)
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Pending Outlets'),
      body: pendingList.isEmpty
          ? const Center(child: Text('No pending outlets.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final r = pendingList[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(r.imageUrl),
                    ),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        StatusBadge.fromStatus(r.status.name),
                      ],
                    ),
                    trailing: const Icon(Icons.rate_review, color: Colors.purple),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.restaurantVerificationDetail,
                        arguments: r,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
