import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../widgets/restaurant_card.dart';

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<RestaurantModel> _filteredList = MockSeedData.restaurants;

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = MockSeedData.restaurants;
      } else {
        _filteredList = MockSeedData.restaurants
            .where((r) =>
                r.name.toLowerCase().contains(query.toLowerCase()) ||
                r.category.toLowerCase().contains(query.toLowerCase()) ||
                r.address.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Search Outlets'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search outlets...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredList.length} Outlets',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Map View'),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantMap),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredList.isEmpty
                ? const Center(child: Text('No outlets found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      return RestaurantCard(restaurant: _filteredList[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
