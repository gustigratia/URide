import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/home.dart';
import 'screen/sign_in.dart';
// import 'screen/lokasi_parkir.dart';

// Global Supabase instance
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mxwxxtaaxksddeijpgbb.supabase.co',
    anonKey: 'sb_publishable_xDF-CQX3wPWcVbm2tpzXdA_0JHyBW4j',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'URide',
      theme: ThemeData(
        fontFamily: "Euclid",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      // home: const SignInPage(),
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/signin': (context) => const SignInPage(),
      },
    );
  }
}
