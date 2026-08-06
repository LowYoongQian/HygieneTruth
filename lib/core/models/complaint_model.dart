enum ComplaintStatus {
  submitted,
  underReview,
  investigating,
  pendingInspection,
  resolved,
  rejected,
}

enum SeverityLevel { low, medium, high }

class ComplaintModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String userId;
  final String userName;
  final String category;
  final List<String> issues;
  final String description;
  final ComplaintStatus status;
  final SeverityLevel severity;
  final double latitude;
  final double longitude;
  final bool isFlaggedForReview;
  final String? flaggedReason;
  final String submittedAt;
  final List<String> photoUrls;

  const ComplaintModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.userId,
    required this.userName,
    required this.category,
    required this.issues,
    required this.description,
    required this.status,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.isFlaggedForReview = false,
    this.flaggedReason,
    required this.submittedAt,
    required this.photoUrls,
  });
}
