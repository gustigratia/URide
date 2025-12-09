import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uride/services/gemini_service.dart';
import 'env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await GeminiService.initialize();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
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

      // route awal
      initialRoute: AppRoutes.signin,

      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
