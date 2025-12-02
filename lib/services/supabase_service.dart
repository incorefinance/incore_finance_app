import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  // Replace these with your actual Supabase project credentials from your dashboard
  // Find these at: https://app.supabase.com/project/_/settings/api
  static const String supabaseUrl = 'https://hjtwysbxuergqyvzadcs.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHd5c2J4dWVyZ3F5dnphZGNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMTk3NDAsImV4cCI6MjA3OTU5NTc0MH0.xztPH_rBI_yuBaJCmcSt-tesT3j7b8fT7vTniukehC8';

  // Get Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Get current user ID (for demo purposes, using a default profile ID)
  // In production, this would come from authentication
  int get currentUserId =>
      1; // Replace with actual auth user ID when auth is implemented
}
