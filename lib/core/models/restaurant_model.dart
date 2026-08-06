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
  });
}
