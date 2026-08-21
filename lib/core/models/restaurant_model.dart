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
  final String? enforcementAction; // 'closure', 'fine', 'warning', 'none'
  final double fineAmount;
  final bool isFinePaid;
  final String? fineIssuedDate;
  final String? fineDueDate;
  final bool isSuspended;
  final String? statutoryCitation;

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
    this.enforcementAction,
    this.fineAmount = 0.0,
    this.isFinePaid = true,
    this.fineIssuedDate,
    this.fineDueDate,
    this.isSuspended = false,
    this.statutoryCitation,
  });

  bool get hasActiveEnforcement {
    if (enforcementAction == null || enforcementAction == 'none' || enforcementAction!.isEmpty) {
      return false;
    }
    return !isFinePaid || enforcementAction == 'closure' || isSuspended;
  }

  int get fineDaysRemaining {
    if (fineDueDate == null || fineDueDate!.isEmpty) {
      if (fineIssuedDate != null && fineIssuedDate!.isNotEmpty) {
        try {
          final issued = DateTime.parse(fineIssuedDate!);
          final due = issued.add(const Duration(days: 14));
          final diff = due.difference(DateTime.now()).inDays;
          return diff < 0 ? 0 : diff;
        } catch (_) {}
      }
      return 14;
    }
    try {
      final due = DateTime.parse(fineDueDate!);
      final diff = due.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 14;
    }
  }

  bool get isCompoundedOverdue {
    if (fineAmount > 0 && !isFinePaid) {
      return fineDaysRemaining <= 0;
    }
    return false;
  }

  bool get isPubliclyVisible {
    if (status != RestaurantStatus.approved) return false;
    if (isSuspended) return false;
    if (enforcementAction == 'closure' && !isFinePaid) return false;
    if (isCompoundedOverdue) return false;
    return true;
  }

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

    final double fineAmt = (map['fine_amount'] as num?)?.toDouble() ??
        (map['fineAmount'] as num?)?.toDouble() ??
        0.0;
    final bool finePaid = map['is_fine_paid'] == true ||
        map['isFinePaid'] == true ||
        (map['is_fine_paid'] == null && fineAmt == 0.0);
    final bool suspended = map['is_suspended'] == true || map['isSuspended'] == true;

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
      enforcementAction: map['enforcement_action']?.toString() ?? map['enforcementAction']?.toString(),
      fineAmount: fineAmt,
      isFinePaid: finePaid,
      fineIssuedDate: map['fine_issued_date']?.toString() ?? map['fineIssuedDate']?.toString(),
      fineDueDate: map['fine_due_date']?.toString() ?? map['fineDueDate']?.toString(),
      isSuspended: suspended,
      statutoryCitation: map['statutory_citation']?.toString() ?? map['statutoryCitation']?.toString(),
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
      'enforcement_action': enforcementAction,
      'fine_amount': fineAmount,
      'is_fine_paid': isFinePaid,
      'fine_issued_date': fineIssuedDate,
      'fine_due_date': fineDueDate,
      'is_suspended': isSuspended,
      'statutory_citation': statutoryCitation,
    };
  }

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? address,
    String? category,
    double? latitude,
    double? longitude,
    double? hygieneRiskScore,
    RiskCategory? riskCategory,
    RestaurantStatus? status,
    int? violationCount,
    String? imageUrl,
    String? lastUpdated,
    String? ownerId,
    String? ownerName,
    String? operatingHours,
    String? businessRegNo,
    String? enforcementAction,
    double? fineAmount,
    bool? isFinePaid,
    String? fineIssuedDate,
    String? fineDueDate,
    bool? isSuspended,
    String? statutoryCitation,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hygieneRiskScore: hygieneRiskScore ?? this.hygieneRiskScore,
      riskCategory: riskCategory ?? this.riskCategory,
      status: status ?? this.status,
      violationCount: violationCount ?? this.violationCount,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      operatingHours: operatingHours ?? this.operatingHours,
      businessRegNo: businessRegNo ?? this.businessRegNo,
      enforcementAction: enforcementAction ?? this.enforcementAction,
      fineAmount: fineAmount ?? this.fineAmount,
      isFinePaid: isFinePaid ?? this.isFinePaid,
      fineIssuedDate: fineIssuedDate ?? this.fineIssuedDate,
      fineDueDate: fineDueDate ?? this.fineDueDate,
      isSuspended: isSuspended ?? this.isSuspended,
      statutoryCitation: statutoryCitation ?? this.statutoryCitation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RestaurantModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
