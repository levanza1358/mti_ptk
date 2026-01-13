import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://xykbbbnqcvviygfqcped.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5a2JiYm5xY3Z2aXlnZnFjcGVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NzY0MjgsImV4cCI6MjA3NDQ1MjQyOH0.CrEUnvWH74NYLcETjIiLyUJtuO999a-MonSetKDKHP0';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
