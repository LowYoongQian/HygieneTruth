import 'package:flutter/material.dart';

class AuditLogModel {
  final String id;
  final String userId;
  final String userEmail;
  final String actionType; // e.g. LOGIN, LOGOUT, NAME_CHANGE, PASSWORD_CHANGE, PROFILE_UPDATE
  final String category;   // e.g. 'Session Activity', 'Account Modification', 'General Activity'
  final String title;
  final String description;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.actionType,
    required this.category,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? json['userEmail']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? json['actionType']?.toString() ?? 'GENERAL',
      category: json['category']?.toString() ?? 'Account Modification',
      title: json['title']?.toString() ?? 'Account Activity',
      description: json['description']?.toString() ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : (json['timestamp'] != null ? DateTime.parse(json['timestamp'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'action_type': actionType,
      'category': category,
      'title': title,
      'description': description,
      'created_at': timestamp.toIso8601String(),
    };
  }

  IconData get icon {
    switch (actionType.toUpperCase()) {
      case 'LOGIN':
        return Icons.login_rounded;
      case 'LOGOUT':
        return Icons.logout_rounded;
      case 'NAME_CHANGE':
        return Icons.badge_outlined;
      case 'PASSWORD_CHANGE':
        return Icons.lock_reset_rounded;
      case 'PROFILE_UPDATE':
        return Icons.person_outline_rounded;
      case 'COMPLAINT_SUBMITTED':
        return Icons.report_problem_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  Color get iconColor {
    switch (category) {
      case 'Session Activity':
        return actionType.toUpperCase() == 'LOGIN' ? Colors.green : Colors.orange;
      case 'Account Modification':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }
}
