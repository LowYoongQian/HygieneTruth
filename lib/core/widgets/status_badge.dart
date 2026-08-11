import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.icon,
  });

  factory StatusBadge.fromStatus(String statusStr) {
    Color bg = Colors.grey;
    Color fg = Colors.white;
    IconData? iconData;

    String label = statusStr;

    switch (statusStr.toLowerCase()) {
      case 'approved':
        label = 'Approved';
        bg = const Color(0xFF10B981);
        iconData = Icons.check_circle_outline;
        break;
      case 'resolved':
        label = 'Resolved';
        bg = const Color(0xFF10B981);
        iconData = Icons.check_circle_outline;
        break;
      case 'active':
        label = 'Active';
        bg = const Color(0xFF10B981);
        iconData = Icons.check_circle_outline;
        break;
      case 'compliant':
        label = 'Compliant';
        bg = const Color(0xFF10B981);
        iconData = Icons.check_circle_outline;
        break;
      case 'pending':
      case 'submitted':
        label = 'Pending';
        bg = const Color(0xFFF59E0B);
        iconData = Icons.schedule;
        break;
      case 'underreview':
      case 'under review':
        label = 'Under Review';
        bg = const Color(0xFFF59E0B);
        iconData = Icons.schedule;
        break;
      case 'pendingverification':
      case 'pending verification':
        label = 'Pending';
        bg = const Color(0xFFF59E0B);
        iconData = Icons.schedule;
        break;
      case 'pendinginspection':
      case 'pending inspection':
        label = 'Pending Inspection';
        bg = const Color(0xFFF59E0B);
        iconData = Icons.schedule;
        break;
      case 'investigating':
        label = 'Investigating';
        bg = const Color(0xFF0284C7);
        iconData = Icons.search;
        break;
      case 'in progress':
      case 'inprogress':
        label = 'In Progress';
        bg = const Color(0xFF0284C7);
        iconData = Icons.search;
        break;
      case 'rejected':
        label = 'Rejected';
        bg = const Color(0xFFEF4444);
        iconData = Icons.cancel_outlined;
        break;
      case 'deactivated':
        label = 'Deactivated';
        bg = const Color(0xFFEF4444);
        iconData = Icons.cancel_outlined;
        break;
      case 'noncompliant':
      case 'non-compliant':
        label = 'Non-Compliant';
        bg = const Color(0xFFEF4444);
        iconData = Icons.cancel_outlined;
        break;
      case 'suspended':
        label = 'Suspended';
        bg = const Color(0xFFEF4444);
        iconData = Icons.cancel_outlined;
        break;
      case 'needsrevision':
      case 'needs revision':
        label = 'Needs Revision';
        bg = const Color(0xFF8B5CF6);
        iconData = Icons.edit_note;
        break;
    }

    return StatusBadge(
      text: label,
      backgroundColor: bg,
      textColor: fg,
      icon: iconData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        border: Border.all(color: backgroundColor, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: backgroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
