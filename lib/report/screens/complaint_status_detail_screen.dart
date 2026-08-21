import '../../core/services/restaurant_store_service.dart';
import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/complaint_status_tracker.dart';

class ComplaintStatusDetailScreen extends StatelessWidget {
  const ComplaintStatusDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    ComplaintModel? c;
    if (args is ComplaintModel) {
      c = args;
    } else if (RestaurantStoreService.complaintsNotifier.value.isNotEmpty) {
      c = RestaurantStoreService.complaintsNotifier.value.first;
    }

    if (c == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Report Status'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.report_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No complaint status available.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: 'Report: ${c.id}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComplaintStatusTracker(status: c.status),
            const SizedBox(height: 20),
            Card(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Report ID: ${c.id}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge.fromStatus(c.status.name),
                      ],
                    ),
                    Divider(height: 24, color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.store, color: AppTheme.primaryColor, size: 20),
                      ),
                      title: Text(c.restaurantName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor)),
                      subtitle: Text('Category: ${c.category}', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      ),
                      title: Text('Issues', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor)),
                      subtitle: Text(c.issues.join('\n'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFF0284C7), size: 20),
                      ),
                      title: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor)),
                      subtitle: Text(c.description, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time, color: Colors.purple, size: 20),
                      ),
                      title: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor)),
                      subtitle: Text(c.submittedAt, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
