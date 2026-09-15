import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  //User Name / Comapny Name Controller
  final _nameController = TextEditingController();

  //Siugn Up Function
  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      await _authService.signUp(email, password, name);
      if(mounted){
        Navigator.pop(context); // Navigate back to the previous screen after successful sign-up
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name / Company Name'),
        ),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),  

        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: signUp,
          child: const Text('Sign Up'),
        ),  
      ]
    )
    );
  }
}