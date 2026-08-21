import 'package:flutter/material.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/language_manager.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../widgets/restaurant_card.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate initial data fetching shimmer loading effect
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        final restaurants = RestaurantStoreService.restaurantsNotifier.value.where((r) => r.isPubliclyVisible).toList();

        return Scaffold(
          appBar: CustomAppBar(title: t('top_rated_safe')),
          body: SkeletonScreenWrapper(
            isLoading: _isLoading,
            skeletonView: const SkeletonListLoader(itemCount: 5),
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  return RestaurantCard(restaurant: restaurants[index]);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dedicated Wishlist / Saved Restaurants Screen
class SavedRestaurantsScreen extends StatefulWidget {
  const SavedRestaurantsScreen({super.key});

  @override
  State<SavedRestaurantsScreen> createState() => _SavedRestaurantsScreenState();
}

class _SavedRestaurantsScreenState extends State<SavedRestaurantsScreen> {
  bool _isLoading = true;
  List<RestaurantModel> _savedRestaurants = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final list = await BookmarkService.getBookmarkedRestaurants(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _savedRestaurants = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Saved Wishlist',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Wishlist',
                onPressed: () => _loadSaved(forceRefresh: true),
              ),
            ],
          ),
          body: ValueListenableBuilder<Set<String>>(
            valueListenable: BookmarkService.bookmarkedIdsNotifier,
            builder: (context, bookmarkedIds, _) {
              if (_isLoading) {
                return const SkeletonListLoader(itemCount: 4);
              }

              final displayedList = _savedRestaurants.where((r) => bookmarkedIds.contains(r.id)).toList();

              if (displayedList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 46,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Your Wishlist is Empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navyColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save restaurants you love by tapping the bookmark icon on any outlet page or card.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text('Explore Outlets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _loadSaved(forceRefresh: true),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: displayedList.length,
                  itemBuilder: (context, index) {
                    final restaurant = displayedList[index];
                    return Dismissible(
                      key: Key('bookmark_${restaurant.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        BookmarkService.toggleBookmark(restaurant.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${restaurant.name} removed from wishlist'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => BookmarkService.toggleBookmark(restaurant.id),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.restaurantDetail,
                              arguments: restaurant,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Restaurant Image with Risk Chip
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: Image.network(
                                          restaurant.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.store, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: restaurant.riskCategory == RiskCategory.safe
                                              ? const Color(0xFF059669)
                                              : (restaurant.riskCategory == RiskCategory.moderate
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFFDC2626)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          restaurant.riskCategory.name.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Title, Category & Address
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.navyColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        restaurant.category,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF0F766E)),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              restaurant.address,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Bookmark Action Icon
                                IconButton(
                                  icon: const Icon(
                                    Icons.bookmark_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 24,
                                  ),
                                  tooltip: 'Remove from Wishlist',
                                  onPressed: () async {
                                    await BookmarkService.toggleBookmark(restaurant.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

