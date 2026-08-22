import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
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

class _RiskRankingListScreenState extends State<RiskRankingListScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'Today'; // 'Today' or 'Week'
  String _selectedTierFilter = 'All';

  late AnimationController _celebrationController;
  late AnimationController _pillarController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pillarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pillarController.forward();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pillarController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                    Expanded(
                      child: Text(
                        'Ranking Criteria Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppTheme.navyColor),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white60 : Colors.grey, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Outlets are categorized into tiers based on verified hygiene risk scores and ratings:',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 18),
                _buildInfoRow(
                  tierName: 'Bronze Tier',
                  riskTitle: 'High Risk (>60)',
                  subtitle: 'Requires immediate sanitation inspection & action.',
                  color: const Color(0xFFD97706),
                  bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  tierName: 'Silver Tier',
                  riskTitle: 'Moderate Risk (30-60)',
                  subtitle: 'Standard hygiene standards with periodic monitoring.',
                  color: const Color(0xFF64748B),
                  bgColor: isDark ? const Color(0xFF282828).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  tierName: 'Gold Tier',
                  riskTitle: 'Low Risk (15-30)',
                  subtitle: 'High sanitation standards & clean dining environment.',
                  color: const Color(0xFFEAB308),
                  bgColor: isDark ? const Color(0xFF713F12).withValues(alpha: 0.35) : const Color(0xFFFEF9C3),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  tierName: 'Platinum Tier',
                  riskTitle: 'Elite Clean (<15)',
                  subtitle: 'Pristine hygiene score with flawless audit record.',
                  color: const Color(0xFF0EA5E9),
                  bgColor: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFE0F2FE),
                  isDark: isDark,
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
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : AppTheme.navyColor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<RestaurantModel> _getRankedList() {
    final List<RestaurantModel> list = List.from(RestaurantStoreService.restaurantsNotifier.value);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankedList = _getRankedList();

    final RestaurantModel? firstPlace = rankedList.isNotEmpty ? rankedList[0] : null;
    final RestaurantModel? secondPlace = rankedList.length > 1 ? rankedList[1] : null;
    final RestaurantModel? thirdPlace = rankedList.length > 2 ? rankedList[2] : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Risk Rankings',
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: isDark ? Colors.white : AppTheme.navyColor),
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
                    color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLeagueRibbonBadge('Bronze', const Color(0xFFD97706), Icons.military_tech, isDark),
                      _buildLeagueRibbonBadge('Silver', const Color(0xFF64748B), Icons.military_tech, isDark),
                      _buildLeagueRibbonBadge('Gold', const Color(0xFFEAB308), Icons.military_tech, isDark),
                      _buildLeagueRibbonBadge('Platinum', const Color(0xFF0EA5E9), Icons.military_tech, isDark),
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
                  color: isDark ? const Color(0xFF282828) : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedPeriod != 'Today') {
                            setState(() {
                              _selectedPeriod = 'Today';
                            });
                            _pillarController.forward(from: 0.0);
                          }
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
                              color: _selectedPeriod == 'Today' ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedPeriod != 'Week') {
                            setState(() {
                              _selectedPeriod = 'Week';
                            });
                            _pillarController.forward(from: 0.0);
                          }
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
                              color: _selectedPeriod == 'Week' ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
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
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.navyColor),
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
                            AnimatedBuilder(
                              animation: Listenable.merge([_celebrationController, _pillarController]),
                              builder: (context, _) {
                                final double p1Anim = CurvedAnimation(
                                  parent: _pillarController,
                                  curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
                                ).value;

                                final double p2Anim = CurvedAnimation(
                                  parent: _pillarController,
                                  curve: const Interval(0.08, 0.88, curve: Curves.easeOutBack),
                                ).value;

                                final double p3Anim = CurvedAnimation(
                                  parent: _pillarController,
                                  curve: const Interval(0.0, 0.78, curve: Curves.easeOutBack),
                                ).value;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (secondPlace != null)
                                      _buildPodiumColumn(secondPlace, 2, 115, isDark, p2Anim),
                                    const SizedBox(width: 10),
                                    if (firstPlace != null)
                                      _buildPodiumColumn(firstPlace, 1, 155, isDark, p1Anim),
                                    const SizedBox(width: 10),
                                    if (thirdPlace != null)
                                      _buildPodiumColumn(thirdPlace, 3, 92, isDark, p3Anim),
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
              ),

            const SizedBox(height: 16),

            // 4. TIER FILTER CHIPS ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filter Tier:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppTheme.navyColor),
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
                              backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF00A88F) : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _selectedTierFilter = val ? tier : 'All';
                                });
                                _pillarController.forward(from: 0.0);
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
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.navyColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Outlets with matching risk scores will automatically appear here once audited.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey),
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
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                                color: rankNum <= 3
                                    ? const Color(0xFF00A88F).withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  rankNum < 10 ? '0$rankNum' : '$rankNum',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rankNum <= 3 ? const Color(0xFF00A88F) : (isDark ? Colors.white70 : Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Outlet Avatar Image
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey.shade200,
                              backgroundImage: restaurant.imageUrl.isNotEmpty ? NetworkImage(restaurant.imageUrl) : null,
                              child: restaurant.imageUrl.isEmpty
                                  ? Text(restaurant.name[0], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))
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
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? _getTierColor(tier).withValues(alpha: 0.2) : _getTierBgColor(tier),
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
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade500),
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
                                        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                                        : (restaurant.hygieneRiskScore <= 60
                                            ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7))
                                            : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2))),
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
                                    final ratingInfo = RestaurantStoreService.getRatingSync(restaurant.id, restaurantName: restaurant.name);
                                    return Row(
                                      children: [
                                        Icon(
                                          ratingInfo.hasReviews ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: ratingInfo.hasReviews ? Colors.amber : (isDark ? Colors.white24 : Colors.grey.shade400),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          ratingInfo.ratingText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: ratingInfo.hasReviews ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.grey.shade600),
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

  Widget _buildPodiumColumn(
    RestaurantModel restaurant,
    int rank,
    double targetHeight,
    bool isDark,
    double animProgress,
  ) {
    final tier = _getRestaurantTier(restaurant);
    final double currentHeight = (targetHeight * animProgress).clamp(12.0, targetHeight);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: restaurant);
      },
      child: Transform.translate(
        offset: Offset(0, (1.0 - animProgress) * 45),
        child: Opacity(
          opacity: animProgress.clamp(0.0, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. AVATAR STACK: Glory Light with Wings & 3D Golden Halo (Rank 1), 3D Silver Halo (Rank 2), Clean (Rank 3)
              if (rank == 1)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Shimmering Golden Angel Wings, Floating 3D Golden Halo, & Sparkles
                    CustomPaint(
                      size: const Size(160, 100),
                      painter: GoldenWingsPainter(shimmer: _celebrationController.value),
                    ),
                    // Avatar with Gold Ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFF7D6),
                            Color(0xFFFFD700),
                            Color(0xFFF59E0B),
                            Color(0xFFB45309)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.65),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isDark ? const Color(0xFF242424) : Colors.grey.shade100,
                        backgroundImage: restaurant.imageUrl.isNotEmpty
                            ? NetworkImage(restaurant.imageUrl)
                            : null,
                        child: restaurant.imageUrl.isEmpty
                            ? Text(
                                restaurant.name[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFFD97706),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                )
              else if (rank == 2)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Floating 3D Silver Halo & Silver Sparkles
                    CustomPaint(
                      size: const Size(90, 75),
                      painter: SilverHaloPainter(shimmer: _celebrationController.value),
                    ),
                    // Avatar with Silver Chrome Ring
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFE2E8F0),
                            Color(0xFF94A3B8),
                            Color(0xFF475569)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 23,
                        backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey.shade200,
                        backgroundImage: restaurant.imageUrl.isNotEmpty
                            ? NetworkImage(restaurant.imageUrl)
                            : null,
                        child: restaurant.imageUrl.isEmpty
                            ? Text(
                                restaurant.name[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF475569),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                )
              else
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Rank 3: Remain Nothing (Clean avatar, no wings, no glory light)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFEDD5),
                            Color(0xFFFB923C),
                            Color(0xFFC2410C),
                            Color(0xFF7C2D12)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9A3412).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey.shade200,
                        backgroundImage: restaurant.imageUrl.isNotEmpty
                            ? NetworkImage(restaurant.imageUrl)
                            : null,
                        child: restaurant.imageUrl.isEmpty
                            ? Text(
                                restaurant.name[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF9A3412),
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Small Bronze Dot
                    Positioned(
                      top: -10,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFCD7F32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          color: Color(0xFFFFEDD5),
                          size: 8,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 6),

              // Restaurant Name
              SizedBox(
                width: 86,
                child: Text(
                  restaurant.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isDark ? Colors.white : AppTheme.navyColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),

              // Tier Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark
                      ? _getTierColor(tier).withValues(alpha: 0.2)
                      : _getTierBgColor(tier),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getTierName(tier),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getTierColor(tier),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 2. METALLIC PODIUM PILLAR
              if (rank == 1)
                // Gold Brush Color Pillar
                Container(
                  width: 82,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF9DB), // Gold brushed reflect highlight
                        Color(0xFFFFE082), // Soft gold
                        Color(0xFFFFD700), // Pure golden yellow
                        Color(0xFFF59E0B), // Vibrant amber gold
                        Color(0xFFD97706), // Rich dark gold
                        Color(0xFF92400E), // Gold brush shade
                      ],
                      stops: [0.0, 0.18, 0.42, 0.68, 0.88, 1.0],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border.all(color: const Color(0xFFFFF3B0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFB45309), width: 1.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF78350F),
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  offset: const Offset(0, 1.5),
                                  blurRadius: 2,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, -1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (rank == 2)
                // Silver Metallic Color Pillar
                Container(
                  width: 74,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF), // Chrome mirror reflect
                        Color(0xFFF1F5F9), // Pure silver
                        Color(0xFFCBD5E1), // Metallic steel
                        Color(0xFF94A3B8), // Brushed slate silver
                        Color(0xFF475569), // Dark silver shadow
                      ],
                      stops: [0.0, 0.22, 0.5, 0.78, 1.0],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF64748B), width: 1.2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF334155),
                              shadows: [
                                const Shadow(
                                  color: Colors.white,
                                  offset: Offset(0, 1.2),
                                  blurRadius: 2,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, -1),
                                  blurRadius: 1.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Bronze Brown Color Pillar
                Container(
                  width: 70,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFEDD5), // Bronze brushed highlight
                        Color(0xFFFB923C), // Warm copper bronze
                        Color(0xFFEA580C), // Deep metallic bronze
                        Color(0xFFC2410C), // Rust bronze
                        Color(0xFF7C2D12), // Dark bronze brown base
                      ],
                      stops: [0.0, 0.22, 0.52, 0.78, 1.0],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C2D12).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF9A3412), width: 1.2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF451A03),
                              shadows: [
                                const Shadow(
                                  color: Color(0xFFFFEDD5),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, -1),
                                  blurRadius: 1.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueRibbonBadge(String name, Color color, IconData icon, bool isDark) {
    final isSelected = _selectedTierFilter.toLowerCase() == name.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTierFilter = isSelected ? 'All' : name;
        });
        _pillarController.forward(from: 0.0);
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
              color: isSelected ? const Color(0xFF00A88F) : (isDark ? Colors.white : AppTheme.navyColor),
            ),
          ),
        ],
      ),
    );
  }
}

class GoldenWingsPainter extends CustomPainter {
  final double shimmer; // 0.0 to 1.0

  GoldenWingsPainter({this.shimmer = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);

    // 1. Radiant Ambient Glory Glow behind Avatar & Wings
    final glowPulse = 0.35 + 0.15 * math.sin(shimmer * math.pi * 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: (glowPulse * 0.7).clamp(0.0, 1.0)),
          const Color(0xFFF59E0B).withValues(alpha: (glowPulse * 0.45).clamp(0.0, 1.0)),
          const Color(0xFFB45309).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.48));

    canvas.drawCircle(center, size.width * 0.48, glowPaint);

    // 2. WINGS GEOMETRY - Pure Radiant Gold Color
    final wingOutlinePaint = Paint()
      ..color = const Color(0xFFB45309) // Deep warm gold border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final featherLinePaint = Paint()
      ..color = const Color(0xFFD97706) // Rich amber gold feather scallop lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final wingHighlightPaint = Paint()
      ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.85) // Specular gold shine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final wingFillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFBEB), // Bright light-gold highlight
          Color(0xFFFFF3B0), // Champagne gold
          Color(0xFFFFD700), // Pure vibrant yellow gold
          Color(0xFFF59E0B), // Warm amber gold
          Color(0xFFD97706), // Rich deep gold shading
          Color(0xFF92400E), // Base gold shadow
        ],
        stops: [0.0, 0.15, 0.38, 0.62, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw Left Wing Path
    final leftWingPath = Path();
    leftWingPath.moveTo(center.dx - 22, center.dy + 8);
    // Smooth top wing ridge sweeping upward and outward to top primary feather
    leftWingPath.cubicTo(
      center.dx - 36, center.dy - 12,
      center.dx - 52, center.dy - 22,
      center.dx - 68, center.dy - 14,
    );
    // Feather 1 (Top wingtip)
    leftWingPath.cubicTo(
      center.dx - 62, center.dy - 4,
      center.dx - 54, center.dy + 2,
      center.dx - 48, center.dy + 6,
    );
    // Feather 2
    leftWingPath.cubicTo(
      center.dx - 58, center.dy + 8,
      center.dx - 64, center.dy + 4,
      center.dx - 66, center.dy + 10,
    );
    leftWingPath.cubicTo(
      center.dx - 58, center.dy + 16,
      center.dx - 48, center.dy + 18,
      center.dx - 42, center.dy + 18,
    );
    // Feather 3
    leftWingPath.cubicTo(
      center.dx - 50, center.dy + 22,
      center.dx - 56, center.dy + 20,
      center.dx - 58, center.dy + 26,
    );
    leftWingPath.cubicTo(
      center.dx - 50, center.dy + 30,
      center.dx - 40, center.dy + 30,
      center.dx - 34, center.dy + 28,
    );
    // Feather 4 (Bottom-most rounded feather)
    leftWingPath.cubicTo(
      center.dx - 40, center.dy + 32,
      center.dx - 44, center.dy + 34,
      center.dx - 44, center.dy + 38,
    );
    leftWingPath.cubicTo(
      center.dx - 36, center.dy + 40,
      center.dx - 28, center.dy + 34,
      center.dx - 20, center.dy + 26,
    );
    leftWingPath.close();

    // Top ridge highlight path
    final ridgeHighlight = Path();
    ridgeHighlight.moveTo(center.dx - 28, center.dy + 4);
    ridgeHighlight.cubicTo(
      center.dx - 40, center.dy - 8,
      center.dx - 52, center.dy - 18,
      center.dx - 64, center.dy - 12,
    );

    // Internal scallop feather layer curves
    final scallopPath1 = Path();
    scallopPath1.moveTo(center.dx - 38, center.dy + 4);
    scallopPath1.cubicTo(
      center.dx - 44, center.dy + 10,
      center.dx - 46, center.dy + 16,
      center.dx - 34, center.dy + 20,
    );

    final scallopPath2 = Path();
    scallopPath2.moveTo(center.dx - 48, center.dy + 12);
    scallopPath2.cubicTo(
      center.dx - 54, center.dy + 16,
      center.dx - 54, center.dy + 22,
      center.dx - 44, center.dy + 24,
    );

    // Draw Left Wing
    canvas.drawPath(leftWingPath, wingFillPaint);
    canvas.drawPath(leftWingPath, wingOutlinePaint);
    canvas.drawPath(ridgeHighlight, wingHighlightPaint);
    canvas.drawPath(scallopPath1, featherLinePaint);
    canvas.drawPath(scallopPath2, featherLinePaint);

    // Draw Right Wing (Perfect Symmetrical Reflection)
    canvas.save();
    canvas.translate(center.dx, 0);
    canvas.scale(-1, 1);
    canvas.translate(-center.dx, 0);
    canvas.drawPath(leftWingPath, wingFillPaint);
    canvas.drawPath(leftWingPath, wingOutlinePaint);
    canvas.drawPath(ridgeHighlight, wingHighlightPaint);
    canvas.drawPath(scallopPath1, featherLinePaint);
    canvas.drawPath(scallopPath2, featherLinePaint);
    canvas.restore();

    // 3. FLOATING 3D GOLDEN HALO RING (Matching top-center reference)
    final haloCenter = Offset(center.dx, center.dy - 44);

    // Ambient Halo Glow
    final haloGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(
            alpha: (0.6 + 0.2 * math.sin(shimmer * math.pi * 2)).clamp(0.0, 1.0),
          ),
          const Color(0xFFF59E0B).withValues(alpha: 0.25),
          const Color(0xFFFFD700).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: haloCenter, radius: 36));

    canvas.drawCircle(haloCenter, 36, haloGlowPaint);

    // Halo Torus Ring Path (Outer oval minus inner oval)
    final outerHalo = Path()
      ..addOval(Rect.fromCenter(center: haloCenter, width: 44, height: 16));
    final innerHalo = Path()
      ..addOval(Rect.fromCenter(center: haloCenter, width: 28, height: 9));
    final ringPath = Path.combine(PathOperation.difference, outerHalo, innerHalo);

    final haloFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFDE7), // Light yellow highlight
          Color(0xFFFFEE58), // Bright gold
          Color(0xFFFFC107), // Amber gold
          Color(0xFFFFA000), // Deep warm gold
          Color(0xFFFF8F00), // Shaded gold
        ],
        stops: [0.0, 0.25, 0.55, 0.8, 1.0],
      ).createShader(Rect.fromCenter(center: haloCenter, width: 44, height: 16))
      ..style = PaintingStyle.fill;

    final haloStroke = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawPath(ringPath, haloFill);
    canvas.drawPath(outerHalo, haloStroke);
    canvas.drawPath(innerHalo, haloStroke);

    // Specular Shine Arc on Top Edge of Halo
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final shineArc = Path();
    shineArc.addArc(
      Rect.fromCenter(center: haloCenter, width: 40, height: 13),
      -math.pi * 0.85,
      math.pi * 0.7,
    );
    canvas.drawPath(shineArc, shinePaint);

    // 4. FLOATING SPARKLE STARS & PARTICLES (✦ in gold & white)
    final starAlpha = 0.55 + 0.45 * math.sin(shimmer * math.pi * 2);
    _drawSparkle(canvas, Offset(haloCenter.dx - 26, haloCenter.dy - 6), 4.5, const Color(0xFFFFF7D6), starAlpha);
    _drawSparkle(canvas, Offset(haloCenter.dx + 25, haloCenter.dy - 7), 5.0, const Color(0xFFFFF7D6), starAlpha * 0.9);
    _drawSparkle(canvas, Offset(haloCenter.dx - 18, haloCenter.dy + 9), 3.5, const Color(0xFFFFD700), starAlpha * 0.85);
    _drawSparkle(canvas, Offset(haloCenter.dx + 20, haloCenter.dy + 8), 4.0, const Color(0xFFFFD700), starAlpha);
    _drawSparkle(canvas, Offset(center.dx - 64, center.dy - 20), 4.2, const Color(0xFFFFD700), starAlpha * 0.85);
    _drawSparkle(canvas, Offset(center.dx + 64, center.dy - 20), 4.2, const Color(0xFFFFD700), starAlpha * 0.85);

    // Glowing Dust Specks
    final speckPaint = Paint()..style = PaintingStyle.fill;
    final specks = [
      Offset(haloCenter.dx - 32, haloCenter.dy + 2),
      Offset(haloCenter.dx + 30, haloCenter.dy - 2),
      Offset(haloCenter.dx - 10, haloCenter.dy - 12),
      Offset(haloCenter.dx + 12, haloCenter.dy - 12),
      Offset(haloCenter.dx + 4, haloCenter.dy + 12),
    ];
    for (int i = 0; i < specks.length; i++) {
      final p = specks[i];
      final a = ((math.sin((shimmer * math.pi * 2) + i) + 1) / 2 * 0.75 + 0.25).clamp(0.0, 1.0);
      speckPaint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(p, 1.5, speckPaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset pos, double size, Color color, double alpha) {
    if (alpha <= 0.05) return;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(pos.dx, pos.dy - size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - size);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawCircle(pos, size * 0.3, Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)));
  }

  @override
  bool shouldRepaint(covariant GoldenWingsPainter oldDelegate) {
    return oldDelegate.shimmer != shimmer;
  }
}

class SilverHaloPainter extends CustomPainter {
  final double shimmer;

  SilverHaloPainter({this.shimmer = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final haloCenter = Offset(center.dx, center.dy - 38);

    // 1. Soft Ambient Silver/Cyan Halo Glow
    final glowPulse = 0.35 + 0.15 * math.sin(shimmer * math.pi * 2);
    final haloGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: (glowPulse * 0.6).clamp(0.0, 1.0)),
          const Color(0xFFCBD5E1).withValues(alpha: (glowPulse * 0.4).clamp(0.0, 1.0)),
          const Color(0xFF94A3B8).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: haloCenter, radius: 28));

    canvas.drawCircle(haloCenter, 28, haloGlowPaint);

    // 2. Silver Torus Ring Path
    final outerHalo = Path()
      ..addOval(Rect.fromCenter(center: haloCenter, width: 38, height: 14));
    final innerHalo = Path()
      ..addOval(Rect.fromCenter(center: haloCenter, width: 24, height: 8));
    final ringPath = Path.combine(PathOperation.difference, outerHalo, innerHalo);

    final haloFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Color(0xFFF1F5F9),
          Color(0xFFCBD5E1),
          Color(0xFF94A3B8),
        ],
      ).createShader(Rect.fromCenter(center: haloCenter, width: 38, height: 14))
      ..style = PaintingStyle.fill;

    final haloStroke = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(ringPath, haloFill);
    canvas.drawPath(outerHalo, haloStroke);
    canvas.drawPath(innerHalo, haloStroke);

    // Specular Shine Arc on Top Edge
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final shineArc = Path();
    shineArc.addArc(
      Rect.fromCenter(center: haloCenter, width: 34, height: 11),
      -math.pi * 0.85,
      math.pi * 0.7,
    );
    canvas.drawPath(shineArc, shinePaint);

    // Sparkle Stars
    final starAlpha = 0.5 + 0.45 * math.sin(shimmer * math.pi * 2);
    _drawSparkle(canvas, Offset(haloCenter.dx - 22, haloCenter.dy - 4), 3.8, const Color(0xFFE2E8F0), starAlpha);
    _drawSparkle(canvas, Offset(haloCenter.dx + 20, haloCenter.dy - 5), 4.0, const Color(0xFF38BDF8), starAlpha * 0.85);
    _drawSparkle(canvas, Offset(haloCenter.dx - 12, haloCenter.dy + 7), 3.0, Colors.white, starAlpha);
    _drawSparkle(canvas, Offset(haloCenter.dx + 15, haloCenter.dy + 6), 3.2, const Color(0xFFE2E8F0), starAlpha * 0.9);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double size, Color color, double alpha) {
    if (alpha <= 0.05) return;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(pos.dx, pos.dy - size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - size);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawCircle(pos, size * 0.3, Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)));
  }

  @override
  bool shouldRepaint(covariant SilverHaloPainter oldDelegate) {
    return oldDelegate.shimmer != shimmer;
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
