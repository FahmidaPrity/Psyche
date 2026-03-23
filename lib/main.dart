import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zaiqirqjdwdaxboqciab.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphaXFpcnFqZHdkYXhib3FjaWFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTM4NTQsImV4cCI6MjA3MzY2OTg1NH0.jnGou3b8iMunflGkIyjiSFGUR7PNHH8EW-74Xpm8MQc',
  );
  runApp(const PsycheApp());
}

class PsycheApp extends StatelessWidget {
  const PsycheApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psyche',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Roboto'),
      home: const SplashScreen(),
    );
  }
}
