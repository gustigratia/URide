import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before async code

  await Supabase.initialize(
    url: 'https://mxwxxtaaxksddeijpgbb.supabase.co',
    anonKey: 'sb_publishable_xDF-CQX3wPWcVbm2tpzXdA_0JHyBW4j',
  );

  runApp(const MyApp());
}

// Global Supabase instance
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        // '/search': (context) => const SearchScreen(),
        // '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}