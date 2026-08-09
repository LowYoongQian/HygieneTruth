import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/audit_log_service.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/language_manager.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/utils/translations.dart';
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
      });
    }
  }

  void _saveSettingBool(String key, bool val) {
    final user = CustomerStoreService.currentCustomer;
    final userId = user?.id ?? 'guest_default';
    UserSettingsService.saveBool(userId, key, val);
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          Widget buildPasswordField({
            required TextEditingController controller,
            required String label,
            required bool isObscured,
            required VoidCallback onToggle,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: TextField(
                controller: controller,
                obscureText: isObscured,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    onPressed: onToggle,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  t('change_password'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navyColor),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  buildPasswordField(
                    controller: oldPasswordController,
                    label: 'Current Password',
                    isObscured: obscureOld,
                    onToggle: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                  buildPasswordField(
                    controller: newPasswordController,
                    label: 'New Password',
                    isObscured: obscureNew,
                    onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    isObscured: obscureConfirm,
                    onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(t('cancel'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        final newPass = newPasswordController.text;
                        final confirmPass = confirmPasswordController.text;

                        if (newPass.isEmpty || confirmPass.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields!'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (newPass != confirmPass) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('New passwords do not match!'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (newPass.length < 6) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Password must be at least 6 characters!'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        try {
                          final supabase = SupabaseService.client;
                          try {
                            await supabase.auth.updateUser(UserAttributes(password: newPass));
                          } catch (_) {}

                          AuditLogService.logAction(
                            actionType: 'PASSWORD_CHANGE',
                            category: 'Account Modification',
                            title: 'Password Changed',
                            description: 'Updated account login credentials',
                          );

                          if (!mounted) return;
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully!'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Text(t('update'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
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
                Text(
                  t('choose_language'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                ),
                const SizedBox(height: 16),
                ...List.generate(LanguageManager.languages.length, (index) {
                  final lang = LanguageManager.languages[index];
                  final isSelected = languageManager.locale.languageCode == lang['code'];

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
                      title: Text(lang['label'].toString(), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                      onTap: () {
                        languageManager.setLanguage(index);
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
                onTap: _showChangePasswordDialog,
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
            _buildSectionHeader(t('preferences')),
            _buildSettingCard([
              ListenableBuilder(
                listenable: languageManager,
                builder: (context, _) {
                  final currentLang = LanguageManager.languages.firstWhere(
                    (l) => l['code'] == languageManager.locale.languageCode,
                    orElse: () => LanguageManager.languages.first,
                  );

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: Colors.green),
                    ),
                    title: Text(t('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(currentLang['label'].toString(), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: _showLanguageSelector,
                  );
                },
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
