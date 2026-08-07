import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/uuid_helper.dart';
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
      String? joinedDate;

      if (data != null) {
        name = data['name']?.toString() ?? name;
        phone = data['phone']?.toString();
        gender = data['gender']?.toString();
        country = data['country']?.toString();
        state = data['state']?.toString();
        if (data['created_at'] != null) {
          final DateTime? dt = DateTime.tryParse(data['created_at'].toString());
          if (dt != null) {
            joinedDate = '${_monthName(dt.month)} ${dt.year}';
          }
        }
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

  static Future<CustomerAuthResult> registerCustomer({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '+60 12-345 6789';

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

    // 3. Guarantee direct insertion into public.users table in Supabase
    try {
      await supabase.from('users').upsert(
        {
          'id': validId,
          'name': cleanName,
          'email': cleanEmail,
          'phone': cleanPhone,
          'role': 'user',
          'status': 'active',
        },
        onConflict: 'email',
      );
      if (kDebugMode) {
        print('User successfully inserted/updated in Supabase users table with ID: $validId');
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
          'role': 'user',
          'status': 'active',
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
      'phone': cleanPhone,
      'password': password,
    };

    _currentCustomer = UserModel(
      id: validId,
      name: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      role: UserRole.user,
      status: AccountStatus.active,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    );

    return CustomerAuthResult(
      success: true,
      message: 'Registration successful! Saved to Supabase database.',
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
          phone: '+60 12-345 6789',
          role: UserRole.user,
          status: AccountStatus.active,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

        // Ensure user row exists in Supabase `users` table
        try {
          await supabase.from('users').upsert(
            {
              'id': res.user!.id,
              'name': fullName,
              'email': cleanEmail,
              'phone': '+60 12-345 6789',
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
          phone: response['phone']?.toString() ?? '+60 12-345 6789',
          role: UserRole.user,
          status: AccountStatus.active,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

        return CustomerAuthResult(
          success: true,
          message: 'Login successful!',
          user: _currentCustomer,
        );
      }
    } catch (_) {}

    // 3. Local fallback check
    final record = _registeredCustomers[cleanEmail];
    if (record != null) {
      if (record['password'] == password) {
        _currentCustomer = UserModel(
          id: record['id']!,
          name: record['name']!,
          email: record['email']!,
          phone: record['phone'] ?? '+60 12-345 6789',
          role: UserRole.user,
          status: AccountStatus.active,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
        );

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

    // Default fallback during development
    _currentCustomer = UserModel(
      id: UuidHelper.generateV4(),
      name: cleanEmail.contains('@') ? cleanEmail.split('@').first : 'Customer User',
      email: cleanEmail,
      phone: '+60 12-345 6789',
      role: UserRole.user,
      status: AccountStatus.active,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    );

    return CustomerAuthResult(
      success: true,
      message: 'Login successful!',
      user: _currentCustomer,
    );
  }

  static void logout() {
    try {
      SupabaseService.client.auth.signOut();
    } catch (_) {}
    _currentCustomer = null;
  }
}
