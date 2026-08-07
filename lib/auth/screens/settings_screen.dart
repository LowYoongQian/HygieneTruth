import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Push Notification Settings Toggles
  bool _enablePushNotifications = true;
  bool _hygieneRiskAlerts = true;
  bool _inspectionUpdates = true;
  bool _complaintStatusAlerts = true;

  // Selected Language
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾'},
    {'code': 'zh', 'name': '中文 (Chinese)', 'flag': '🇨🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = CustomerStoreService.currentCustomer;
    final userId = user?.id ?? 'guest_default';
    final settings = await UserSettingsService.loadUserSettings(userId);
    if (mounted) {
      setState(() {
        _enablePushNotifications = settings.enablePushNotifications;
        _hygieneRiskAlerts = settings.hygieneRiskAlerts;
        _complaintStatusAlerts = settings.complaintStatusAlerts;
        _inspectionUpdates = settings.inspectionUpdates;
        _selectedLanguage = settings.selectedLanguage;
      });
    }
  }

  void _saveSettingBool(String key, bool val) {
    final user = CustomerStoreService.currentCustomer;
    final userId = user?.id ?? 'guest_default';
    UserSettingsService.saveBool(userId, key, val);
  }

  void _saveSettingString(String key, String val) {
    final user = CustomerStoreService.currentCustomer;
    final userId = user?.id ?? 'guest_default';
    UserSettingsService.saveString(userId, key, val);
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select System Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                ),
                const SizedBox(height: 16),
                ..._languages.map((lang) {
                  final isSelected = _selectedLanguage == lang['name'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                      title: Text(lang['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                      onTap: () {
                        setState(() {
                          _selectedLanguage = lang['name']!;
                        });
                        _saveSettingString('language', lang['name']!);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ACCOUNT & SECURITY SECTION
            _buildSectionHeader('ACCOUNT & PROFILE'),
            _buildSettingCard([
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.blue),
                ),
                title: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Name, email, phone number', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.indigo),
                ),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Update login credentials', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.pushNamed(context, AppRoutes.resetPassword),
              ),
            ]),

            const SizedBox(height: 24),

            // 2. PUSH NOTIFICATIONS SECTION
            _buildSectionHeader('PUSH NOTIFICATIONS'),
            _buildSettingCard([
              SwitchListTile(
                activeThumbColor: AppTheme.primaryColor,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: Colors.amber),
                ),
                title: const Text('Enable Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Receive real-time alerts and updates', style: TextStyle(fontSize: 12)),
                value: _enablePushNotifications,
                onChanged: (val) {
                  setState(() {
                    _enablePushNotifications = val;
                  });
                  _saveSettingBool('enable_push', val);
                },
              ),
              if (_enablePushNotifications) ...[
                const Divider(height: 1),
                SwitchListTile(
                  activeThumbColor: AppTheme.primaryColor,
                  title: const Text('Hygiene Risk Alerts', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('High risk changes near your location', style: TextStyle(fontSize: 12)),
                  value: _hygieneRiskAlerts,
                  onChanged: (val) {
                    setState(() => _hygieneRiskAlerts = val);
                    _saveSettingBool('risk_alerts', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeThumbColor: AppTheme.primaryColor,
                  title: const Text('Complaint Status Updates', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Official inspection and ticket progress', style: TextStyle(fontSize: 12)),
                  value: _complaintStatusAlerts,
                  onChanged: (val) {
                    setState(() => _complaintStatusAlerts = val);
                    _saveSettingBool('complaint_alerts', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeThumbColor: AppTheme.primaryColor,
                  title: const Text('Inspection Notice Updates', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Enforcement notices and resolution reports', style: TextStyle(fontSize: 12)),
                  value: _inspectionUpdates,
                  onChanged: (val) {
                    setState(() => _inspectionUpdates = val);
                    _saveSettingBool('inspection_updates', val);
                  },
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // 3. NEW CONTAINER SECTION FOR THEME SETTINGS
            _buildSectionHeader('APPEARANCE & THEME SETTINGS'),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3C3C3C)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Select App Theme Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.navyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Segmented Theme Mode Selector (Light, System, Dark)
                  ListenableBuilder(
                    listenable: themeManager,
                    builder: (context, _) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF181818) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildThemeOption(ThemeMode.light, 'Light', Icons.light_mode_outlined),
                            _buildThemeOption(ThemeMode.system, 'System', Icons.brightness_auto_outlined),
                            _buildThemeOption(ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. LANGUAGE & PREFERENCES SECTION
            _buildSectionHeader('PREFERENCES & LANGUAGE'),
            _buildSettingCard([
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language, color: Colors.green),
                ),
                title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_selectedLanguage, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _showLanguageSelector,
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, String label, IconData icon) {
    final bool isSelected = themeManager.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color activeColor = AppTheme.primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          themeManager.setThemeMode(mode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label Theme applied successfully!'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF252526) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.2)
                : Border.all(color: Colors.transparent),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : (isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : (isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
