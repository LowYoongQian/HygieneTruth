import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    IconData icon;

    switch (role) {
      case UserRole.user:
        bg = const Color(0xFF0284C7);
        label = 'Public User';
        icon = Icons.person;
        break;
      case UserRole.admin:
        bg = Colors.purple;
        label = 'System Admin';
        icon = Icons.admin_panel_settings;
        break;
      case UserRole.government:
        bg = Colors.blueGrey;
        label = 'Officer';
        icon = Icons.security;
        break;
      case UserRole.owner:
        bg = const Color(0xFFD97706);
        label = 'Owner';
        icon = Icons.storefront;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        border: Border.all(color: bg, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: bg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: bg,
            ),
          ),
        ],
      ),
    );
  }
}
