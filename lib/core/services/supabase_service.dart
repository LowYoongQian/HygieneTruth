import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String defaultUrl = 'https://edaoswrsigvpfudgxlwq.supabase.co';
  static const String defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkYW9zd3JzaWd2cGZ1ZGd4bHdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYwMTczODcsImV4cCI6MjEwMTU5MzM4N30.rOGAKwGLDUAzKuUSrsAECdME6vsMJNguFWX9Mongv_Y';

  static bool isInitialized = false;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    String? supabaseUrl;
    String? supabaseAnonKey;

    try {
      if (dotenv.isInitialized) {
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_KEY'];
      }
    } catch (_) {}

    supabaseUrl ??= const String.fromEnvironment('SUPABASE_URL', defaultValue: defaultUrl);
    supabaseAnonKey ??= const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: defaultAnonKey);

    final activeUrl = supabaseUrl.isNotEmpty ? supabaseUrl : defaultUrl;
    final activeKey = supabaseAnonKey.isNotEmpty ? supabaseAnonKey : defaultAnonKey;

    try {
      await Supabase.initialize(
        url: activeUrl,
        // ignore: deprecated_member_use
        anonKey: activeKey,
      );
      isInitialized = true;
    } catch (_) {
      try {
        Supabase.instance.client;
        isInitialized = true;
      } catch (_) {
        isInitialized = false;
      }
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
