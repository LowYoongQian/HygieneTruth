import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/wireframe_box.dart';
import '../../risk/widgets/risk_score_gauge.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isSaved = true; // Toggle state for saved banner icon

  final _newCommentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  int _selectedRating = 5;

  final List<Map<String, String>> _reviews = [
    {
      'userName': 'Ahmad Razak',
      'date': '2026-07-28',
      'stars': '5',
      'comment': 'Very clean dining area and kitchen! Food served hot and fresh. Staff wore hairnets and gloves properly.',
    },
    {
      'userName': 'Siti Sarah',
      'date': '2026-07-22',
      'stars': '4',
      'comment': 'Great noodles! Tables were wiped clean quickly after customers left. Passed hygiene inspection well.',
    },
    {
      'userName': 'Kevin Tan',
      'date': '2026-07-15',
      'stars': '5',
      'comment': 'Spacious and hygienic environment. Grease traps and floors look well maintained.',
    },
  ];

  @override
  void dispose() {
    _newCommentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final commentText = _newCommentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment before submitting.')),
      );
      return;
    }

    final currentUser = CustomerStoreService.currentCustomer;
    final userName = currentUser?.name ?? 'Verified Customer';

    setState(() {
      _reviews.insert(0, {
        'userName': userName,
        'date': DateTime.now().toString().split(' ')[0],
        'stars': '$_selectedRating',
        'comment': commentText,
      });
      _newCommentController.clear();
      _selectedRating = 5;
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment published successfully!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAddReviewDialog() {
    final commentCtrl = TextEditingController();
    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Leave a Review',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Rating:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedStars = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Share your dining hygiene experience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  onPressed: () {
                    if (commentCtrl.text.trim().isNotEmpty) {
                      final currentUser = CustomerStoreService.currentCustomer;
                      final userName = currentUser?.name ?? 'Verified Customer';

                      setState(() {
                        _reviews.insert(0, {
                          'userName': userName,
                          'date': DateTime.now().toString().split(' ')[0],
                          'stars': '$selectedStars',
                          'comment': commentCtrl.text.trim(),
                        });
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review submitted successfully!'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: Colors.red),
                title: const Text('Report Hygiene Issue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: const Text('Submit a formal report to health inspectors'),
                onTap: () {
                  Navigator.pop(ctx);
                  final restaurant = ModalRoute.of(context)?.settings.arguments as RestaurantModel? ?? MockSeedData.restaurants.first;
                  Navigator.pushNamed(context, AppRoutes.submitComplaint, arguments: restaurant);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppTheme.navyColor),
                title: const Text('Share Restaurant Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restaurant link copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInputCard() {
    final currentUser = CustomerStoreService.currentCustomer;
    final userName = currentUser?.name ?? 'Verified Customer';
    final avatarUrl = currentUser?.avatarUrl ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light grey input box background matching reference image
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Account Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Comment TextField Input
              Expanded(
                child: TextField(
                  controller: _newCommentController,
                  focusNode: _commentFocusNode,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 6),
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Star Rating Picker
              Row(
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starVal;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        starVal <= _selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ),

              // Green Pill Submit Button matching reference image
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857), // Forest green submit button matching reference image
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _submitComment,
                child: const Text(
                  'Submit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = ModalRoute.of(context)?.settings.arguments as RestaurantModel? ?? (MockSeedData.restaurants.isNotEmpty ? MockSeedData.restaurants.first : null);

    if (restaurant == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Restaurant Details'),
        body: Center(child: Text('No restaurant data selected')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: restaurant.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showReportOptionsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outlet Image with Banner Icons
            Stack(
              children: [
                const WireframeBox(
                  height: 200,
                  label: 'Outlet Image',
                  icon: Icons.storefront,
                ),
                // Approved Status Badge Below Image Container
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusBadge.fromStatus('Approved'),
                ),
                // Safe Status Icon Only (below approved badge)
                Positioned(
                  top: 48,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Saved Banner Icon at Far Right Top
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSaved = !_isSaved;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isSaved ? 'Restaurant saved to bookmarks!' : 'Restaurant removed from bookmarks.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? AppTheme.primaryColor : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Restaurant Title & Category
            Text(
              restaurant.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.category,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Location Row
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    restaurant.address,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rating System Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return const Icon(Icons.star, color: Colors.amber, size: 18);
                    }),
                  ),
                  const Spacer(),
                  Text(
                    '4.8 / 5.0 (${_reviews.length} reviews)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map Section (Combining Google Map Pinned Locations + Heatmap)
            const WireframeBox(
              height: 180,
              label: 'GPS: 3.1466, 101.6958',
              sublabel: 'Tap map below',
            ),
            const SizedBox(height: 20),

            // Customer Reviews Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.comment_bank_outlined, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Customer Reviews',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.rate_review_outlined, size: 16, color: AppTheme.primaryColor),
                  label: const Text(
                    'Add Review',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dedicated Account Comment Field Card matching reference image
            _buildCommentInputCard(),

            // Review Cards List
            ..._reviews.map((review) {
              final starsCount = int.tryParse(review['stars'] ?? '5') ?? 5;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              review['userName']![0],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review['userName']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                                ),
                                Text(
                                  review['date']!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < starsCount ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 15,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment']!,
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Risk Score Summary Box
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
            const SizedBox(height: 24),

            // Bottom Navigation Buttons
            CustomButton(
              label: 'View Risk Ranking Comparison',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.riskRankingList);
              },
            ),
          ],
        ),
      ),
    );
  }
}
