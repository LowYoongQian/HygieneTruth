import 'package:flutter/foundation.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import '../utils/uuid_helper.dart';
import 'customer_store_service.dart';
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
    String operatingHours = '10:00 AM - 10:00 PM (Daily)',
    bool autoApprove = false,
  }) async {
    final String id = UuidHelper.generateV4();
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    final RestaurantStatus status = autoApprove ? RestaurantStatus.approved : RestaurantStatus.pendingVerification;
    final String statusStr = autoApprove ? 'approved' : 'pendingVerification';
    final String? currentUserId = SupabaseService.client.auth.currentUser?.id ?? CustomerStoreService.currentCustomer?.id;
    final String? generatedRegNo = status == RestaurantStatus.approved
        ? 'SSM-${DateTime.now().year}-${id.substring(0, 6).toUpperCase()}-X'
        : null;

    final newRestaurant = RestaurantModel(
      id: id,
      name: name,
      address: address,
      category: category,
      latitude: latitude,
      longitude: longitude,
      hygieneRiskScore: 10.0,
      riskCategory: RiskCategory.safe,
      status: status,
      violationCount: 0,
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
      lastUpdated: nowIso.split('T').first,
      ownerId: currentUserId ?? 'own_001',
      operatingHours: operatingHours,
      businessRegNo: generatedRegNo,
    );

    // 1. Insert into Supabase Database `restaurants` table matching exact Postgres schema
    try {
      final supabase = SupabaseService.client;
      final Map<String, dynamic> insertData = {
        'id': id,
        'name': name,
        'address': address,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'hygiene_grade': 'A',
        'hygiene_risk_score': 10.0,
        'risk_category': 'safe',
        'status': statusStr,
        'violation_count': 0,
        'image_url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
        'created_at': nowIso,
        'last_updated': nowIso,
      };

      if (currentUserId != null && currentUserId.isNotEmpty) {
        insertData['owner_id'] = currentUserId;
      }

      // Try inserting with operating_hours and business_reg_no into database
      try {
        final Map<String, dynamic> insertDataWithExtraCols = Map<String, dynamic>.from(insertData);
        insertDataWithExtraCols['operating_hours'] = operatingHours;
        if (generatedRegNo != null) {
          insertDataWithExtraCols['business_reg_no'] = generatedRegNo;
        }
        await supabase.from('restaurants').insert(insertDataWithExtraCols);
      } catch (_) {
        // Safe fallback if operating_hours column is not yet present in Supabase table schema
        await supabase.from('restaurants').insert(insertData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase restaurants table insert error: $e');
      }
    }

    // 2. Append to active restaurants store for immediate UI updates
    MockSeedData.restaurants.insert(0, newRestaurant);

    return newRestaurant;
  }
}
