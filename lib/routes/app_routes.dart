import 'package:flutter/material.dart';
import 'package:uride/screen/home.dart';
import 'package:uride/screen/sign_in.dart';
import 'package:uride/screen/sign_up.dart';
import 'package:uride/screen/search.dart';
import 'package:uride/screen/lalulintas.dart';
import 'package:uride/screen/lokasi_parkir.dart';
import 'package:uride/screen/workshop_detail.dart';
import 'package:uride/screen/order_service.dart';
import 'package:uride/screen/order_confirmation.dart';
import 'package:uride/screen/workshop.dart';
import 'package:uride/screen/ubah_kata_sandi.dart';
import 'package:uride/screen/verifikasi_kode.dart';
import 'package:uride/screen/buat_password_baru.dart';
import 'package:uride/screen/vehicle_detail_page.dart';
import 'package:uride/screen/search_result.dart';
import 'package:uride/screen/edit_kendaraan_page.dart';

class AppRoutes {
  static const home = '/home';
  static const signin = '/signin';
  static const signup = '/signup';
  static const search = '/search';
  static const parking = '/parking';
  static const workshopDetail = '/workshop_detail';
  static const ajukanLayanan = '/order_service';
  static const konfirmasiAjuan = '/order_confirmation';
  static const listbengkel = '/workshop';
  static const String verifikasiKode = '/verifikasi-kode';
  static const vehicle = '/vehicle';
  static const search_result = '/search-result';
  static const ubahKataSandi = '/ubah-kata-sandi';
  static const buatPasswordBaru = '/buat-password-baru'; 
  static const laluLintas = '/lalulintas';
  static const editKendaraan = '/edit-kendaraan'; 


  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    signin: (_) => const SignInPage(),
    search: (_) => const SearchPage(),
    parking: (_) => const LokasiParkir(),
    listbengkel: (_) => const BengkelListScreen(),
    signup: (_) => const SignUpPage(),
    vehicle: (_) => const VehicleDetailPage(),
    ubahKataSandi: (_) => const UbahKataSandiPage(),
    verifikasiKode: (_) => const VerifikasiKodePage(),
    buatPasswordBaru: (_) => const BuatPasswordBaruPage(),
    laluLintas: (_)=> const LaluLintasPage(), 
    editKendaraan: (_) => const EditKendaraanPage(),
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

      case search:
        return _animatedRoute(const SearchPage());
      case parking:
        return _animatedRoute(const LokasiParkir());
      case ubahKataSandi:
        return _animatedRoute(const UbahKataSandiPage());
      case verifikasiKode:
        return _animatedRoute(const VerifikasiKodePage());
      case buatPasswordBaru:
        return _animatedRoute(const BuatPasswordBaruPage());
      case laluLintas:
        return _animatedRoute(const LaluLintasPage());
      case vehicle:
        return _animatedRoute(const VehicleDetailPage());
      case editKendaraan:
        return _animatedRoute(const EditKendaraanPage()); 
      case search_result:
        return PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) =>
              SearchResultPage(arguments: settings.arguments as Map<String, dynamic>?),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
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
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        final slide = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
