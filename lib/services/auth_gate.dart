/*
  This Service will listen for Auth State changes and redirect the user to the appropriate page based on their authentication status.
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {

  const AuthGate ({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        //Check if the session is null, if it is then the user is not logged in and we will redirect them to the login page.
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null) {
          return HomePage(); // Replace with your home page widget
        } else {
          return const LoginPage(); // Replace with your login page widget
        }
      }     
    );
  }
  
}