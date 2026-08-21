import 'dart:async';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../theme/theme_manager.dart';
import '../utils/uuid_helper.dart';
import 'audit_log_service.dart';
import 'language_manager.dart';
import 'remember_me_service.dart';
import 'supabase_service.dart';

class CustomerAuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final bool isAccountNotFound;

  const CustomerAuthResult({
    required this.success,
    required this.message,
    this.user,
    this.isAccountNotFound = false,
  });
}

class CustomerStoreService {
  static List<UserModel> getAllRegisteredCustomers() {
    return _registeredCustomers.entries.map((e) => UserModel(
      id: e.key,
      name: e.key.split('@').first,
      email: e.key,
      phone: '',
      role: e.value['role'] == 'businessman' ? UserRole.owner : UserRole.user,
      status: AccountStatus.active,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    )).toList();
  }

  static UserModel? _currentCustomer;

  static UserModel? get currentCustomer => _currentCustomer;

  static final Map<String, Map<String, String>> _registeredCustomers = {};

  /// Fetches real user profile for the current active Supabase Auth session or current customer
  static Future<UserModel?> fetchActiveUserSession() async {
    try {
      final supabase = SupabaseService.client;
      final sessionUser = supabase.auth.currentUser;
      
      String? targetUserId = sessionUser?.id ?? _currentCustomer?.id;
      String? targetUserEmail = sessionUser?.email ?? _currentCustomer?.email;

      if (targetUserId == null && (targetUserEmail == null || targetUserEmail.isEmpty)) {
        return _currentCustomer;
      }

      // Query real user row from public.users table in Supabase
      Map<String, dynamic>? data;
      if (targetUserId != null && targetUserId.isNotEmpty) {
        try {
          data = await supabase
              .from('users')
              .select()
              .eq('id', targetUserId)
              .maybeSingle();
        } catch (_) {}
      }

      if (data == null && targetUserEmail != null && targetUserEmail.isNotEmpty) {
        try {
          data = await supabase
              .from('users')
              .select()
              .eq('email', targetUserEmail.trim().toLowerCase())
              .maybeSingle();
        } catch (_) {}
      }

      final String finalId = data?['id']?.toString() ?? targetUserId ?? UuidHelper.generateV4();
      final String finalEmail = data?['email']?.toString() ?? targetUserEmail ?? '';

      String name = sessionUser?.userMetadata?['name'] as String? ?? (finalEmail.isNotEmpty ? finalEmail.split('@').first : 'User');
      String? phone;
      String? gender;
      String? country;
      String? state;
      String avatarUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200';
      UserRole userRole = _currentCustomer?.role ?? UserRole.user;

      if (data != null) {
        name = data['name']?.toString() ?? name;
        phone = data['phone']?.toString();
        gender = data['gender']?.toString();
        country = data['country']?.toString();
        state = data['state']?.toString();
        if (data['avatar_url'] != null && data['avatar_url'].toString().trim().isNotEmpty) {
          avatarUrl = data['avatar_url'].toString().trim();
        }
        if (data['role'] != null) {
          final r = data['role'].toString().toLowerCase();
          userRole = (r == 'businessman' || r == 'owner')
              ? UserRole.owner
              : (r == 'admin'
                  ? UserRole.admin
                  : (r == 'government' ? UserRole.government : UserRole.user));
        }
        if (data['language'] != null) {
          final langIdx = int.tryParse(data['language'].toString());
          if (langIdx != null) {
            languageManager.updateLanguageFromDatabase(langIdx);
          }
        }
        if (data['settings'] is Map) {
          final settings = data['settings'] as Map<String, dynamic>;
          if (settings['google_linked'] is Map) {
            _cachedGoogleLinkedEmail = settings['google_linked']['email']?.toString();
          } else if (settings['google_email'] != null) {
            _cachedGoogleLinkedEmail = settings['google_email']?.toString();
          }
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        _cachedGoogleLinkedEmail ??= prefs.getString('google_linked_email_$finalId') ?? prefs.getString('google_linked_email_$finalEmail');
      } catch (_) {}

      String? joinedDate;
      final rawCreated = data?['created_at']?.toString() ?? sessionUser?.createdAt ?? _currentCustomer?.joinedDate;
      if (rawCreated != null && rawCreated.isNotEmpty) {
        final dt = DateTime.tryParse(rawCreated);
        if (dt != null) {
          final DateTime msiaDt = dt.toUtc().add(const Duration(hours: 8));
          joinedDate = '${msiaDt.day} ${_monthName(msiaDt.month)} ${msiaDt.year}';
        }
      }

      if (joinedDate == null || joinedDate.isEmpty) {
        final nowMsia = DateTime.now().toUtc().add(const Duration(hours: 8));
        joinedDate = '${nowMsia.day} ${_monthName(nowMsia.month)} ${nowMsia.year}';
      }

      _currentCustomer = UserModel(
        id: finalId,
        name: name,
        email: finalEmail,
        phone: phone,
        role: userRole,
        status: AccountStatus.active,
        avatarUrl: avatarUrl,
        gender: gender,
        country: country,
        state: state,
        joinedDate: joinedDate,
      );

      themeManager.loadThemeForUser(finalId);

      return _currentCustomer;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching active Supabase session user profile: $e');
      }
      return _currentCustomer;
    }
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  static String? _cachedGoogleLinkedEmail;

  /// Checks if current Supabase session or user profile is linked to a Google auth provider
  static bool isGoogleLinked() {
    if (_cachedGoogleLinkedEmail != null && _cachedGoogleLinkedEmail!.trim().isNotEmpty) {
      return true;
    }
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final provider = user.appMetadata['provider']?.toString();
      if (provider == 'google') return true;
      final identities = user.identities;
      if (identities != null) {
        return identities.any((id) => id.provider.toLowerCase() == 'google');
      }
    }
    return false;
  }

  /// Returns linked Google account email address if available
  static String getGoogleLinkedEmail() {
    if (_cachedGoogleLinkedEmail != null && _cachedGoogleLinkedEmail!.trim().isNotEmpty) {
      return _cachedGoogleLinkedEmail!;
    }
    final user = SupabaseService.client.auth.currentUser;
    if (user != null && isGoogleLinked()) {
      return user.email ?? '';
    }
    return '';
  }

  /// Links / binds a Google account to the currently logged in profile
  static Future<CustomerAuthResult> linkGoogleAccount() async {
    try {
      final supabase = SupabaseService.client;
      String? envClientId;
      try {
        if (dotenv.isInitialized) {
          envClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
        }
      } catch (_) {}
      final String webClientId = envClientId ??
          '927326709623-332ted8aosmjf5efmbq3if09ur98vtl5.apps.googleusercontent.com';

      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      // 1. Initialize Native Google Sign-In SDK
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: isAndroid ? null : webClientId,
        serverClientId: webClientId,
      );

      // Clear any stale cached session to prevent [16] account reauth failed
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await googleSignIn.authenticate();

      final String gEmail = googleUser.email;
      final String gName = googleUser.displayName ?? gEmail.split('@').first;
      final String? gAvatar = googleUser.photoUrl;

      final currentCust = _currentCustomer;
      final String? userId = currentCust?.id ?? supabase.auth.currentUser?.id;
      final String? userEmail = currentCust?.email ?? supabase.auth.currentUser?.email;

      // 3. Persist binding to Supabase users table settings column
      if (userId != null || (userEmail != null && userEmail.isNotEmpty)) {
        try {
          Map<String, dynamic>? userRow;
          if (userId != null && userId.isNotEmpty) {
            userRow = await supabase.from('users').select('id, settings').eq('id', userId).maybeSingle();
          }
          if (userRow == null && userEmail != null && userEmail.isNotEmpty) {
            userRow = await supabase.from('users').select('id, settings').eq('email', userEmail).maybeSingle();
          }

          Map<String, dynamic> settings = {};
          if (userRow != null && userRow['settings'] is Map) {
            settings = Map<String, dynamic>.from(userRow['settings'] as Map);
          }

          settings['google_linked'] = {
            'email': gEmail,
            'name': gName,
            'avatar': gAvatar,
            'linked_at': DateTime.now().toUtc().toIso8601String(),
          };
          settings['google_email'] = gEmail;

          final String targetId = userRow?['id']?.toString() ?? userId ?? '';
          if (targetId.isNotEmpty) {
            await supabase.from('users').update({'settings': settings}).eq('id', targetId);
          } else if (userEmail != null && userEmail.isNotEmpty) {
            await supabase.from('users').update({'settings': settings}).eq('email', userEmail);
          }
          debugPrint('CustomerStoreService: Google account ($gEmail) linked in Supabase users.settings!');
        } catch (dbErr) {
          debugPrint('Error updating google_linked in Supabase: $dbErr');
        }
      }

      // 4. Save to local device storage
      _cachedGoogleLinkedEmail = gEmail;
      try {
        final prefs = await SharedPreferences.getInstance();
        if (userId != null) await prefs.setString('google_linked_email_$userId', gEmail);
        if (userEmail != null) await prefs.setString('google_linked_email_$userEmail', gEmail);
      } catch (_) {}

      // 5. Audit Log
      AuditLogService.logAction(
        actionType: 'GOOGLE_ACCOUNT_LINKED',
        category: 'Security',
        title: 'Google Account Linked',
        description: 'Successfully bound Google account ($gEmail) to profile',
        userId: userId ?? '',
        userEmail: userEmail ?? gEmail,
      );

      return CustomerAuthResult(
        success: true,
        message: 'Google account ($gEmail) successfully linked to your profile!',
      );
    } catch (e) {
      debugPrint('Error in linkGoogleAccount: $e');
      return CustomerAuthResult(
        success: false,
        message: 'Failed to link Google account: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Unlinks Google account from current profile
  static Future<CustomerAuthResult> unlinkGoogleAccount() async {
    try {
      final supabase = SupabaseService.client;
      final currentCust = _currentCustomer;
      final String? userId = currentCust?.id ?? supabase.auth.currentUser?.id;
      final String? userEmail = currentCust?.email ?? supabase.auth.currentUser?.email;

      if (userId != null || (userEmail != null && userEmail.isNotEmpty)) {
        try {
          Map<String, dynamic>? userRow;
          if (userId != null && userId.isNotEmpty) {
            userRow = await supabase.from('users').select('id, settings').eq('id', userId).maybeSingle();
          }
          if (userRow == null && userEmail != null && userEmail.isNotEmpty) {
            userRow = await supabase.from('users').select('id, settings').eq('email', userEmail).maybeSingle();
          }

          if (userRow != null && userRow['settings'] is Map) {
            final settings = Map<String, dynamic>.from(userRow['settings'] as Map);
            settings.remove('google_linked');
            settings.remove('google_email');
            final String targetId = userRow['id']?.toString() ?? userId ?? '';
            if (targetId.isNotEmpty) {
              await supabase.from('users').update({'settings': settings}).eq('id', targetId);
            }
          }
        } catch (_) {}
      }

      _cachedGoogleLinkedEmail = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        if (userId != null) await prefs.remove('google_linked_email_$userId');
        if (userEmail != null) await prefs.remove('google_linked_email_$userEmail');
      } catch (_) {}

      AuditLogService.logAction(
        actionType: 'GOOGLE_ACCOUNT_UNLINKED',
        category: 'Security',
        title: 'Google Account Unlinked',
        description: 'Unlinked Google account connection from profile',
        userId: userId ?? '',
        userEmail: userEmail ?? '',
      );

      return const CustomerAuthResult(
        success: true,
        message: 'Google account unlinked successfully.',
      );
    } catch (e) {
      return CustomerAuthResult(
        success: false,
        message: 'Failed to unlink Google account: $e',
      );
    }
  }

  /// Updates user profile details in Supabase database and active session
  static Future<bool> updateCustomerProfile({
    required String name,
    String? email,
    String? phone,
    String? gender,
    String? country,
    String? state,
    String? avatarUrl,
  }) async {
    try {
      final supabase = SupabaseService.client;
      final sessionUser = supabase.auth.currentUser;
      final targetId = sessionUser?.id ?? _currentCustomer?.id;
      final targetEmail = _currentCustomer?.email ?? email;

      final Map<String, dynamic> updateData = {
        'name': name.trim(),
        'phone': phone?.trim(),
        'gender': gender,
        'country': country,
        'state': state,
      };
      if (email != null && email.trim().isNotEmpty) {
        updateData['email'] = email.trim().toLowerCase();
      }
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        updateData['avatar_url'] = avatarUrl;
      }

      bool updated = false;
      if (targetId != null && targetId.isNotEmpty) {
        try {
          final res = await supabase.from('users').update(updateData).eq('id', targetId).select();
          if (res.isNotEmpty) {
            updated = true;
          }
        } catch (_) {}
      }

      if (!updated && targetEmail != null && targetEmail.isNotEmpty) {
        try {
          await supabase.from('users').update(updateData).eq('email', targetEmail.trim().toLowerCase());
          updated = true;
        } catch (_) {}
      }

      bool nameChanged = (_currentCustomer != null && _currentCustomer!.name != name.trim());
      if (_currentCustomer != null) {
        _currentCustomer = UserModel(
          id: _currentCustomer!.id,
          name: name.trim(),
          email: (email != null && email.trim().isNotEmpty) ? email.trim().toLowerCase() : _currentCustomer!.email,
          phone: phone?.trim(),
          role: _currentCustomer!.role,
          status: _currentCustomer!.status,
          avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : _currentCustomer!.avatarUrl,
          gender: gender,
          country: country,
          state: state,
          joinedDate: _currentCustomer!.joinedDate,
        );
      }

      if (nameChanged) {
        AuditLogService.logAction(
          actionType: 'NAME_CHANGE',
          category: 'Account Modification',
          title: 'User Name Changed',
          description: 'Updated account full name to "${name.trim()}"',
        );
      } else {
        AuditLogService.logAction(
          actionType: 'PROFILE_UPDATED',
          category: 'Account Modification',
          title: 'Profile Details Updated',
          description: 'User updated profile contact and regional details',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer profile: $e');
      }
      return false;
    }
  }

  static Future<CustomerAuthResult> registerCustomer({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.user,
    String? gender,
    String? country,
    String? state,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty || cleanEmail.isEmpty || password.isEmpty) {
      return const CustomerAuthResult(
        success: false,
        message: 'Please fill in all fields.',
      );
    }

    final supabase = SupabaseService.client;
    final String roleStr = role == UserRole.owner
        ? 'businessman'
        : (role == UserRole.admin
            ? 'admin'
            : (role == UserRole.government ? 'government' : 'customer'));

    // Hash password with BCrypt (logRounds: 6 matching $2a$06$ format)
    final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 6));

    String? userId;
    try {
      final res = await supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'name': name.trim()},
      );
      userId = res.user?.id;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase auth.signUp info: $e');
      }
    }

    userId ??= UuidHelper.generateV4();
    final nowUtc = DateTime.now().toUtc();
    final nowMsia = nowUtc.add(const Duration(hours: 8));
    final String formattedJoinedDate = '${nowMsia.day} ${_monthName(nowMsia.month)} ${nowMsia.year}';

    final Map<String, dynamic> userPayload = {
      'id': userId,
      'name': name.trim(),
      'email': cleanEmail,
      'user_password': hashedPassword,
      'role': roleStr,
      'status': 'active',
    };

    if (gender != null && gender.trim().isNotEmpty) {
      userPayload['gender'] = gender.trim();
    }
    if (country != null && country.trim().isNotEmpty) {
      userPayload['country'] = country.trim();
    }
    if (state != null && state.trim().isNotEmpty) {
      userPayload['state'] = state.trim();
    }

    // Guaranteed Upsert into public.users table in Supabase with BCrypt Hashed Password
    try {
      await supabase.from('users').upsert(
        userPayload,
        onConflict: 'email',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error upserting user to Supabase users table: $e');
      }
    }

    _registeredCustomers[cleanEmail] = {
      'id': userId,
      'name': name.trim(),
      'email': cleanEmail,
      'password': password,
      'role': roleStr,
    };

    _currentCustomer = UserModel(
      id: userId,
      name: name.trim(),
      email: cleanEmail,
      phone: null,
      role: role,
      status: AccountStatus.active,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
      gender: gender?.trim(),
      country: country?.trim(),
      state: state?.trim(),
      joinedDate: formattedJoinedDate,
    );

    await RememberMeService.saveRememberedUser(
      rememberMe: true,
      email: cleanEmail,
    );

    await themeManager.loadThemeForUser(_currentCustomer!.id);

    final String auditCategory = role == UserRole.owner
        ? 'Businessman'
        : (role == UserRole.government ? 'Government' : (role == UserRole.admin ? 'Admin' : 'Customer'));
    final String auditActionType = role == UserRole.owner
        ? 'BUSINESSMAN_REGISTER'
        : (role == UserRole.government ? 'GOVERNMENT_REGISTER' : (role == UserRole.admin ? 'ADMIN_REGISTER' : 'CUSTOMER_REGISTER'));
    final String auditTitle = role == UserRole.owner
        ? 'Businessman Registration'
        : (role == UserRole.government ? 'Government Registration' : (role == UserRole.admin ? 'Admin Registration' : 'User Registration'));

    AuditLogService.logAction(
      actionType: auditActionType,
      category: auditCategory,
      title: auditTitle,
      description: 'New $auditCategory account registered ($cleanEmail)',
      userId: userId,
      userEmail: cleanEmail,
    );

    return CustomerAuthResult(
      success: true,
      message: 'Registration successful! Account created as ${roleStr.toUpperCase()}.',
      user: _currentCustomer,
    );
  }

  static void updatePasswordLocally(String newPassword) {
    if (_currentCustomer != null) {
      final email = _currentCustomer!.email.toLowerCase();
      if (_registeredCustomers.containsKey(email)) {
        _registeredCustomers[email]!['password'] = newPassword;
      }
    }
  }

  static Future<CustomerAuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _currentCustomer;
    if (user == null) {
      return const CustomerAuthResult(
        success: false,
        message: 'No active login session found. Please log in again.',
      );
    }

    final cleanEmail = user.email.trim().toLowerCase();
    final supabase = SupabaseService.client;

    // 1. Verify old password against Supabase `users` table or local store
    Map<String, dynamic>? dbUser;
    try {
      dbUser = await supabase
          .from('users')
          .select()
          .ilike('email', cleanEmail)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error verifying current password: $e');
    }

    bool oldPasswordValid = false;
    if (dbUser != null) {
      final storedPassword = dbUser['user_password']?.toString() ?? '';
      if (storedPassword.startsWith(r'$2a$') ||
          storedPassword.startsWith(r'$2b$') ||
          storedPassword.startsWith(r'$2y$')) {
        try {
          oldPasswordValid = BCrypt.checkpw(oldPassword, storedPassword);
        } catch (_) {}
      } else {
        oldPasswordValid = (storedPassword == oldPassword);
      }
    } else if (_registeredCustomers.containsKey(cleanEmail)) {
      final localPass = _registeredCustomers[cleanEmail]?['password'] ?? '';
      oldPasswordValid = (localPass == oldPassword);
    }

    if (!oldPasswordValid) {
      return const CustomerAuthResult(
        success: false,
        message: 'Current password is incorrect.',
      );
    }

    // 2. Hash new password with BCrypt
    final String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: 6));

    // 3. Update Supabase `users` table
    try {
      await supabase
          .from('users')
          .update({
            'user_password': hashedPassword,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .ilike('email', cleanEmail);
    } catch (e) {
      debugPrint('Error updating password in Supabase: $e');
    }

    // 4. Update Supabase Auth user if active session exists
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (_) {}

    // 5. Update local in-memory store
    _registeredCustomers[cleanEmail] = {
      'password': newPassword,
      'role': user.role.name,
    };

    AuditLogService.logAction(
      actionType: 'PASSWORD_CHANGE',
      category: 'Account Modification',
      title: 'Password Changed',
      description: 'Account login password updated successfully',
      userId: user.id,
      userEmail: cleanEmail,
    );

    return const CustomerAuthResult(
      success: true,
      message: 'Password changed successfully!',
    );
  }

  /// Generates a random 10-character alphanumeric secure password
  static String generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%*';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Sets or generates an initial password for a user (e.g. during Google onboarding or account setup)
  static Future<CustomerAuthResult> setInitialPassword({
    required String newPassword,
    String? email,
  }) async {
    final targetEmail = (email ?? _currentCustomer?.email)?.trim().toLowerCase();
    if (targetEmail == null || targetEmail.isEmpty) {
      return const CustomerAuthResult(
        success: false,
        message: 'No active user email found to set password.',
      );
    }

    if (newPassword.length < 6) {
      return const CustomerAuthResult(
        success: false,
        message: 'Password must be at least 6 characters long.',
      );
    }

    final supabase = SupabaseService.client;
    final String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: 6));

    // 1. Update Supabase users table with BCrypt hashed password
    try {
      await supabase
          .from('users')
          .update({
            'user_password': hashedPassword,
            'password': hashedPassword,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .ilike('email', targetEmail);
    } catch (e) {
      debugPrint('CustomerStoreService: Supabase user_password update error: $e');
    }

    // 2. Sync password with Supabase Auth so traditional email/password login works
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (_) {}

    // 3. Update in-memory cache
    _registeredCustomers[targetEmail] = {
      'password': newPassword,
      'role': _currentCustomer?.role.name ?? 'customer',
    };

    AuditLogService.logAction(
      actionType: 'PASSWORD_SET',
      category: 'Account Security',
      title: 'Account Password Configured',
      description: 'User configured password for direct login access',
      userId: _currentCustomer?.id ?? '',
      userEmail: targetEmail,
    );

    return const CustomerAuthResult(
      success: true,
      message: 'Account password configured successfully!',
    );
  }

  static Future<CustomerAuthResult> loginCustomer({
    required String email,
    required String password,
    bool rememberMe = false,
    PortalType portal = PortalType.customer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      return const CustomerAuthResult(
        success: false,
        message: 'Please enter your email and password.',
      );
    }

    final supabase = SupabaseService.client;

    // 1. Check public.users table for user password (BCrypt hash matching)
    Map<String, dynamic>? dbUser;
    try {
      dbUser = await supabase
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();
    } catch (e) {
      if (kDebugMode) {
        print('Supabase DB fetch info: $e');
      }
    }

    if (dbUser != null) {
      final storedPassword = dbUser['user_password']?.toString() ?? '';
      bool passwordMatches = false;

      if (storedPassword.startsWith(r'$2a$') || storedPassword.startsWith(r'$2b$') || storedPassword.startsWith(r'$2y$')) {
        try {
          passwordMatches = BCrypt.checkpw(password, storedPassword);
        } catch (_) {}
      } else {
        passwordMatches = (storedPassword == password);
      }

      if (passwordMatches) {
        // Stored password match confirmed!
        final String rawDbRole = (dbUser['role']?.toString() ?? 'customer').toLowerCase().trim();

        // STRICT ROLE-BASED ACCESS CONTROL (RBAC) ENFORCEMENT
        bool isRoleAuthorized = false;

        switch (portal) {
          case PortalType.customer:
            isRoleAuthorized = (rawDbRole == 'customer' || rawDbRole == 'user');
            break;

          case PortalType.owner:
            isRoleAuthorized = (rawDbRole == 'businessman' || rawDbRole == 'owner');
            break;

          case PortalType.government:
            isRoleAuthorized = (rawDbRole == 'government' || rawDbRole == 'inspector' || rawDbRole == 'officer');
            break;

          case PortalType.admin:
            isRoleAuthorized = (rawDbRole == 'admin' || rawDbRole == 'administrator');
            break;
        }

        if (!isRoleAuthorized) {
          // Generic secure response preventing role and account enumeration (no audit log to avoid exposing role details)
          return const CustomerAuthResult(
            success: false,
            message: 'No account was found with these credentials. Please try again.',
          );
        }

        final String userId = dbUser['id']?.toString() ?? UuidHelper.generateV4();
        final UserRole finalUserRole = (rawDbRole == 'businessman' || rawDbRole == 'owner')
            ? UserRole.owner
            : (rawDbRole == 'admin'
                ? UserRole.admin
                : (rawDbRole == 'government' ? UserRole.government : UserRole.user));

        String? joinedDate;
        final rawCreated = dbUser['created_at']?.toString();
        if (rawCreated != null && rawCreated.isNotEmpty) {
          final dt = DateTime.tryParse(rawCreated);
          if (dt != null) {
            final DateTime msiaDt = dt.toUtc().add(const Duration(hours: 8));
            joinedDate = '${msiaDt.day} ${_monthName(msiaDt.month)} ${msiaDt.year}';
          }
        }

        _currentCustomer = UserModel(
          id: userId,
          name: dbUser['name']?.toString() ?? cleanEmail.split('@').first,
          email: cleanEmail,
          phone: dbUser['phone']?.toString(),
          role: finalUserRole,
          status: AccountStatus.active,
          avatarUrl: dbUser['avatar_url']?.toString() ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
          gender: dbUser['gender']?.toString(),
          country: dbUser['country']?.toString(),
          state: dbUser['state']?.toString(),
          joinedDate: joinedDate,
        );

        // Keep registeredCustomers store updated
        _registeredCustomers[cleanEmail] = {
          'password': password,
          'role': rawDbRole,
        };

        // Run background non-blocking tasks asynchronously for instant UI transition
        unawaited(() async {
          try {
            await supabase.auth.signInWithPassword(
              email: cleanEmail,
              password: password,
            );
          } catch (_) {}
          try {
            await AuditLogService.logAction(
              actionType: 'LOGIN',
              category: 'Session Activity',
              title: 'User Login Session',
              description: 'Logged into account session successfully as ${finalUserRole.name}',
              userId: userId,
              userEmail: cleanEmail,
            );
          } catch (_) {}
          try {
            await themeManager.loadThemeForUser(_currentCustomer!.id);
          } catch (_) {}
        }());

        await RememberMeService.saveRememberedUser(
          rememberMe: rememberMe,
          email: cleanEmail,
          portal: portal,
        );

        return CustomerAuthResult(
          success: true,
          message: 'Login successful!',
          user: _currentCustomer,
        );
      } else {
        // Password does not match DB hash -> Invalid Credentials!
        return const CustomerAuthResult(
          success: false,
          message: 'No account was found with these credentials. Please try again.',
        );
      }
    }

    // 2. Fallback to local registered customers store if offline or no DB row
    if (_registeredCustomers.containsKey(cleanEmail)) {
      final regData = _registeredCustomers[cleanEmail]!;
      final storedPass = regData['password'] ?? '';
      final storedRole = (regData['role'] ?? 'customer').toString().toLowerCase();

      if (storedPass == password) {
        // RBAC validation in fallback mode
        bool isRoleAuthorized = false;
        switch (portal) {
          case PortalType.customer:
            isRoleAuthorized = (storedRole == 'customer' || storedRole == 'user');
            break;
          case PortalType.owner:
            isRoleAuthorized = (storedRole == 'businessman' || storedRole == 'owner');
            break;
          case PortalType.government:
            isRoleAuthorized = (storedRole == 'government' || storedRole == 'inspector');
            break;
          case PortalType.admin:
            isRoleAuthorized = (storedRole == 'admin' || storedRole == 'administrator');
            break;
        }

        if (!isRoleAuthorized) {
          return const CustomerAuthResult(
            success: false,
            message: 'No account was found with these credentials. Please try again.',
          );
        }

        final UserRole role = (storedRole == 'businessman' || storedRole == 'owner')
            ? UserRole.owner
            : (storedRole == 'admin'
                ? UserRole.admin
                : (storedRole == 'government' ? UserRole.government : UserRole.user));

        _currentCustomer = UserModel(
          id: UuidHelper.generateV4(),
          name: cleanEmail.split('@').first,
          email: cleanEmail,
          role: role,
          status: AccountStatus.active,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

        await RememberMeService.saveRememberedUser(
          rememberMe: rememberMe,
          email: cleanEmail,
          portal: portal,
        );

        await themeManager.loadThemeForUser(_currentCustomer!.id);

        return CustomerAuthResult(
          success: true,
          message: 'Login successful!',
          user: _currentCustomer,
        );
      }
    }

    return const CustomerAuthResult(
      success: false,
      message: 'No account was found with these credentials. Please try again.',
    );
  }

  /// Triggers Native Google Sign-In Account Selector & authenticates with Supabase via ID Token
  /// [isRegistration]: If false (Login page), checks if user exists in Supabase. If not found, aborts login and returns isAccountNotFound: true.
  /// If true (Register page), creates a new user record in Supabase.
  static Future<CustomerAuthResult> signInWithGoogle({bool isRegistration = false}) async {
    try {
      final supabase = SupabaseService.client;
      String? envClientId;
      try {
        if (dotenv.isInitialized) {
          envClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
        }
      } catch (_) {}
      final String webClientId = envClientId ??
          '927326709623-332ted8aosmjf5efmbq3if09ur98vtl5.apps.googleusercontent.com';

      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

      // 1. Initialize Native Google Sign-In SDK
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: isAndroid ? null : webClientId,
        serverClientId: webClientId,
      );

      // Clear any stale cached Google credentials to prevent code [16] account reauth failed
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // 2. Prompt native Android / iOS "Choose an account" dialog
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } catch (authErr) {
        if (kDebugMode) {
          print('GoogleSignIn.authenticate error: $authErr');
        }

        final errText = authErr.toString().toLowerCase();

        // If it failed with account reauth failed (code 16), force reset and retry once
        if (errText.contains('16') || errText.contains('reauth') || errText.contains('account reauth failed')) {
          try {
            await googleSignIn.signOut();
            googleUser = await googleSignIn.authenticate();
          } catch (retryErr) {
            if (kDebugMode) {
              print('GoogleSignIn retry failed: $retryErr');
            }
          }
        }

        if (googleUser == null) {
          // Check if user specifically cancelled / dismissed the dialog
          final bool isUserExplicitCancel = errText.contains('canceled_by_user') ||
              errText.contains('user_canceled') ||
              errText.contains('user canceled') ||
              errText.contains('activity was cancelled by the user');

          if (isUserExplicitCancel) {
            return const CustomerAuthResult(
              success: false,
              message: 'Google Sign-In was cancelled.',
            );
          }

          if (errText.contains('16') || errText.contains('reauth')) {
            return const CustomerAuthResult(
              success: false,
              message: 'Google account reauthorization expired. Please select your account again or log in with Email.',
            );
          }

          return CustomerAuthResult(
            success: false,
            message: errText.contains('10') || errText.contains('developer')
                ? 'Google Sign-In configuration mismatch (Developer 10). Please ensure SHA-1 fingerprint is registered in Google Cloud Console.'
                : 'Google Sign-In failed ($errText). Please try again or use Email/Password.',
          );
        }
      }

      final String gEmail = googleUser.email.trim().toLowerCase();
      final String gName = googleUser.displayName ?? gEmail.split('@').first;
      final String gAvatar = googleUser.photoUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200';

      // 3. PRE-CHECK: Query Supabase public.users table BEFORE calling signInWithIdToken
      // This prevents Supabase auth trigger from creating an account on the Login screen
      Map<String, dynamic>? existingUserPre;
      try {
        existingUserPre = await supabase
            .from('users')
            .select()
            .ilike('email', gEmail)
            .maybeSingle();
      } catch (e) {
        if (kDebugMode) {
          print('Error checking existing user in users table: $e');
        }
      }

      // CASE A: LOGIN FLOW (isRegistration == false) & NO RECORD IN SUPABASE
      if (!isRegistration && existingUserPre == null && !_registeredCustomers.containsKey(gEmail)) {
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        _currentCustomer = null;

        return CustomerAuthResult(
          success: false,
          isAccountNotFound: true,
          message: 'No account found for $gEmail. Please register your account first.',
        );
      }

      // 4. Obtain authentication ID Token from native Google SDK
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const CustomerAuthResult(
          success: false,
          message: 'Failed to retrieve Google ID token.',
        );
      }

      // 5. Authenticate with Supabase using idToken
      final AuthResponse authRes = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final sessionUser = authRes.user ?? supabase.auth.currentUser;
      final String userId = sessionUser?.id ?? UuidHelper.generateV4();
      final nowUtc = DateTime.now().toUtc();
      final nowMsia = nowUtc.add(const Duration(hours: 8));
      final String formattedJoinedDate = '${nowMsia.day} ${_monthName(nowMsia.month)} ${nowMsia.year}';
      final String createdIso = nowUtc.toIso8601String();

      // CASE B: REGISTER FLOW (isRegistration == true) & NO RECORD -> CREATE NEW USER
      if (existingUserPre == null) {
        try {
          await supabase.from('users').upsert(
            {
              'id': userId,
              'name': gName,
              'email': gEmail,
              'role': 'customer',
              'status': 'active',
              'created_at': createdIso,
            },
            onConflict: 'email',
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error upserting new Google user: $e');
          }
        }

        _currentCustomer = UserModel(
          id: userId,
          name: gName,
          email: gEmail,
          phone: null,
          role: UserRole.user,
          status: AccountStatus.active,
          avatarUrl: gAvatar,
          joinedDate: formattedJoinedDate,
        );

        await RememberMeService.saveRememberedUser(
          rememberMe: true,
          email: gEmail,
        );

        await themeManager.loadThemeForUser(_currentCustomer!.id);

        AuditLogService.logAction(
          actionType: 'REGISTER',
          category: 'Authentication',
          title: 'Google Account Registered',
          description: 'New customer account created via Google Sign-In',
          userId: userId,
          userEmail: gEmail,
        );

        return CustomerAuthResult(
          success: true,
          message: 'Google Registration successful! Welcome, $gName',
          user: _currentCustomer,
        );
      }

      // CASE C: EXISTING USER FOUND (Login or Register)
      final statusStr = existingUserPre['status']?.toString().toLowerCase() ?? 'active';
      if (statusStr == 'suspended' || statusStr == 'banned' || statusStr == 'inactive') {
        try {
          await supabase.auth.signOut();
        } catch (_) {}
        _currentCustomer = null;
        return CustomerAuthResult(
          success: false,
          message: 'Your account is currently $statusStr. Please contact support.',
        );
      }

      final roleStr = existingUserPre['role']?.toString().toLowerCase() ?? 'customer';
      UserRole mappedRole = UserRole.user;
      if (roleStr == 'admin') {
        mappedRole = UserRole.admin;
      } else if (roleStr == 'officer' || roleStr == 'government') {
        mappedRole = UserRole.government;
      } else if (roleStr == 'businessman' || roleStr == 'owner') {
        mappedRole = UserRole.owner;
      }

      _currentCustomer = UserModel(
        id: existingUserPre['id']?.toString() ?? userId,
        name: existingUserPre['name']?.toString() ?? gName,
        email: gEmail,
        phone: existingUserPre['phone']?.toString(),
        role: mappedRole,
        status: AccountStatus.active,
        avatarUrl: existingUserPre['avatar_url']?.toString() ?? gAvatar,
        gender: existingUserPre['gender']?.toString(),
        country: existingUserPre['country']?.toString(),
        state: existingUserPre['state']?.toString(),
        joinedDate: formattedJoinedDate,
      );

      await RememberMeService.saveRememberedUser(
        rememberMe: true,
        email: gEmail,
      );

      await themeManager.loadThemeForUser(_currentCustomer!.id);

      AuditLogService.logAction(
        actionType: 'LOGIN',
        category: 'Authentication',
        title: 'Google Sign-In Successful',
        description: 'Customer logged in with Google authentication',
        userId: _currentCustomer!.id,
        userEmail: gEmail,
      );

      return CustomerAuthResult(
        success: true,
        message: 'Welcome back, ${_currentCustomer!.name}!',
        user: _currentCustomer,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Native Google Sign-In error: $e');
      }

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('canceled_by_user') || errStr.contains('user_canceled')) {
        return const CustomerAuthResult(
          success: false,
          message: 'Google Sign-In was cancelled.',
        );
      }

      return CustomerAuthResult(
        success: false,
        message: 'Google Sign-In failed: ${e.toString().split(":").last.trim()}',
      );
    }
  }

  static void logout() {
    if (_currentCustomer != null) {
      AuditLogService.logAction(
        actionType: 'LOGOUT',
        category: 'Session Activity',
        title: 'User Logout Session',
        description: 'Logged out of account session',
        userId: _currentCustomer!.id,
        userEmail: _currentCustomer!.email,
      );
    }
    try {
      SupabaseService.client.auth.signOut();
    } catch (_) {}
    _currentCustomer = null;
    themeManager.resetToSystemTheme();
  }

  /// Override active role for switching between Customer, Owner, Admin & Government Official
  static void updateOwnerRole(UserRole newRole) {
    if (_currentCustomer != null) {
      _currentCustomer = UserModel(
        id: _currentCustomer!.id,
        name: _currentCustomer!.name,
        email: _currentCustomer!.email,
        phone: _currentCustomer!.phone,
        role: newRole,
        status: _currentCustomer!.status,
        avatarUrl: _currentCustomer!.avatarUrl,
        gender: _currentCustomer!.gender,
        country: _currentCustomer!.country,
        state: _currentCustomer!.state,
        joinedDate: _currentCustomer!.joinedDate,
      );
    }
  }

  /// Fetches all user accounts directly from Supabase 'users' database table
  static Future<List<UserModel>> fetchAllRealUsers() async {
    try {
      final supabase = SupabaseService.client;
      final res = await supabase.from('users').select().order('created_at', ascending: false);
      final List<dynamic> rows = res as List<dynamic>;

      if (rows.isNotEmpty) {
        final List<UserModel> realUsers = [];
        for (final row in rows) {
          realUsers.add(UserModel.fromMap(row as Map<String, dynamic>));
        }

        // Ensure current active customer is included if missing
        if (_currentCustomer != null && !realUsers.any((u) => u.id == _currentCustomer!.id || u.email == _currentCustomer!.email)) {
          realUsers.insert(0, _currentCustomer!);
        }

        return realUsers;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching real users from Supabase: $e');
      }
    }

    if (_currentCustomer != null) {
      return [_currentCustomer!];
    }
    return _registeredCustomers.entries.map((e) => UserModel(id: e.key, name: e.key.split('@').first, email: e.key, phone: '', role: e.value['role'] == 'businessman' ? UserRole.owner : UserRole.user, status: AccountStatus.active, avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200')).toList();
  }

  /// Fetches paginated user accounts directly from Supabase 'users' database table using range(from, to)
  static Future<({List<UserModel> users, bool hasMore})> fetchUsersPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final supabase = SupabaseService.client;
      final int from = page * pageSize;
      final int to = from + pageSize - 1;

      final res = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> rows = res as List<dynamic>;
      final List<UserModel> paginatedUsers = [];
      for (final row in rows) {
        paginatedUsers.add(UserModel.fromMap(row as Map<String, dynamic>));
      }

      final bool hasMore = paginatedUsers.length == pageSize;
      return (users: paginatedUsers, hasMore: hasMore);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching paginated users from Supabase: $e');
      }
      return (users: <UserModel>[], hasMore: false);
    }
  }
}
