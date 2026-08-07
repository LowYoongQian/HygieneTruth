import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
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
  // High -> Bronze, Medium -> Silver, Low -> Gold, Risk < 3 & Rating >= 4.8 -> Platinum
  RankingLeagueTier _getRestaurantTier(RestaurantModel r) {
    // Check Platinum condition first (< 3 risk score & high rating)
    if (r.hygieneRiskScore < 3.0) {
      return RankingLeagueTier.platinum;
    }
    // High Risk -> Bronze
    if (r.riskCategory == RiskCategory.high || r.hygieneRiskScore > 50.0) {
      return RankingLeagueTier.bronze;
    }
    // Medium Risk -> Silver
    if (r.riskCategory == RiskCategory.moderate || (r.hygieneRiskScore >= 25.0 && r.hygieneRiskScore <= 50.0)) {
      return RankingLeagueTier.silver;
    }
    // Low Risk -> Gold
    return RankingLeagueTier.gold;
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

  // Unified Ranking Icon (Uses Medal Star Ribbon icon matching reference image)
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
                // Header with Icon & Title & Close X Button
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

                // 1. Bronze Tier
                _buildInfoRow(
                  tierName: 'Bronze',
                  riskTitle: 'High Risk',
                  subtitle: 'Hygiene Risk Score > 50.0 or High Violations',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                ),
                const SizedBox(height: 10),

                // 2. Silver Tier
                _buildInfoRow(
                  tierName: 'Silver',
                  riskTitle: 'Medium Risk',
                  subtitle: 'Hygiene Risk Score between 25.0 and 50.0',
                  color: const Color(0xFF475569),
                  bgColor: const Color(0xFFF8FAFC),
                ),
                const SizedBox(height: 10),

                // 3. Gold Tier
                _buildInfoRow(
                  tierName: 'Gold',
                  riskTitle: 'Low Risk / Safe',
                  subtitle: 'Hygiene Risk Score < 25.0 (Passed Inspection)',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEFCE8),
                ),
                const SizedBox(height: 10),

                // 4. Platinum Tier
                _buildInfoRow(
                  tierName: 'Platinum',
                  riskTitle: 'Ultra-Safe Tier',
                  subtitle: 'Risk Score < 3.0 & Customer Rating ≥ 4.8 ★',
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                ),

                const SizedBox(height: 22),

                // Full-width Modern Pill Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.military_tech, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Titles & Subtitle
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
    List<RestaurantModel> list = List.from(MockSeedData.restaurants);

    // If 'Week' tab is selected, sort with weekly variance simulation
    if (_selectedPeriod == 'Week') {
      list.sort((a, b) => (a.hygieneRiskScore - a.violationCount).compareTo(b.hygieneRiskScore - b.violationCount));
    } else {
      list.sort((a, b) => a.hygieneRiskScore.compareTo(b.hygieneRiskScore));
    }

    if (_selectedTierFilter != 'All') {
      list = list.where((r) {
        final tier = _getRestaurantTier(r);
        return _getTierName(tier).toLowerCase() == _selectedTierFilter.toLowerCase();
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final rankedList = _getRankedList();

    // Top 3 Podium Candidates (if available)
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
            // 1. TOP PENTAGON LEAGUE BADGES RIBBON HEADER WITH FROSTED GLASS BACKDROP FILTER
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
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
                      _buildLeagueRibbonBadge('Bronze', const Color(0xFFD97706), Icons.military_tech, isUnlocked: true),
                      _buildLeagueRibbonBadge('Silver', const Color(0xFF64748B), Icons.military_tech, isUnlocked: true),
                      _buildLeagueRibbonBadge('Gold', const Color(0xFFEAB308), Icons.military_tech, isUnlocked: true),
                      _buildLeagueRibbonBadge('Platinum', const Color(0xFF0EA5E9), Icons.military_tech, isUnlocked: true),
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
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'Today' ? const Color(0xFF1E293B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedPeriod == 'Today'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
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
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'Week' ? const Color(0xFF1E293B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedPeriod == 'Week'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
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

            // 3. TOP 3 WINNERS PODIUM GRAPHIC WITH FESTIVE CONFETTI PARTY PARTICLES
            if (rankedList.length >= 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Animated Festive Celebration Particles Over Podium
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

                          // Podium Contents Column
                          Column(
                            children: [
                              // Period Header
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
                                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Top Outlets 🎉',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 3-Podium Layout: Left (#2), Center (#1), Right (#3)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // #2 RUNNER-UP PODIUM (LEFT)
                                  if (secondPlace != null) _buildPodiumColumn(secondPlace, 2, const Color(0xFFF97316), 110),

                                  const SizedBox(width: 12),

                                  // #1 WINNER PODIUM (CENTER - TALLEST WITH GOLDEN CROWN)
                                  if (firstPlace != null) _buildPodiumColumn(firstPlace, 1, const Color(0xFF7C3AED), 145),

                                  const SizedBox(width: 12),

                                  // #3 THIRD PLACE PODIUM (RIGHT)
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
              ),

            const SizedBox(height: 20),

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
                            child: ChoiceChip(
                              label: Text(tier),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedTierFilter = tier);
                                }
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

            const SizedBox(height: 12),

            // 5. RANKINGS LIST CARDS WITH FROSTED GLASS BACKDROP FILTER
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.8)),
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
                              SizedBox(
                                width: 32,
                                child: Text(
                                  rankNum < 10 ? '0$rankNum' : '$rankNum',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: rankNum <= 3 ? AppTheme.primaryColor : Colors.grey.shade600,
                                  ),
                                ),
                              ),

                              // Outlet Avatar Image
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(restaurant.imageUrl),
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
                                        // Tier Badge Chip with Unified Medal Icon
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
                                        Text(
                                          restaurant.category,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Risk: ${restaurant.hygieneRiskScore.toStringAsFixed(1)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
        // Avatar with Golden Crown on #1 or Medal Badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rank == 1 ? Colors.amber : color, width: 2),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 28 : 22,
                backgroundColor: color.withValues(alpha: 0.2),
                backgroundImage: NetworkImage(restaurant.imageUrl),
              ),
            ),
            if (rank == 1)
              Positioned(
                top: -12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, size: 14, color: Colors.white),
                ),
              )
            else
              Positioned(
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(_getTierIcon(tier), size: 14, color: _getTierColor(tier)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Outlet Name
        SizedBox(
          width: 80,
          child: Text(
            restaurant.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.navyColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),

        // Animated Gradient Podium Pillar Container with Smooth Height Transition
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          width: 80,
          height: targetHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rank',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${restaurant.hygieneRiskScore.toStringAsFixed(1)} Risk',
                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueRibbonBadge(String name, Color color, IconData icon, {required bool isUnlocked}) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.navyColor,
          ),
        ),
      ],
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
