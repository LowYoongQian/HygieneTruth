import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../widgets/enforcement_action_card.dart';

class EnforcementHistoryScreen extends StatelessWidget {
  const EnforcementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = MockSeedData.inspections;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Action History'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return EnforcementActionCard(
            inspection: list[index],
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.closeCase, arguments: list[index]);
            },
          );
        },
      ),
    );
  }
}
