import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../gps/widgets/restaurant_card.dart';

class RecommendationHomeScreen extends StatefulWidget {
  const RecommendationHomeScreen({super.key});

  @override
  State<RecommendationHomeScreen> createState() => _RecommendationHomeScreenState();
}

class _RecommendationHomeScreenState extends State<RecommendationHomeScreen> {
  bool _showEmptyStateDemo = false;
  String _lastRefreshed = '2026-08-06 12:00 PM';

  List<RestaurantModel> get _safeRestaurants => MockSeedData.restaurants
      .where((r) => r.riskCategory == RiskCategory.safe)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Safe Food',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _lastRefreshed = DateTime.now().toString().split('.')[0];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed safe food list!')),
              );
            },
          ),
          IconButton(
            icon: Icon(_showEmptyStateDemo ? Icons.visibility : Icons.visibility_off),
            tooltip: 'Toggle Demo',
            onPressed: () {
              setState(() => _showEmptyStateDemo = !_showEmptyStateDemo);
            },
          ),
        ],
      ),
      body: _showEmptyStateDemo
          ? EmptyStateWidget(
              title: 'No Safe Outlets',
              message: 'No safe food outlets found nearby.',
              icon: Icons.g_mobiledata,
              actionLabel: 'View Heatmap',
              onAction: () => Navigator.pushNamed(context, AppRoutes.hygieneHeatmap),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safe Food Finder',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Evaluated by verified complaint analysis.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Updated: $_lastRefreshed',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Top Safe Eats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.riskRankingList),
                        child: const Text('Risk Rankings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  for (final r in _safeRestaurants) RestaurantCard(restaurant: r),

                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_fire_department, color: Colors.red),
                      title: const Text('Risk Heatmap', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('View high complaint zones'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.hygieneHeatmap),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
