import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
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
    final restaurants = MockSeedData.restaurants;

    return Scaffold(
      appBar: const CustomAppBar(title: 'All Outlets'),
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
  }
}
