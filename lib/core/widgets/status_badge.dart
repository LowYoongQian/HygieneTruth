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

    switch (statusStr.toLowerCase()) {
      case 'approved':
      case 'resolved':
      case 'active':
      case 'compliant':
        bg = const Color(0xFF10B981);
        iconData = Icons.check_circle_outline;
        break;
      case 'pending':
      case 'submitted':
      case 'underreview':
      case 'under review':
      case 'pendingverification':
      case 'pending verification':
      case 'pendinginspection':
      case 'pending inspection':
        bg = const Color(0xFFF59E0B);
        iconData = Icons.schedule;
        break;
      case 'investigating':
      case 'in progress':
      case 'inprogress':
        bg = const Color(0xFF0284C7);
        iconData = Icons.search;
        break;
      case 'rejected':
      case 'deactivated':
      case 'noncompliant':
      case 'non-compliant':
      case 'suspended':
        bg = const Color(0xFFEF4444);
        iconData = Icons.cancel_outlined;
        break;
      case 'needsrevision':
      case 'needs revision':
        bg = const Color(0xFF8B5CF6);
        iconData = Icons.edit_note;
        break;
    }

    return StatusBadge(
      text: statusStr,
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
