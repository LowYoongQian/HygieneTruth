import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  const CustomerAuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class CustomerStoreService {
  static UserModel? _currentCustomer;

  static UserModel? get currentCustomer => _currentCustomer;

  static final Map<String, Map<String, String>> _registeredCustomers = {};

  /// Fetches real user profile for the current active Supabase Auth session
  static Future<UserModel?> fetchActiveUserSession() async {
    try {
      final supabase = SupabaseService.client;
      final sessionUser = supabase.auth.currentUser;
      
      if (sessionUser == null) {
        return _currentCustomer;
      }

      final String userId = sessionUser.id;
      final String userEmail = sessionUser.email ?? '';

      // Query real user row from public.users table in Supabase
      final Map<String, dynamic>? data = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      String name = sessionUser.userMetadata?['name'] as String? ?? (userEmail.isNotEmpty ? userEmail.split('@').first : 'User');
      String? phone;
      String? gender;
      String? country;
      String? state;
      String avatarUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200';

      if (data != null) {
        name = data['name']?.toString() ?? name;
        phone = data['phone']?.toString();
        gender = data['gender']?.toString();
        country = data['country']?.toString();
        state = data['state']?.toString();
        if (data['avatar_url'] != null && data['avatar_url'].toString().trim().isNotEmpty) {
          avatarUrl = data['avatar_url'].toString().trim();
        }
        if (data['language'] != null) {
          final langIdx = int.tryParse(data['language'].toString());
          if (langIdx != null) {
            languageManager.updateLanguageFromDatabase(langIdx);
          }
        }
      }

      String? joinedDate;
      final rawCreated = data?['created_at']?.toString() ?? sessionUser.createdAt;
      if (rawCreated.isNotEmpty) {
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
        id: userId,
        name: name,
        email: userEmail,
        phone: phone,
        role: UserRole.user,
        status: AccountStatus.active,
        avatarUrl: avatarUrl,
        gender: gender,
        country: country,
        state: state,
        joinedDate: joinedDate,
      );

      themeManager.loadThemeForUser(userId);

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

  /// Checks if current Supabase session is linked to a Google auth provider
  static bool isGoogleLinked() {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;
    final provider = user.appMetadata['provider']?.toString();
    if (provider == 'google') return true;
    final identities = user.identities;
    if (identities != null) {
      return identities.any((id) => id.provider.toLowerCase() == 'google');
    }
    return false;
  }

  /// Returns linked Google account email address if available
  static String getGoogleLinkedEmail() {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return '';
    if (isGoogleLinked()) {
      return user.email ?? '';
    }
    return '';
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
      if (sessionUser != null) {
        final Map<String, dynamic> updateData = {
          'name': name.trim(),
          'phone': phone?.trim(),
          'gender': gender,
          'country': country,
          'state': state,
        };
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          updateData['avatar_url'] = avatarUrl;
        }
        await supabase.from('users').update(updateData).eq('id', sessionUser.id);
      }
      bool nameChanged = (_currentCustomer != null && _currentCustomer!.name != name.trim());
      if (_currentCustomer != null) {
        _currentCustomer = UserModel(
          id: _currentCustomer!.id,
          name: name.trim(),
          email: _currentCustomer!.email,
          phone: phone,
          role: _currentCustomer!.role,
          status: _currentCustomer!.status,
          avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : _currentCustomer!.avatarUrl,
          gender: gender,
          country: country,
          state: state,
          joinedDate: _currentCustomer!.joinedDate,
        );
      }

      // Record audit log entry in Supabase & local history
      if (nameChanged) {
        AuditLogService.logAction(
          actionType: 'NAME_CHANGE',
          category: 'Account Modification',
          title: 'User Name Changed',
          description: 'Updated account full name to "${name.trim()}"',
        );
      } else {
        AuditLogService.logAction(
          actionType: 'PROFILE_UPDATE',
          category: 'Account Modification',
          title: 'Profile Updated',
          description: 'Updated personal profile details',
        );
      }

      return true;
    } catch (_) {
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

    return CustomerAuthResult(
      success: true,
      message: 'Registration successful! Account created as ${roleStr.toUpperCase()}.',
      user: _currentCustomer,
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
    final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 6));
    String targetRoleStr = portal == PortalType.owner ? 'businessman' : 'customer';

    // 1. Supabase Auth Sign In (authenticates against auth.users)
    try {
      final res = await supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (res.user != null) {
        final String authId = res.user!.id;
        final fullName = res.user!.userMetadata?['name'] as String? ?? cleanEmail.split('@').first;

        // Fetch existing public.users record to preserve existing role/details
        Map<String, dynamic>? existingDbUser;
        try {
          existingDbUser = await supabase
              .from('users')
              .select()
              .eq('email', cleanEmail)
              .maybeSingle();
        } catch (_) {}

        if (existingDbUser != null && existingDbUser['role'] != null) {
          targetRoleStr = existingDbUser['role'].toString();
        } else if (portal == PortalType.owner) {
          targetRoleStr = 'businessman';
        }

        final UserRole finalUserRole = (targetRoleStr == 'businessman' || targetRoleStr == 'owner')
            ? UserRole.owner
            : (targetRoleStr == 'admin'
                ? UserRole.admin
                : (targetRoleStr == 'government' ? UserRole.government : UserRole.user));

        // Sync auth.users session ID to public.users table (tight 1-to-1 UUID link)
        try {
          await supabase.from('users').upsert(
            {
              'id': authId,
              'name': fullName,
              'email': cleanEmail,
              'user_password': hashedPassword,
              'role': targetRoleStr,
              'status': 'active',
            },
            onConflict: 'email',
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing public.users table during login: $e');
          }
        }

        _currentCustomer = UserModel(
          id: authId,
          name: existingDbUser?['name']?.toString() ?? fullName,
          email: cleanEmail,
          phone: existingDbUser?['phone']?.toString(),
          role: finalUserRole,
          status: AccountStatus.active,
          avatarUrl: existingDbUser?['avatar_url']?.toString() ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

        AuditLogService.logAction(
          actionType: 'LOGIN',
          category: 'Session Activity',
          title: 'User Login Session',
          description: 'Logged into account session successfully',
          userId: authId,
          userEmail: cleanEmail,
        );

        await RememberMeService.saveRememberedUser(
          rememberMe: rememberMe,
          email: cleanEmail,
          portal: portal,
        );

        await themeManager.loadThemeForUser(_currentCustomer!.id);

        return CustomerAuthResult(
          success: true,
          message: 'Supabase login successful!',
          user: _currentCustomer,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase signInWithPassword info: $e');
      }
    }

    // 2. Direct DB table query check with BCrypt verification fallback
    try {
      final Map<String, dynamic>? response = await supabase
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();

      if (response != null) {
        final storedPassword = response['user_password']?.toString() ?? '';
        bool passwordMatches = false;

        if (storedPassword.startsWith(r'$2a$') || storedPassword.startsWith(r'$2b$') || storedPassword.startsWith(r'$2y$')) {
          try {
            passwordMatches = BCrypt.checkpw(password, storedPassword);
          } catch (_) {}
        } else {
          passwordMatches = (storedPassword == password);
        }

        if (passwordMatches) {
          final String dbRole = response['role']?.toString() ?? (portal == PortalType.owner ? 'businessman' : 'customer');
          final UserRole finalUserRole = (dbRole == 'businessman' || dbRole == 'owner')
              ? UserRole.owner
              : (dbRole == 'admin'
                  ? UserRole.admin
                  : (dbRole == 'government' ? UserRole.government : UserRole.user));

          // If stored password was plain text, auto-upgrade it to BCrypt hash in DB!
          if (!storedPassword.startsWith(r'$2a$')) {
            try {
              await supabase.from('users').update({
                'user_password': hashedPassword,
              }).eq('email', cleanEmail);
            } catch (_) {}
          }

          _currentCustomer = UserModel(
            id: response['id']?.toString() ?? UuidHelper.generateV4(),
            name: response['name']?.toString() ?? cleanEmail.split('@').first,
            email: cleanEmail,
            phone: response['phone']?.toString(),
            role: finalUserRole,
            status: AccountStatus.active,
            avatarUrl: response['avatar_url']?.toString() ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
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
    } catch (_) {}

    // 3. Registered in current session check
    final record = _registeredCustomers[cleanEmail];
    if (record != null) {
      if (record['password'] == password) {
        _currentCustomer = UserModel(
          id: record['id']!,
          name: record['name']!,
          email: record['email']!,
          phone: record['phone'],
          role: UserRole.user,
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
      } else {
        return const CustomerAuthResult(
          success: false,
          message: 'Incorrect password. Please try again.',
        );
      }
    }

    return const CustomerAuthResult(
      success: false,
      message: 'Account not found or wrong password.',
    );
  }

  /// Triggers Native Google Sign-In Account Selector & authenticates with Supabase via ID Token
  static Future<CustomerAuthResult> signInWithGoogle() async {
    try {
      final supabase = SupabaseService.client;
      final String webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
          '927326709623-332ted8aosmjf5efmbq3if09ur98vtl5.apps.googleusercontent.com';

      // 1. Initialize Native Google Sign-In SDK
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: webClientId,
        serverClientId: webClientId,
      );

      // 2. Prompt native Android / iOS "Choose an account" dialog
      final googleUser = await googleSignIn.authenticate();

      // 3. Obtain authentication ID Token from native Google SDK
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const CustomerAuthResult(
          success: false,
          message: 'Failed to retrieve Google ID token.',
        );
      }

      // 4. Authenticate with Supabase using idToken
      final AuthResponse authRes = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final sessionUser = authRes.user ?? supabase.auth.currentUser;
      final String gEmail = googleUser.email;
      final String gName = googleUser.displayName ?? gEmail.split('@').first;
      final String gAvatar = googleUser.photoUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200';
      final String userId = sessionUser?.id ?? UuidHelper.generateV4();
      final nowUtc = DateTime.now().toUtc();
      final nowMsia = nowUtc.add(const Duration(hours: 8));
      final String formattedJoinedDate = '${nowMsia.day} ${_monthName(nowMsia.month)} ${nowMsia.year}';
      final String createdIso = nowUtc.toIso8601String();

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
      } catch (_) {}

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

      return CustomerAuthResult(
        success: true,
        message: 'Google Sign-In successful for $gEmail',
        user: _currentCustomer,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Native Google Sign-In error: $e');
      }

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') || errStr.contains('abort') || errStr.contains('closed')) {
        return const CustomerAuthResult(
          success: false,
          message: 'Google Sign-In was cancelled.',
        );
      }

      // Check if user is already authenticated via active Supabase session
      final sessionUser = SupabaseService.client.auth.currentUser;
      if (sessionUser != null) {
        final activeUser = await fetchActiveUserSession();
        if (activeUser != null) {
          return CustomerAuthResult(
            success: true,
            message: 'Signed in as ${activeUser.email}',
            user: activeUser,
          );
        }
      }

      return const CustomerAuthResult(
        success: false,
        message: 'Google Sign-In was cancelled or failed.',
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
}
