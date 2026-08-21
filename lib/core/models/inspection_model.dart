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
  final String? statutoryCitation;
  final String? issuedDate;
  final String? dueDate;
  final bool isFinePaid;
  final String? paidAt;

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
    this.statutoryCitation,
    this.issuedDate,
    this.dueDate,
    this.isFinePaid = false,
    this.paidAt,
  });

  factory InspectionModel.fromMap(Map<String, dynamic> map) {
    final double fineAmt = (map['fine_amount'] as num?)?.toDouble() ??
        (map['fineAmount'] as num?)?.toDouble() ??
        0.0;
    final bool finePaid = map['is_fine_paid'] == true ||
        map['isFinePaid'] == true ||
        (map['is_fine_paid'] == null && fineAmt == 0.0);

    return InspectionModel(
      id: map['id']?.toString() ?? '',
      complaintId: map['complaint_id']?.toString() ?? map['complaintId']?.toString() ?? '',
      restaurantId: map['restaurant_id']?.toString() ?? map['restaurantId']?.toString() ?? '',
      restaurantName: map['restaurant_name']?.toString() ?? map['restaurantName']?.toString() ?? 'Premises',
      scheduledDate: map['scheduled_date']?.toString() ?? map['scheduledDate']?.toString() ?? '',
      conductedDate: map['conducted_date']?.toString() ?? map['conductedDate']?.toString(),
      officerName: map['officer_name']?.toString() ?? map['officerName']?.toString() ?? 'Health Officer',
      outcome: InspectionOutcome.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['outcome'] ?? '').toString().toLowerCase(),
        orElse: () => InspectionOutcome.pending,
      ),
      findings: map['findings']?.toString() ?? '',
      recommendedAction: EnforcementType.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['recommended_action'] ?? map['recommendedAction'] ?? '').toString().toLowerCase(),
        orElse: () => EnforcementType.warning,
      ),
      issuedAction: EnforcementType.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['issued_action'] ?? map['issuedAction'] ?? '').toString().toLowerCase(),
        orElse: () => EnforcementType.warning,
      ),
      justification: map['justification']?.toString() ?? '',
      fineAmount: fineAmt,
      enforcementStatus: EnforcementStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['enforcement_status'] ?? map['enforcementStatus'] ?? '').toString().toLowerCase(),
        orElse: () => EnforcementStatus.pending,
      ),
      statutoryCitation: map['statutory_citation']?.toString() ?? map['statutoryCitation']?.toString(),
      issuedDate: map['issued_date']?.toString() ?? map['issuedDate']?.toString(),
      dueDate: map['due_date']?.toString() ?? map['dueDate']?.toString(),
      isFinePaid: finePaid,
      paidAt: map['paid_at']?.toString() ?? map['paidAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'scheduled_date': scheduledDate,
      'conducted_date': conductedDate,
      'officer_name': officerName,
      'outcome': outcome.name,
      'findings': findings,
      'recommended_action': recommendedAction.name,
      'issued_action': issuedAction.name,
      'justification': justification,
      'fine_amount': fineAmount,
      'enforcement_status': enforcementStatus.name,
      'statutory_citation': statutoryCitation,
      'issued_date': issuedDate,
      'due_date': dueDate,
      'is_fine_paid': isFinePaid,
      'paid_at': paidAt,
    };
  }

  InspectionModel copyWith({
    String? id,
    String? complaintId,
    String? restaurantId,
    String? restaurantName,
    String? scheduledDate,
    String? conductedDate,
    String? officerName,
    InspectionOutcome? outcome,
    String? findings,
    EnforcementType? recommendedAction,
    EnforcementType? issuedAction,
    String? justification,
    double? fineAmount,
    EnforcementStatus? enforcementStatus,
    String? statutoryCitation,
    String? issuedDate,
    String? dueDate,
    bool? isFinePaid,
    String? paidAt,
  }) {
    return InspectionModel(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      conductedDate: conductedDate ?? this.conductedDate,
      officerName: officerName ?? this.officerName,
      outcome: outcome ?? this.outcome,
      findings: findings ?? this.findings,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      issuedAction: issuedAction ?? this.issuedAction,
      justification: justification ?? this.justification,
      fineAmount: fineAmount ?? this.fineAmount,
      enforcementStatus: enforcementStatus ?? this.enforcementStatus,
      statutoryCitation: statutoryCitation ?? this.statutoryCitation,
      issuedDate: issuedDate ?? this.issuedDate,
      dueDate: dueDate ?? this.dueDate,
      isFinePaid: isFinePaid ?? this.isFinePaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
