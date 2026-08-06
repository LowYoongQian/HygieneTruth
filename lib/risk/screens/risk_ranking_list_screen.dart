import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../widgets/risk_score_badge.dart';
import '../widgets/risk_score_gauge.dart';

class RiskRankingListScreen extends StatefulWidget {
  const RiskRankingListScreen({super.key});

  @override
  State<RiskRankingListScreen> createState() => _RiskRankingListScreenState();
}

class _RiskRankingListScreenState extends State<RiskRankingListScreen> {
  String _selectedTierFilter = 'All';

  List<RestaurantModel> _getRankedList() {
    List<RestaurantModel> list = List.from(MockSeedData.restaurants);
    list.sort((a, b) => a.hygieneRiskScore.compareTo(b.hygieneRiskScore));

    if (_selectedTierFilter != 'All') {
      list = list
          .where((r) => r.riskCategory.name.toLowerCase() == _selectedTierFilter.toLowerCase())
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _getRankedList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Risk Rankings'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['All', 'Safe', 'Moderate', 'High'].map((tier) {
                final isSelected = _selectedTierFilter.toLowerCase() == tier.toLowerCase();
                return ChoiceChip(
                  label: Text(tier),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedTierFilter = tier);
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ranked.isEmpty
                ? const Center(child: Text('No outlets match tier.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: ranked.length,
                    itemBuilder: (context, index) {
                      final r = ranked[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: [
                              RiskScoreGauge(score: r.hygieneRiskScore, size: 28),
                              const SizedBox(width: 8),
                              Text('Score: ${r.hygieneRiskScore.toStringAsFixed(1)}'),
                            ],
                          ),
                          trailing: RiskScoreBadge(category: r.riskCategory),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.restaurantRiskDetail,
                              arguments: r,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
