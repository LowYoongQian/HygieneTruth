enum RestaurantStatus { approved, pendingVerification, rejected, needsRevision }

enum RiskCategory { safe, moderate, high }

class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final double hygieneRiskScore; // 0.0 to 100.0 (lower is safer)
  final RiskCategory riskCategory;
  final RestaurantStatus status;
  final int violationCount;
  final String imageUrl;
  final String lastUpdated;
  final String ownerId;
  final String ownerName;
  final String operatingHours;
  final String? businessRegNo;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.hygieneRiskScore,
    required this.riskCategory,
    required this.status,
    required this.violationCount,
    required this.imageUrl,
    required this.lastUpdated,
    this.ownerId = 'own_001',
    this.ownerName = 'Chong Wei Meng',
    this.operatingHours = '10:00 AM - 10:00 PM (Daily)',
    this.businessRegNo,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    RestaurantStatus parseStatus(String? s) {
      if (s == 'approved' || s == 'active') return RestaurantStatus.approved;
      if (s == 'rejected') return RestaurantStatus.rejected;
      if (s == 'needsRevision') return RestaurantStatus.needsRevision;
      return RestaurantStatus.pendingVerification;
    }

    RiskCategory parseRisk(String? r) {
      if (r == 'high' || r == 'critical') return RiskCategory.high;
      if (r == 'moderate') return RiskCategory.moderate;
      return RiskCategory.safe;
    }

    return RestaurantModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Restaurant',
      address: map['address']?.toString() ?? 'No address provided',
      category: map['category']?.toString() ?? 'General',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 3.1475,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 101.7085,
      hygieneRiskScore: (map['hygiene_risk_score'] as num?)?.toDouble() ?? 10.0,
      riskCategory: parseRisk(map['risk_category']?.toString()),
      status: parseStatus(map['status']?.toString()),
      violationCount: (map['violation_count'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
      lastUpdated: map['last_updated']?.toString().split('T').first ?? '2026-08-09',
      ownerId: map['owner_id']?.toString() ?? 'own_001',
      ownerName: map['owner_name']?.toString() ?? 'Owner',
      operatingHours: map['operating_hours']?.toString() ?? '10:00 AM - 10:00 PM (Daily)',
      businessRegNo: map['business_reg_no']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'hygiene_risk_score': hygieneRiskScore,
      'risk_category': riskCategory.name,
      'status': status.name,
      'violation_count': violationCount,
      'image_url': imageUrl,
      'last_updated': lastUpdated,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'operating_hours': operatingHours,
      'business_reg_no': businessRegNo,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RestaurantModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
