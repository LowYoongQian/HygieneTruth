import 'package:flutter/material.dart';
import '../../core/models/audit_log_model.dart';
import '../../core/services/audit_log_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/empty_state_widget.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  bool _isLoading = true;
  List<AuditLogModel> _logs = [];
  String _selectedCategory = 'All'; // 'All', 'Session Activity', 'Account Modification'

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    final logs = await AuditLogService.fetchUserLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, ${hour.toString().padLeft(2, '0')}:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _selectedCategory == 'All'
        ? _logs
        : _logs.where((l) => l.category == _selectedCategory).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Account Audit History',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Logs',
            onPressed: _loadAuditLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey.shade50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'All Logs'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Session Activity', 'Session Activity'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Account Modification', 'Account Modifications'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: filteredLogs.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No History Recorded',
                          message: 'No audit log history entries found for this category.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAuditLogs,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLogs.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filteredLogs[index];
                              final isSession = item.category == 'Session Activity';

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: item.iconColor.withValues(alpha: 0.12),
                                        child: Icon(item.icon, color: item.iconColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isSession ? Colors.green.shade50 : Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    item.category,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSession ? Colors.green.shade700 : Colors.blue.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.description,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDateTime(item.timestamp),
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String categoryValue, String label) {
    final bool isSelected = _selectedCategory == categoryValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.navyColor, fontSize: 12, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedCategory = categoryValue);
        }
      },
    );
  }
}
