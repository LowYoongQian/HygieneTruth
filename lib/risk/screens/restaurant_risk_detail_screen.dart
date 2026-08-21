import 'package:flutter/material.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../widgets/risk_score_badge.dart';
import '../widgets/risk_score_gauge.dart';

class RestaurantRiskDetailScreen extends StatelessWidget {
  const RestaurantRiskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final r = args is RestaurantModel ? args : (RestaurantStoreService.restaurantsNotifier.value.isNotEmpty ? RestaurantStoreService.restaurantsNotifier.value.first : null);
    if (r == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Risk Details'),
        body: Center(child: Text('No restaurant selected')),
      );
    }
    RestaurantStoreService.recordRecentVisit(r);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Risk Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  RiskScoreGauge(score: r.hygieneRiskScore, size: 90),
                  const SizedBox(height: 12),
                  RiskScoreBadge(category: r.riskCategory),
                  const SizedBox(height: 8),
                  Text(r.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(r.address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timestamp Card
            Card(
              color: Colors.teal.shade50,
              child: ListTile(
                leading: const Icon(Icons.update, color: Colors.teal),
                title: const Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(r.lastUpdated),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Risk Factors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _factorRow(
                      title: 'Verified Complaints',
                      value: '${r.violationCount} Complaints',
                      isNegative: r.violationCount > 0,
                    ),
                    const Divider(),
                    _factorRow(
                      title: 'Inspection Record',
                      value: r.violationCount > 1 ? 'Failed Recent Visit' : 'Passed Inspection',
                      isNegative: r.violationCount > 1,
                    ),
                    const Divider(),
                    _factorRow(
                      title: 'GPS Recency',
                      value: '14 Days Ago',
                      isNegative: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Submit Report',
              icon: Icons.report_problem,
              backgroundColor: Colors.red.shade700,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.submitComplaint,
                  arguments: r,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _factorRow({required String title, required String value, required bool isNegative}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Row(
            children: [
              Icon(
                isNegative ? Icons.warning_amber : Icons.check_circle,
                size: 16,
                color: isNegative ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isNegative ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
