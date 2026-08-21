import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../risk/widgets/risk_score_gauge.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isSaved = false;

  final _newCommentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  int _selectedRating = 5;

  List<Map<String, String>> _reviews = [];
  String? _loadedRestaurantId;
  RestaurantModel? _currentRestaurant;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final restaurant = ModalRoute.of(context)?.settings.arguments as RestaurantModel?;
    if (restaurant != null) {
      _currentRestaurant = restaurant;
      if (restaurant.id != _loadedRestaurantId) {
        _loadedRestaurantId = restaurant.id;
        _isSaved = BookmarkService.isBookmarked(restaurant.id);
        _loadReviewsForRestaurant(restaurant.id, restaurantName: restaurant.name);
        RestaurantStoreService.recordRecentVisit(restaurant);
      }
    }
  }

  Future<void> _loadReviewsForRestaurant(String restaurantId, {String? restaurantName}) async {
    final loaded = await RestaurantStoreService.fetchReviews(
      restaurantId,
      restaurantName: restaurantName ?? _currentRestaurant?.name,
    );
    if (mounted) {
      setState(() {
        _reviews = List<Map<String, String>>.from(loaded);
      });
    }
  }

  Future<void> _saveReviewsForRestaurant(String restaurantId) async {
    try {
      await RestaurantStoreService.saveReviewsToSupabase(
        restaurantId,
        _reviews,
        restaurantName: _currentRestaurant?.name,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Map<String, String>? _findUserExistingReview() {
    final user = CustomerStoreService.currentCustomer;
    if (user == null) return null;
    final currentUserId = user.id.trim();
    final currentUserEmail = user.email.trim().toLowerCase();
    final currentUserName = user.name.trim().toLowerCase();

    for (final r in _reviews) {
      final rUserId = r['userId']?.trim();
      final rUserEmail = r['userEmail']?.trim().toLowerCase();
      final rUserName = r['userName']?.trim().toLowerCase();

      if (currentUserId.isNotEmpty && rUserId == currentUserId) {
        return r;
      }
      if (currentUserEmail.isNotEmpty && rUserEmail == currentUserEmail) {
        return r;
      }
      if (currentUserName.isNotEmpty && rUserName == currentUserName) {
        return r;
      }
    }
    return null;
  }

  String _formatReviewTimestamp(String raw) {
    if (raw.isEmpty) return 'Recently';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      final msiaDt = dt.toUtc().add(const Duration(hours: 8));
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = msiaDt.hour.toString().padLeft(2, '0');
      final minute = msiaDt.minute.toString().padLeft(2, '0');
      if (raw.contains('T') || raw.contains(':')) {
        return '${msiaDt.day} ${months[msiaDt.month - 1]} ${msiaDt.year}, $hour:$minute';
      } else {
        return '${msiaDt.day} ${months[msiaDt.month - 1]} ${msiaDt.year}';
      }
    }
    return raw;
  }

  void _submitComment() {
    if (_findUserExistingReview() != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted a review for this restaurant.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final commentText = _newCommentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment before submitting.')),
      );
      return;
    }

    final currentUser = CustomerStoreService.currentCustomer;
    final userName = currentUser?.name ?? 'Verified Customer';
    final userId = currentUser?.id ?? '';
    final userEmail = currentUser?.email ?? '';
    final userAvatar = currentUser?.avatarUrl ?? '';
    final now = DateTime.now();

    final newReview = {
      'id': 'rev_${now.millisecondsSinceEpoch}',
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userAvatar': userAvatar,
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'timestamp': now.toUtc().toIso8601String(),
      'stars': '$_selectedRating',
      'comment': commentText,
    };

    setState(() {
      _reviews.insert(0, newReview);
      _newCommentController.clear();
      _selectedRating = 5;
    });

    if (_loadedRestaurantId != null) {
      final rName = _currentRestaurant?.name ?? _loadedRestaurantId!;
      _saveReviewsForRestaurant(_loadedRestaurantId!);
      RestaurantStoreService.logUserReviewActivity(
        restaurantId: _loadedRestaurantId!,
        restaurantName: rName,
        stars: int.tryParse(newReview['stars'] ?? '5') ?? 5,
        comment: commentText,
        timestamp: newReview['timestamp'],
      );
    }

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review published successfully!'),
        backgroundColor: AppTheme.primaryColor,
      ),
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
                  final restaurant = ModalRoute.of(context)?.settings.arguments as RestaurantModel? ?? (RestaurantStoreService.restaurantsNotifier.value.isNotEmpty ? RestaurantStoreService.restaurantsNotifier.value.first : null);
                  Navigator.pushNamed(context, AppRoutes.submitComplaint, arguments: restaurant);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: AppTheme.navyColor),
                title: const Text('Share Restaurant Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Share details, risk score & GPS map link via other apps'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final restaurant = ModalRoute.of(context)?.settings.arguments as RestaurantModel? ??
                      (RestaurantStoreService.restaurantsNotifier.value.isNotEmpty
                          ? RestaurantStoreService.restaurantsNotifier.value.first
                          : null);
                  if (restaurant == null) return;

                  final ratingInfo = RestaurantStoreService.getRatingSync(
                    restaurant.id,
                    restaurantName: restaurant.name,
                  );

                  final String shareContent = '''🍽️ Check out ${restaurant.name} on HygieneTruth!

📍 Address: ${restaurant.address}
🏷️ Cuisine: ${restaurant.category}
⭐ Rating: ${ratingInfo.ratingText} ★ ${ratingInfo.hasReviews ? '(${ratingInfo.totalReviews} reviews)' : ''}
🛡️ Hygiene Status: ${restaurant.riskCategory.name.toUpperCase()} (Score: ${restaurant.hygieneRiskScore.toStringAsFixed(1)} / 100)
⏰ Operating Hours: ${restaurant.operatingHours}

🗺️ View on Google Maps: https://www.google.com/maps/search/?api=1&query=${restaurant.latitude},${restaurant.longitude}

📱 Discover clean dining and real-time hygiene audit certificates on HygieneTruth!''';

                  try {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: shareContent,
                        subject: 'Check out ${restaurant.name} on HygieneTruth',
                      ),
                    );
                  } catch (e) {
                    // Fallback to Clipboard if running on Hot Reload before cold re-run
                    await Clipboard.setData(ClipboardData(text: shareContent));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Restaurant profile copied to clipboard!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _selectedFilterStar = 0; // 0 = All, 5 = 5 stars, 4 = 4 stars, etc.
  final Set<int> _likedReviewIndices = {};

  Widget _buildOutletQuickActions(RestaurantModel restaurant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _quickActionButton(
              icon: Icons.near_me_rounded,
              label: 'Directions',
              color: const Color(0xFF00A88F),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.restaurantMap,
                  arguments: {
                    'restaurant': restaurant,
                    'showDirections': true,
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _quickActionButton(
              icon: Icons.phone_rounded,
              label: 'Call Outlet',
              color: const Color(0xFF0284C7),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling outlet contact number...')),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _quickActionButton(
              icon: Icons.report_problem_rounded,
              label: 'Report Issue',
              color: const Color(0xFFDC2626),
              isRed: true,
              onTap: _showReportOptionsDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isRed = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isRed ? const Color(0xFFFEF2F2) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isRed ? const Color(0xFFFCA5A5) : color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInputCard() {
    final currentUser = CustomerStoreService.currentCustomer;
    final userName = currentUser?.name ?? 'Verified Customer';
    final avatarUrl = currentUser?.avatarUrl ?? '';

    final ratingLabels = ['Poor', 'Fair', 'Average', 'Good', 'Excellent'];

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
                  ),
                  const Text(
                    'Share your dining hygiene experience',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _newCommentController,
              focusNode: _commentFocusNode,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Describe kitchen cleanliness, staff hygiene, utensils, or food quality...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
          // Quick Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _quickTagChip('#CleanKitchen'),
              _quickTagChip('#GoodSanitation'),
              _quickTagChip('#FreshFood'),
              _quickTagChip('#WashedUtensils'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                                starVal <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 22,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ratingLabels[_selectedRating - 1],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A88F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
                onPressed: _submitComment,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text(
                  'Post Review',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyReviewedCard(Map<String, String> existingReview) {
    final starsCount = int.tryParse(existingReview['stars'] ?? '5') ?? 5;
    final dateStr = _formatReviewTimestamp(existingReview['timestamp'] ?? existingReview['date'] ?? '');
    final comment = existingReview['comment'] ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thank You for Review this Restaurant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your hygiene experience review has been submitted and verified.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < starsCount ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 17,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$starsCount ★ Verified Diner',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.35),
                  ),
                  if ((existingReview['ownerReply'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF15803D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Official Response from Restaurant Owner',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF14532D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  existingReview['ownerReply']!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF166534),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF15803D)),
              const SizedBox(width: 6),
              Text(
                'Reviewed on: $dateStr',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTagChip(String label) {
    return GestureDetector(
      onTap: () {
        final currentText = _newCommentController.text;
        _newCommentController.text = currentText.isEmpty ? label : '$currentText $label';
        _newCommentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _newCommentController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildOutletImage(RestaurantModel restaurant) {
    final imageUrl = restaurant.imageUrl.trim();
    Widget imageWidget;

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        imageWidget = Image.network(
          imageUrl,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackImagePlaceholder(restaurant),
        );
      } else if (imageUrl.startsWith('assets/')) {
        imageWidget = Image.asset(
          imageUrl,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackImagePlaceholder(restaurant),
        );
      } else {
        try {
          final file = File(imageUrl);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackImagePlaceholder(restaurant),
            );
          } else {
            imageWidget = _buildFallbackImagePlaceholder(restaurant);
          }
        } catch (_) {
          imageWidget = _buildFallbackImagePlaceholder(restaurant);
        }
      }
    } else {
      imageWidget = _buildFallbackImagePlaceholder(restaurant);
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageWidget,
      ),
    );
  }

  Widget _buildFallbackImagePlaceholder(RestaurantModel restaurant) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C2340), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.storefront_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A88F).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00A88F).withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 40,
                  color: Color(0xFF00A88F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                restaurant.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  restaurant.category,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    double avgRating = 0.0;
    if (_reviews.isNotEmpty) {
      double sum = 0;
      for (var r in _reviews) {
        sum += (double.tryParse(r['stars'] ?? '0') ?? 0);
      }
      avgRating = sum / _reviews.length;
    }

    final hasReviews = _reviews.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Big Score Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasReviews ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasReviews ? const Color(0xFFFCD34D) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasReviews ? avgRating.toStringAsFixed(1) : '0.0',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: hasReviews ? const Color(0xFFD97706) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: List.generate(5, (index) {
                    if (!hasReviews) {
                      return Icon(Icons.star_border_rounded, color: Colors.grey.shade400, size: 14);
                    }
                    final starValue = index + 1;
                    if (avgRating >= starValue) {
                      return const Icon(Icons.star_rounded, color: Colors.amber, size: 14);
                    } else if (avgRating >= starValue - 0.5) {
                      return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 14);
                    } else {
                      return Icon(Icons.star_border_rounded, color: Colors.grey.shade400, size: 14);
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right Summary Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasReviews ? 'Customer Rating' : 'No Ratings Yet',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor),
                ),
                const SizedBox(height: 3),
                Text(
                  hasReviews
                      ? '${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}'
                      : 'New restaurant',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasReviews ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasReviews ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasReviews ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                        size: 13,
                        color: hasReviews ? const Color(0xFF059669) : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          hasReviews ? 'Verified Reviews' : 'No reviews yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasReviews ? const Color(0xFF059669) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapSection(RestaurantModel restaurant) {
    final LatLng pos = LatLng(
      restaurant.latitude != 0.0 ? restaurant.latitude : 3.1466,
      restaurant.longitude != 0.0 ? restaurant.longitude : 101.6958,
    );

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: true,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: pos,
                  zoom: 16.0,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(restaurant.id),
                    position: pos,
                    infoWindow: InfoWindow(
                      title: restaurant.name,
                      snippet: restaurant.address,
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyColor),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.restaurantMap,
                        arguments: {
                          'restaurant': restaurant,
                          'showDirections': false,
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.map_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Full Map', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard(RestaurantModel restaurant) {
    final score = restaurant.hygieneRiskScore;
    final isSafe = score < 25;
    final isModerate = score >= 25 && score <= 60;

    final Color statusColor = isSafe
        ? const Color(0xFF059669) // Emerald
        : isModerate
            ? const Color(0xFFD97706) // Amber
            : const Color(0xFFDC2626); // Red

    final Color bgColor = isSafe
        ? const Color(0xFFECFDF5)
        : isModerate
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEF2F2);

    final String statusText = isSafe
        ? 'Safe'
        : isModerate
            ? 'Moderate'
            : 'High Risk';

    final String headlineDesc = isSafe
        ? 'Excellent Hygiene (Grade A)'
        : isModerate
            ? 'Moderate Risk • Monitor Needed'
            : 'High Risk • Caution Advised';

    final String explanatoryText = isSafe
        ? 'Score ${score.toStringAsFixed(1)} / 100. High cleanliness standards observed with safe food preparation practices.'
        : isModerate
            ? 'Score ${score.toStringAsFixed(1)} / 100. Meets standard hygiene rules but has room for sanitation improvements.'
            : 'Score ${score.toStringAsFixed(1)} / 100. Elevated risk score detected. Exercise caution when dining.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Hygiene Risk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyColor),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Risk Scale: 0 (Safest) to 100 (Highest Risk)',
                    child: Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Gauge + Meaning Info
          Row(
            children: [
              RiskScoreGauge(score: score, size: 76),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headlineDesc,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      explanatoryText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _riskMetricRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Last Updated',
                      value: restaurant.lastUpdated,
                      valueColor: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual 3-Segment Risk Meter Bar (0 to 100 Scale)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Risk Meter Scale',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)} / 100',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Multi-color Segment Bar with Needle Indicator
                LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final clampedScore = score.clamp(0.0, 100.0);
                    final pointerLeft = ((clampedScore / 100.0) * totalWidth).clamp(0.0, totalWidth - 12);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Segmented bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 25,
                                child: Container(height: 8, color: const Color(0xFF10B981)), // Safe: 0-25
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: 35,
                                child: Container(height: 8, color: const Color(0xFFF59E0B)), // Moderate: 26-60
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: 40,
                                child: Container(height: 8, color: const Color(0xFFEF4444)), // High: 61-100
                              ),
                            ],
                          ),
                        ),
                        // Current Score Indicator Marker
                        Positioned(
                          left: pointerLeft,
                          top: -3,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: statusColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Range Legend Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('0-25 Safe', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('26-60 Moderate', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('61-100 High', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeArg = ModalRoute.of(context)?.settings.arguments as RestaurantModel?;
    final targetId = routeArg?.id ?? '';
    final targetName = routeArg?.name ?? '';

    return ValueListenableBuilder<List<RestaurantModel>>(
      valueListenable: RestaurantStoreService.restaurantsNotifier,
      builder: (context, allRestaurants, _) {
        final restaurant = allRestaurants.where((r) => r.id == targetId || r.name == targetName).firstOrNull ??
            routeArg ??
            (allRestaurants.isNotEmpty ? allRestaurants.first : null);

        if (restaurant == null) {
          return const Scaffold(
            appBar: CustomAppBar(title: 'Restaurant Details'),
            body: Center(child: Text('No restaurant data selected')),
          );
        }

    final filteredReviews = _selectedFilterStar == 0
        ? _reviews
        : _reviews.where((r) => int.tryParse(r['stars'] ?? '5') == _selectedFilterStar).toList();

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
                _buildOutletImage(restaurant),
                // Approved Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusBadge.fromStatus(restaurant.status.name),
                ),
                // Safe Shield Status Icon
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
                // Saved Bookmark Banner Icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final saved = await BookmarkService.toggleBookmark(restaurant.id);
                      if (!mounted) return;
                      setState(() {
                        _isSaved = saved;
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            saved
                                ? '${restaurant.name} saved to your wishlist!'
                                : '${restaurant.name} removed from wishlist.',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: saved ? const Color(0xFF0F766E) : Colors.grey.shade800,
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
                        _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isSaved ? const Color(0xFF0F766E) : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // MOH ENFORCEMENT SUSPENSION BANNER (If Not Publicly Visible)
            if (!restaurant.isPubliclyVisible) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MOH Temporary Suspension Order',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            restaurant.isCompoundedOverdue
                                ? 'This food premises has been temporarily taken down and suspended due to overdue statutory compound penalties under Section 11 Food Act 1983.'
                                : 'This food premises is temporarily suspended by the Ministry of Health under Section 11 Food Act 1983 pending rectification and fine settlement.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

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

            // Quick Actions Bar (Directions, Call, Report Issue)
            _buildOutletQuickActions(restaurant),
            const SizedBox(height: 8),

            // Dynamic Rating Summary Card
            _buildRatingSummaryCard(),
            const SizedBox(height: 16),

            // Embedded Interactive Map Section
            _buildInteractiveMapSection(restaurant),
            const SizedBox(height: 20),

            // Customer Reviews Header
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
            const SizedBox(height: 8),

            // Comment Input Box OR Thank You Card for existing reviewer
            if (_findUserExistingReview() != null)
              _buildAlreadyReviewedCard(_findUserExistingReview()!)
            else
              _buildCommentInputCard(),

            // Review Filter Chips Bar
            if (_reviews.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All (${_reviews.length})', 0),
                    _filterChip('5 ★', 5),
                    _filterChip('4 ★', 4),
                    _filterChip('3 ★', 3),
                    _filterChip('1-2 ★', 2),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Review Cards List or Empty State
            if (filteredReviews.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.star_outline_rounded, size: 36, color: Colors.amber.shade700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFilterStar == 0 ? 'No Customer Reviews Yet' : 'No $_selectedFilterStar Star Reviews',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFilterStar == 0
                          ? 'Be the first to leave a review for this outlet!'
                          : 'No reviews found matching this star rating filter.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...filteredReviews.asMap().entries.map((entry) {
                final idx = entry.key;
                final review = entry.value;
                final starsCount = int.tryParse(review['stars'] ?? '5') ?? 5;
                final isLiked = _likedReviewIndices.contains(idx);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              (review['userName'] != null && review['userName']!.isNotEmpty) ? review['userName']![0] : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      review['userName'] ?? 'Customer',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: const Text(
                                        'Verified Diner',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  review['date'] ?? '',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < starsCount ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        review['comment'] ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                      ),
                      if ((review['ownerReply'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C2340).withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront_rounded, size: 14, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Official Response from Restaurant Owner',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navyColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      review['ownerReply']!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF334155),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isLiked) {
                                  _likedReviewIndices.remove(idx);
                                } else {
                                  _likedReviewIndices.add(idx);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                    size: 14,
                                    color: isLiked ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isLiked ? 'Helpful (1)' : 'Helpful',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                                      color: isLiked ? AppTheme.primaryColor : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Ultra-Premium Hygiene Risk Score Panel
            _buildRiskScoreCard(restaurant),
            const SizedBox(height: 20),

            // Bottom Action Comparison Button
            CustomButton(
              label: 'View Risk Rankings',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.riskRankingList);
              },
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _filterChip(String label, int starVal) {
    final isSelected = _selectedFilterStar == starVal;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF00A88F),
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilterStar = selected ? starVal : 0;
          });
        },
      ),
    );
  }
}
