import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

// Sign up a new user with email and password
  Future<AuthResponse> signUp (String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

// Sign in an existing user with email and password
  Future<AuthResponse> signIn (String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  //Get curent users email
  Future<String?> getCurrentUserEmail() async {
    final user = _client.auth.currentUser;
    return user?.email;
  }
}

