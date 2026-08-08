import 'package:flutter/foundation.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import 'supabase_service.dart';

class RestaurantStoreService {
  /// Save a new restaurant input to Supabase database & append to active store
  static Future<RestaurantModel> addRestaurant({
    required String name,
    required String address,
    required String category,
    required double latitude,
    required double longitude,
    String? ssmCertUrl,
  }) async {
    final String id = 'rst_${DateTime.now().millisecondsSinceEpoch}';
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    final newRestaurant = RestaurantModel(
      id: id,
      name: name,
      address: address,
      category: category,
      latitude: latitude,
      longitude: longitude,
      hygieneRiskScore: 10.0,
      riskCategory: RiskCategory.safe,
      status: RestaurantStatus.pendingVerification,
      violationCount: 0,
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
      lastUpdated: nowIso.split('T').first,
    );

    // 1. Insert into Supabase Database `restaurants` table
    try {
      final supabase = SupabaseService.client;
      await supabase.from('restaurants').insert({
        'id': id,
        'name': name,
        'address': address,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'hygiene_risk_score': 10.0,
        'risk_category': 'safe',
        'status': 'pendingVerification',
        'violation_count': 0,
        'image_url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
        'created_at': nowIso,
        'ssm_cert_url': ssmCertUrl ?? '',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Supabase restaurants table insert info: $e');
      }
    }

    // 2. Append to active restaurants store for immediate UI updates
    MockSeedData.restaurants.insert(0, newRestaurant);

    return newRestaurant;
  }
}
