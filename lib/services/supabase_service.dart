import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  @visibleForTesting
  static set instance(SupabaseService value) => _instance = value;

  SupabaseService._();

  SupabaseClient? _mockClient;

  @visibleForTesting
  set mockClient(SupabaseClient client) => _mockClient = client;

  SupabaseClient get client => _mockClient ?? Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      await client.from('users').select('nrp').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Login with NRP and password
  Future<Map<String, dynamic>?> loginWithNRP({
    required String nrp,
    required String password,
  }) async {
    try {
      final response = await client
          .from('users')
          .select('id, nrp, name, jabatan, sisa_cuti, updated_at')
          .eq('nrp', nrp)
          .eq('password', password)
          .maybeSingle();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get user by NRP
  Future<Map<String, dynamic>?> getUserByNRP(String nrp) async {
    try {
      final response = await client
          .from('users')
          .select('id, nrp, name, jabatan, sisa_cuti, updated_at')
          .eq('nrp', nrp)
          .maybeSingle();

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
