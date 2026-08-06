import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/wireframe_box.dart';
import '../../risk/widgets/risk_score_badge.dart';
import '../../risk/widgets/risk_score_gauge.dart';

class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final restaurant = args is RestaurantModel ? args : MockSeedData.restaurants.first;

    return Scaffold(
      appBar: CustomAppBar(title: restaurant.name),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                WireframeBox(
                  height: 180,
                  icon: Icons.store,
                  label: restaurant.name,
                  sublabel: 'Outlet Image',
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: RiskScoreBadge(category: restaurant.riskCategory),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusBadge.fromStatus(restaurant.status.name),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(restaurant.category, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF0284C7), size: 20),
                      const SizedBox(width: 6),
                      Expanded(child: Text(restaurant.address, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Wireframe Map Preview
                  WireframeBox(
                    height: 120,
                    icon: Icons.map,
                    label: 'GPS: ${restaurant.latitude}, ${restaurant.longitude}',
                    sublabel: 'Tap map below',
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Risk Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              RiskScoreGauge(score: restaurant.hygieneRiskScore),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tier: ${restaurant.riskCategory.name.toUpperCase()}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Violations: ${restaurant.violationCount}'),
                                    Text(
                                      'Updated: ${restaurant.lastUpdated}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'View Map',
                    icon: Icons.map,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.restaurantMap,
                        arguments: restaurant,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    label: 'Submit Report',
                    icon: Icons.report_problem,
                    backgroundColor: Colors.red.shade700,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.submitComplaint,
                        arguments: restaurant,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    label: 'Risk Details',
                    icon: Icons.analytics,
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.restaurantRiskDetail,
                        arguments: restaurant,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
