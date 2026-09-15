import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/home_page.dart';
import '../pages/loginPage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check active session directly if the stream snapshot is null
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;

        if (session != null) {
          //Extract Users Name
          final userName = session.user.userMetadata?['name'] as String? ?? 'User';
          return HomePage(userName: userName);
        } else {
          return const LoginPage();
        }
      },
    );
  }
}