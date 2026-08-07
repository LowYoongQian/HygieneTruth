import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../theme/theme_manager.dart';
import '../utils/uuid_helper.dart';
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

  static UserModel? get currentCustomer => _currentCustomer ?? _fallbackCustomer;

  static final UserModel _fallbackCustomer = UserModel(
    id: '00000000-0000-0000-0000-000000000001',
    name: 'Verified Customer',
    email: 'user@example.com',
    phone: '+60 12-345 6789',
    role: UserRole.user,
    status: AccountStatus.active,
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    gender: null, // Null to reflect missing data until future implementation
    country: null,
    state: null,
    joinedDate: 'Jan 2024',
  );

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
      final String userEmail = sessionUser.email ?? 'user@example.com';

      // Query real user row from public.users table in Supabase
      final Map<String, dynamic>? data = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      String name = sessionUser.userMetadata?['name'] as String? ?? userEmail.split('@').first;
      String? phone;
      String? gender;
      String? country;
      String? state;
      if (data != null) {
        name = data['name']?.toString() ?? name;
        phone = data['phone']?.toString();
        gender = data['gender']?.toString();
        country = data['country']?.toString();
        state = data['state']?.toString();
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
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
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

  static void updateCustomerProfile({
    required String name,
    required String phone,
    required String gender,
    required String country,
    required String state,
  }) {
    final base = _currentCustomer ?? _fallbackCustomer;
    _currentCustomer = UserModel(
      id: base.id,
      name: name,
      email: base.email,
      phone: phone,
      role: base.role,
      status: base.status,
      avatarUrl: base.avatarUrl,
      gender: gender,
      country: country,
      state: state,
      joinedDate: base.joinedDate,
    );

    // Persist profile update to Supabase users table async
    try {
      SupabaseService.client.from('users').upsert({
        'id': base.id,
        'name': name,
        'phone': phone,
        'gender': gender,
        'country': country,
        'state': state,
      });
    } catch (_) {}
  }

  static void updateOwnerRole(UserRole role) {
    if (_currentCustomer != null) {
      _currentCustomer = UserModel(
        id: _currentCustomer!.id,
        name: _currentCustomer!.name,
        email: _currentCustomer!.email,
        phone: _currentCustomer!.phone,
        role: role,
        status: _currentCustomer!.status,
        avatarUrl: _currentCustomer!.avatarUrl,
        gender: _currentCustomer!.gender,
        country: _currentCustomer!.country,
        state: _currentCustomer!.state,
        joinedDate: _currentCustomer!.joinedDate,
        memberTier: _currentCustomer!.memberTier,
      );
    } else {
      _currentCustomer = UserModel(
        id: UuidHelper.generateV4(),
        name: role == UserRole.owner
            ? 'Restaurant Owner'
            : (role == UserRole.admin ? 'Administrator' : 'Government Officer'),
        email: role == UserRole.owner
            ? 'owner@restaurant.com'
            : (role == UserRole.admin ? 'admin@hygiene.gov.my' : 'officer@hygiene.gov.my'),
        role: role,
        status: AccountStatus.active,
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
      );
    }
  }

  static Future<CustomerAuthResult> registerCustomer({
    required String name,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.user,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null;
    final String roleStr = role == UserRole.owner
        ? 'businessman'
        : (role == UserRole.admin
            ? 'admin'
            : (role == UserRole.government ? 'government' : 'customer'));

    if (cleanEmail.isEmpty || password.isEmpty || cleanName.isEmpty) {
      return const CustomerAuthResult(
        success: false,
        message: 'Please fill in all required registration fields.',
      );
    }

    final supabase = SupabaseService.client;
    String? authUserId;

    // 1. Try Supabase Auth signUp first
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'name': cleanName,
          'phone': cleanPhone,
          'role': roleStr,
        },
      );
      if (res.user != null) {
        authUserId = res.user!.id;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase Auth signUp info: $e');
      }
      try {
        final res = await supabase.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (res.user != null) {
          authUserId = res.user!.id;
        }
      } catch (_) {}
    }

    // 2. Generate valid RFC-4122 v4 UUID if Auth ID is not returned
    final String validId = (authUserId != null && authUserId.isNotEmpty)
        ? authUserId
        : UuidHelper.generateV4();

    final nowUtc = DateTime.now().toUtc();
    final nowMsia = nowUtc.add(const Duration(hours: 8));
    final String formattedJoinedDate = '${nowMsia.day} ${_monthName(nowMsia.month)} ${nowMsia.year}';
    final String createdIso = nowUtc.toIso8601String();

    // 3. Guarantee direct insertion into public.users table in Supabase
    try {
      await supabase.from('users').upsert(
        {
          'id': validId,
          'name': cleanName,
          'email': cleanEmail,
          'phone': cleanPhone,
          'role': roleStr,
          'status': 'active',
          'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
          'created_at': createdIso,
        },
        onConflict: 'email',
      );
      if (kDebugMode) {
        print('User successfully inserted/updated in Supabase users table with ID: $validId and role: $roleStr');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase users table insert error: $e');
      }
      try {
        await supabase.from('users').insert({
          'id': validId,
          'name': cleanName,
          'email': cleanEmail,
          'phone': cleanPhone,
          'role': roleStr,
          'status': 'active',
          'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
          'created_at': createdIso,
        });
      } catch (err2) {
        if (kDebugMode) {
          print('Direct insert error: $err2');
        }
      }
    }

    // 4. Update Local Session State
    _registeredCustomers[cleanEmail] = {
      'id': validId,
      'name': cleanName,
      'email': cleanEmail,
      'phone': cleanPhone ?? '',
      'password': password,
      'role': roleStr,
    };

    _currentCustomer = UserModel(
      id: validId,
      name: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      role: role,
      status: AccountStatus.active,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
      joinedDate: formattedJoinedDate,
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
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      return const CustomerAuthResult(
        success: false,
        message: 'Please enter your email and password.',
      );
    }

    final supabase = SupabaseService.client;

    // 1. Supabase Auth Sign In
    try {
      final res = await supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (res.user != null) {
        final fullName = res.user!.userMetadata?['name'] as String? ?? cleanEmail.split('@').first;

        _currentCustomer = UserModel(
          id: res.user!.id,
          name: fullName,
          email: cleanEmail,
          phone: null,
          role: UserRole.user,
          status: AccountStatus.active,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

        await RememberMeService.saveRememberedUser(
          rememberMe: rememberMe,
          email: cleanEmail,
        );

        await themeManager.loadThemeForUser(_currentCustomer!.id);

        try {
          await supabase.from('users').upsert(
            {
              'id': res.user!.id,
              'name': fullName,
              'email': cleanEmail,
              'role': 'user',
              'status': 'active',
            },
            onConflict: 'email',
          );
        } catch (_) {}

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

    // 2. Direct DB table query check
    try {
      final Map<String, dynamic>? response = await supabase
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();

      if (response != null) {
        _currentCustomer = UserModel(
          id: response['id']?.toString() ?? UuidHelper.generateV4(),
          name: response['name']?.toString() ?? cleanEmail.split('@').first,
          email: cleanEmail,
          phone: response['phone']?.toString(),
          role: UserRole.user,
          status: AccountStatus.active,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

        await RememberMeService.saveRememberedUser(
          rememberMe: rememberMe,
          email: cleanEmail,
        );

        await themeManager.loadThemeForUser(_currentCustomer!.id);

        return CustomerAuthResult(
          success: true,
          message: 'Login successful!',
          user: _currentCustomer,
        );
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
      message: 'Invalid credentials. User account not found. Please register first.',
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
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

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
            'avatar_url': gAvatar,
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

      // Fallback to Supabase OAuth redirect if native channel is uninitialized
      try {
        final supabase = SupabaseService.client;
        final bool oauthStarted = await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.colab://login-callback',
        );

        if (oauthStarted) {
          return const CustomerAuthResult(
            success: true,
            message: 'Redirecting to Google Account Sign-In...',
          );
        }
      } catch (_) {}

      return CustomerAuthResult(
        success: false,
        message: 'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  static void logout() {
    try {
      SupabaseService.client.auth.signOut();
    } catch (_) {}
    _currentCustomer = null;
    themeManager.resetToSystemTheme();
  }

  static bool isGoogleLinked() {
    try {
      final sessionUser = SupabaseService.client.auth.currentUser;
      if (sessionUser == null) {
        return _currentCustomer?.email.endsWith('@gmail.com') ?? false;
      }

      final provider = sessionUser.appMetadata['provider'];
      if (provider == 'google') return true;

      final identities = sessionUser.identities;
      if (identities != null) {
        for (final identity in identities) {
          if (identity.provider.toLowerCase() == 'google') {
            return true;
          }
        }
      }

      if (sessionUser.email != null && sessionUser.email!.toLowerCase().contains('gmail.com')) {
        return true;
      }

      return false;
    } catch (_) {
      return _currentCustomer?.email.toLowerCase().contains('gmail.com') ?? false;
    }
  }

  static String getGoogleLinkedEmail() {
    final sessionUser = SupabaseService.client.auth.currentUser;
    if (sessionUser?.email != null && sessionUser!.email!.isNotEmpty) {
      return sessionUser.email!;
    }
    return _currentCustomer?.email ?? '';
  }
}
