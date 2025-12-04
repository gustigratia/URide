import 'package:flutter/material.dart';
import 'package:uride/screen/home.dart';
import 'package:uride/screen/sign_in.dart';
import 'package:uride/screen/search.dart';
import 'package:uride/screen/lokasi_parkir.dart';
import 'package:uride/screen/workshop_detail.dart';
import 'package:uride/screen/order_service.dart';
import 'package:uride/screen/order_confirmation.dart';
import 'package:uride/screen/workshop.dart';

class AppRoutes {
  static const home = '/home';
  static const signin = '/signin';
  static const search = '/search';
  static const parking = '/parking';
  static const workshopDetail = '/workshop_detail';
  static const ajukanLayanan = '/order_service';
  static const konfirmasiAjuan = '/order_confirmation';
  static const listbengkel = '/workshop';
  static const String verifikasiKode = '/verifikasi-kode';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    signin: (_) => const SignInPage(),
    search: (_) => const SearchPage(),
    parking: (_) => const LokasiParkir(),
    listbengkel: (_) => const BengkelListScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case workshopDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _animatedRoute(
          BengkelDetailScreen(workshopId: args['workshopId']),
        );

      case ajukanLayanan:
        final args = settings.arguments as Map<String, dynamic>;
        return _animatedRoute(
          AjukanLayananScreen(
            workshopId: args['workshopId'],
            workshopName: args['workshopName'],
            workshopAddress: args['workshopAddress'],
            price: args['price'],
          ),
        );

      case konfirmasiAjuan:
        final args = settings.arguments as Map<String, dynamic>?;
        return _animatedRoute(
          KonfirmasiAjuanScreen(
            workshopName: args?['workshopName'] ?? '',
            workshopAddress: args?['workshopAddress'] ?? '',
            userAddress: args?['userAddress'] ?? '',
            vehicleType: args?['vehicleType'] ?? '',
            requestType: args?['requestType'] ?? '',
            isOnLocation: args?['isOnLocation'] ?? false,
            price: args?['price'] ?? 0, // pastikan price dikirim
          ),
        );

      default:
        return null;
    }
  }

  static PageRouteBuilder _animatedRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = Tween(begin: 0.0, end: 1.0).animate(animation);
        final slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(animation);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
