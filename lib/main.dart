import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/spbu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://mxwxxtaaxksddeijpgbb.supabase.co',
    anonKey: 'sb_publishable_xDF-CQX3wPWcVbm2tpzXdA_0JHyBW4j',
  );

  runApp(const SPBUApp());
}

class SPBUApp extends StatelessWidget {
  const SPBUApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SPBUListScreen(),
    );
  }
}
