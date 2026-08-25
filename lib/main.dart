import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main () async {
//Supabase Initialisation
WidgetsFlutterBinding.ensureInitialized(); //
  await Supabase.initialize(
  url: 'https://lfwhpfexxqnqnfurmkvq.supabase.co',
  publishableKey: 'sb_publishable_inMUG1x78xKUCEoT9GR_XQ__U6wN44B'
);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Hello, World!'),
        ),
      )
    );
  }
}