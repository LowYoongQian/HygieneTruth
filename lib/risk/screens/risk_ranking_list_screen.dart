import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';

enum RankingLeagueTier { bronze, silver, gold, platinum }

class RiskRankingListScreen extends StatefulWidget {
  const RiskRankingListScreen({super.key});

  @override
  State<RiskRankingListScreen> createState() => _RiskRankingListScreenState();
}

class _RiskRankingListScreenState extends State<RiskRankingListScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'Today'; // 'Today' or 'Week'
  String _selectedTierFilter = 'All';

  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  // Determine League Tier based on User Directives:
  RankingLeagueTier _getRestaurantTier(RestaurantModel r) {
    if (r.hygieneRiskScore < 15.0) {
      return RankingLeagueTier.platinum;
    }
    if (r.hygieneRiskScore < 30.0) {
      return RankingLeagueTier.gold;
    }
    if (r.hygieneRiskScore <= 60.0) {
      return RankingLeagueTier.silver;
    }
    return RankingLeagueTier.bronze;
  }

  String _getTierName(RankingLeagueTier tier) {
    switch (tier) {
      case RankingLeagueTier.bronze:
        return 'Bronze';
      case RankingLeagueTier.silver:
        return 'Silver';
      case RankingLeagueTier.gold:
        return 'Gold';
      case RankingLeagueTier.platinum:
        return 'Platinum';
    }
  }

  Color _getTierColor(RankingLeagueTier tier) {
    switch (tier) {
      case RankingLeagueTier.bronze:
        return const Color(0xFFD97706); // Bronze Amber
      case RankingLeagueTier.silver:
        return const Color(0xFF64748B); // Silver Slate
      case RankingLeagueTier.gold:
        return const Color(0xFFEAB308); // Gold Yellow
      case RankingLeagueTier.platinum:
        return const Color(0xFF0EA5E9); // Platinum Cyan Blue
    }
  }

  Color _getTierBgColor(RankingLeagueTier tier) {
    switch (tier) {
      case RankingLeagueTier.bronze:
        return const Color(0xFFFEF3C7);
      case RankingLeagueTier.silver:
        return const Color(0xFFF1F5F9);
      case RankingLeagueTier.gold:
        return const Color(0xFFFEF9C3);
      case RankingLeagueTier.platinum:
        return const Color(0xFFE0F2FE);
    }
  }

  IconData _getTierIcon(RankingLeagueTier tier) {
    return Icons.military_tech;
  }

  void _showRankingInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ranking Criteria Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navyColor),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Outlets are categorized into tiers based on verified hygiene risk scores and ratings:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 18),
                _buildInfoRow(
                  tierName: 'Bronze Tier',
                  riskTitle: 'High Risk (>60)',
                  subtitle: 'Requires immediate sanitation inspection & action.',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  tierName: 'Silver Tier',
                  riskTitle: 'Moderate Risk (30-60)',
                  subtitle: 'Standard hygiene standards with periodic monitoring.',
                  color: const Color(0xFF64748B),
                  bgColor: const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  tierName: 'Gold Tier',
                  riskTitle: 'Low Risk (15-30)',
                  subtitle: 'High sanitation standards & clean dining environment.',
                  color: const Color(0xFFEAB308),
                  bgColor: const Color(0xFFFEF9C3),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  tierName: 'Platinum Tier',
                  riskTitle: 'Elite Clean (<15)',
                  subtitle: 'Pristine hygiene score with flawless audit record.',
                  color: const Color(0xFF0EA5E9),
                  bgColor: const Color(0xFFE0F2FE),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Got It',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required String tierName,
    required String riskTitle,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.military_tech, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tierName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($riskTitle)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyColor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<RestaurantModel> _getRankedList() {
    final List<RestaurantModel> list = List.from(MockSeedData.restaurants);

    if (_selectedPeriod == 'Week') {
      list.sort((a, b) => (a.hygieneRiskScore - a.violationCount).compareTo(b.hygieneRiskScore - b.violationCount));
    } else {
      list.sort((a, b) => a.hygieneRiskScore.compareTo(b.hygieneRiskScore));
    }

    if (_selectedTierFilter != 'All') {
      return list.where((r) {
        final tier = _getRestaurantTier(r);
        return _getTierName(tier).toLowerCase() == _selectedTierFilter.toLowerCase();
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final rankedList = _getRankedList();

    final RestaurantModel? firstPlace = rankedList.isNotEmpty ? rankedList[0] : null;
    final RestaurantModel? secondPlace = rankedList.length > 1 ? rankedList[1] : null;
    final RestaurantModel? thirdPlace = rankedList.length > 2 ? rankedList[2] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Risk Rankings',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.navyColor),
            tooltip: 'Ranking Criteria Info',
            onPressed: _showRankingInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. TOP PENTAGON LEAGUE BADGES RIBBON HEADER
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLeagueRibbonBadge('Bronze', const Color(0xFFD97706), Icons.military_tech),
                      _buildLeagueRibbonBadge('Silver', const Color(0xFF64748B), Icons.military_tech),
                      _buildLeagueRibbonBadge('Gold', const Color(0xFFEAB308), Icons.military_tech),
                      _buildLeagueRibbonBadge('Platinum', const Color(0xFF0EA5E9), Icons.military_tech),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. SEGMENTED TOGGLE PILL: TODAY vs WEEK
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = 'Today';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'Today' ? const Color(0xFF00A88F) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedPeriod == 'Today'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00A88F).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Today',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _selectedPeriod == 'Today' ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = 'Week';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'Week' ? const Color(0xFF00A88F) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedPeriod == 'Week'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00A88F).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Week',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _selectedPeriod == 'Week' ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. TOP WINNERS PODIUM GRAPHIC (If outlets exist)
            if (rankedList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _celebrationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: CelebrationParticlePainter(
                                  progress: _celebrationController.value,
                                ),
                              );
                            },
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Leaderboard ($_selectedPeriod)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyColor),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A88F).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Top Outlets 🎉',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00A88F)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (secondPlace != null) _buildPodiumColumn(secondPlace, 2, const Color(0xFFF97316), 110),
                                const SizedBox(width: 12),
                                if (firstPlace != null) _buildPodiumColumn(firstPlace, 1, const Color(0xFF7C3AED), 145),
                                const SizedBox(width: 12),
                                if (thirdPlace != null) _buildPodiumColumn(thirdPlace, 3, const Color(0xFFFB923C), 90),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 4. TIER FILTER CHIPS ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Filter Tier:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Platinum', 'Gold', 'Silver', 'Bronze'].map((tier) {
                          final isSelected = _selectedTierFilter == tier;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(tier),
                              selected: isSelected,
                              selectedColor: const Color(0xFF00A88F),
                              backgroundColor: const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF00A88F) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _selectedTierFilter = val ? tier : 'All';
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 5. RANKINGS LIST CARDS OR EMPTY STATE
            if (rankedList.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A88F).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.military_tech_rounded, size: 40, color: Color(0xFF00A88F)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No Outlets in $_selectedTierFilter Tier',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyColor),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Outlets with matching risk scores will automatically appear here once audited.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A88F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedTierFilter = 'All';
                        });
                      },
                      child: const Text('Show All Tiers'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rankedList.length,
                itemBuilder: (context, index) {
                  final restaurant = rankedList[index];
                  final tier = _getRestaurantTier(restaurant);
                  final rankNum = index + 1;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: restaurant);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Rank Number Badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: rankNum <= 3 ? const Color(0xFF00A88F).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  rankNum < 10 ? '0$rankNum' : '$rankNum',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rankNum <= 3 ? const Color(0xFF00A88F) : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Outlet Avatar Image
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: restaurant.imageUrl.isNotEmpty ? NetworkImage(restaurant.imageUrl) : null,
                              child: restaurant.imageUrl.isEmpty
                                  ? Text(restaurant.name[0], style: const TextStyle(fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Outlet Info & Tier Badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getTierBgColor(tier),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _getTierColor(tier).withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(_getTierIcon(tier), size: 14, color: _getTierColor(tier)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getTierName(tier),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getTierColor(tier),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          restaurant.category,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Score & Rating Column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: restaurant.hygieneRiskScore < 30
                                        ? const Color(0xFFECFDF5)
                                        : (restaurant.hygieneRiskScore <= 60 ? const Color(0xFFFEF3C7) : const Color(0xFFFEF2F2)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Score: ${restaurant.hygieneRiskScore.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: restaurant.hygieneRiskScore < 30
                                          ? const Color(0xFF059669)
                                          : (restaurant.hygieneRiskScore <= 60 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final ratingInfo = RestaurantStoreService.getRatingSync(restaurant.id);
                                    return Row(
                                      children: [
                                        Icon(
                                          ratingInfo.hasReviews ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: ratingInfo.hasReviews ? Colors.amber : Colors.grey.shade400,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          ratingInfo.ratingText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: ratingInfo.hasReviews ? Colors.black87 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumColumn(RestaurantModel restaurant, int rank, Color color, double targetHeight) {
    final tier = _getRestaurantTier(restaurant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 28 : 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: restaurant.imageUrl.isNotEmpty ? NetworkImage(restaurant.imageUrl) : null,
                child: restaurant.imageUrl.isEmpty
                    ? Text(
                        restaurant.name[0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: rank == 1 ? 18 : 14,
                          color: color,
                        ),
                      )
                    : null,
              ),
            ),
            if (rank == 1)
              const Positioned(
                top: -16,
                child: Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        SizedBox(
          width: 85,
          child: Text(
            restaurant.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.navyColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _getTierBgColor(tier),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _getTierName(tier),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getTierColor(tier)),
          ),
        ),
        const SizedBox(height: 6),

        Container(
          width: 75,
          height: targetHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueRibbonBadge(String name, Color color, IconData icon) {
    final isSelected = _selectedTierFilter.toLowerCase() == name.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTierFilter = isSelected ? 'All' : name;
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : color,
                width: isSelected ? 2.5 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? color.withValues(alpha: 0.45) : color.withValues(alpha: 0.18),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF00A88F) : AppTheme.navyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class CelebrationParticlePainter extends CustomPainter {
  final double progress;

  CelebrationParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFF59E0B), // Gold
      const Color(0xFFEF4444), // Crimson
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
    ];

    // Seeded particles with individual speed multipliers and initial offsets
    final particles = [
      // Left side (#2 winner)
      _Particle(0.18, 0.05, 4.5, 0, speed: 0.8),
      _Particle(0.24, 0.35, 3.8, 1, speed: 1.1),
      _Particle(0.14, 0.65, 5.2, 2, speed: 0.9),
      _Particle(0.28, 0.85, 4.0, 3, speed: 1.2),

      // Center (#1 winner podium area)
      _Particle(0.44, 0.02, 6.5, 0, speed: 1.0),
      _Particle(0.52, 0.22, 5.0, 1, speed: 0.85),
      _Particle(0.48, 0.45, 5.5, 2, speed: 1.15),
      _Particle(0.56, 0.68, 4.2, 4, speed: 0.95),
      _Particle(0.50, 0.88, 4.8, 5, speed: 1.05),

      // Right side (#3 winner)
      _Particle(0.72, 0.15, 4.5, 3, speed: 1.1),
      _Particle(0.80, 0.48, 4.0, 4, speed: 0.85),
      _Particle(0.85, 0.78, 5.0, 0, speed: 1.0),
    ];

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final color = colors[p.colorIndex % colors.length];

      // Smooth continuous falling progress wrapping calculation
      final rawY = (p.y + (progress * p.speed)) % 1.0;
      final dx = size.width * (p.x + 0.025 * math.sin((progress * 2 * math.pi * p.speed) + i));
      final dy = size.height * rawY;

      // Smooth top/bottom fade curve (fades in smoothly over top 25% and fades out over bottom 25%)
      final fadeRange = size.height * 0.25;
      final topFade = (dy / fadeRange).clamp(0.0, 1.0);
      final bottomFade = ((size.height - dy) / fadeRange).clamp(0.0, 1.0);
      final alphaMultiplier = Curves.easeInOut.transform(topFade * bottomFade);

      if (alphaMultiplier <= 0.01) continue; // Skip rendering when invisible

      final paint = Paint()
        ..color = color.withValues(alpha: (0.75 + 0.25 * math.sin((progress * 3 * math.pi) + i)) * alphaMultiplier)
        ..style = PaintingStyle.fill;

      // Draw smooth particle shapes: circle, rotating confetti ribbon, diamond sparkle
      if (i % 3 == 0) {
        canvas.drawCircle(Offset(dx, dy), p.radius, paint);
      } else if (i % 3 == 1) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate((progress * 3 * math.pi * p.speed) + i);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.radius * 2.2, height: p.radius * 0.9), paint);
        canvas.restore();
      } else {
        final path = Path();
        path.moveTo(dx, dy - p.radius * 1.3);
        path.lineTo(dx + p.radius * 1.1, dy);
        path.lineTo(dx, dy + p.radius * 1.3);
        path.lineTo(dx - p.radius * 1.1, dy);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CelebrationParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final int colorIndex;
  final double speed;
  _Particle(this.x, this.y, this.radius, this.colorIndex, {this.speed = 1.0});
}
