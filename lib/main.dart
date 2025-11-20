import 'package:flutter/material.dart';
// import 'package:uride/screen/lokasi_parkir.dart';
import 'package:uride/screen/sign_in.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lokasi Parkir',
      theme: ThemeData(
        fontFamily: "Euclid", 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const SignInPage(),
      // home: const LokasiParkir(),

    );
  }
}
