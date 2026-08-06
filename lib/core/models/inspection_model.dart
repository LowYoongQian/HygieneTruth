enum InspectionOutcome { pending, compliant, nonCompliant }

enum EnforcementType { warning, fine, closure, none }

enum EnforcementStatus { pending, inProgress, completed }

class InspectionModel {
  final String id;
  final String complaintId;
  final String restaurantId;
  final String restaurantName;
  final String scheduledDate;
  final String? conductedDate;
  final String officerName;
  final InspectionOutcome outcome;
  final String findings;
  final EnforcementType recommendedAction;
  final EnforcementType issuedAction;
  final String justification;
  final double fineAmount;
  final EnforcementStatus enforcementStatus;

  const InspectionModel({
    required this.id,
    required this.complaintId,
    required this.restaurantId,
    required this.restaurantName,
    required this.scheduledDate,
    this.conductedDate,
    required this.officerName,
    required this.outcome,
    required this.findings,
    required this.recommendedAction,
    required this.issuedAction,
    required this.justification,
    required this.fineAmount,
    required this.enforcementStatus,
  });
}
