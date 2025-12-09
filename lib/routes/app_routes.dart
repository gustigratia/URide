// lib/app_routes.dart

import 'package:flutter/material.dart';

import 'package:uride/screen/home.dart';
import 'package:uride/screen/sign_in.dart';
import 'package:uride/screen/sign_up.dart';
import 'package:uride/screen/search.dart';
import 'package:uride/screen/lalulintas.dart';
import 'package:uride/screen/lokasi_parkir.dart';
import 'package:uride/screen/ubah_kata_sandi.dart';
import 'package:uride/screen/verifikasi_kode.dart';
import 'package:uride/screen/buat_password_baru.dart';
import 'package:uride/screen/vehicle_detail_page.dart';
import 'package:uride/screen/addvehicle_screen.dart';
import 'package:uride/screen/search_result.dart';
import 'package:uride/screen/edit_kendaraan_page.dart';
import 'package:uride/screen/spbu.dart'; 

import 'package:uride/screen/orderhistory_screen.dart';
<<<<<<< HEAD
import 'package:uride/screen/payment_page.dart';
import 'package:uride/screen/splash_screen.dart'; // <-- Import SplashScreen
=======
import 'package:uride/screen/chatbot.dart';
>>>>>>> 2d529be3e59b2d8c7d0c2387d5e2bd22413976cf

class AppRoutes {
  static const splash = '/'; // <-- SET SEBAGAI ROOT PATH
  static const home = '/home';
  static const signin = '/signin';
  static const signup = '/signup';
  static const search = '/search';
  static const parking = '/parking';
  static const vehicle = '/vehicle';
  static const addvehicle = '/add-vehicle';
  static const search_result = '/search-result';
  static const ubahKataSandi = '/ubah-kata-sandi';
  static const verifikasiKode = '/verifikasi-kode';
  static const buatPasswordBaru = '/buat-password-baru'; 
  static const laluLintas = '/lalulintas';
  static const spbuList = '/spbu-list'; 
  static const editKendaraan = '/edit-kendaraan';
  static const orderHistory = '/history';
<<<<<<< HEAD
  static const paymentPage = '/payment';
=======
  static const chatbot = '/chatbot';


>>>>>>> 2d529be3e59b2d8c7d0c2387d5e2bd22413976cf


  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(), // <-- ENTRY POINT DARI '/'
    home: (_) => const HomeScreen(),
    signin: (_) => const SignInPage(),
    signup: (_) => const SignUpPage(),
    vehicle: (_) => const VehicleDetailPage(),
    addvehicle: (_) => const TambahKendaraanPage(),
    search: (_) => const SearchPage(),
    ubahKataSandi: (_) => const UbahKataSandiPage(),
    verifikasiKode: (_) => const VerifikasiKodePage(),
    buatPasswordBaru: (_) => const BuatPasswordBaruPage(),
    laluLintas: (_)=> const LaluLintasPage(), 
    parking: (_) => const LokasiParkirPage(),
    editKendaraan: (_) => const EditKendaraanPage(),
<<<<<<< HEAD
    orderHistory: (_) => const OrderHistoryScreen(newOrderId: null), 
=======
    spbuList: (_) => const SPBUListScreen(),
    orderHistory: (_) => const OrderHistoryScreen(),
    chatbot: (_) => const ChatbotPage(),
>>>>>>> 2d529be3e59b2d8c7d0c2387d5e2bd22413976cf
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.search:
        return _animatedRoute(const SearchPage());
<<<<<<< HEAD
      case AppRoutes.parking:
        return _animatedRoute(const LokasiParkir());
      case AppRoutes.ubahKataSandi:
=======
      case parking:
        return _animatedRoute(const LokasiParkirPage());
      case ubahKataSandi:
>>>>>>> 2d529be3e59b2d8c7d0c2387d5e2bd22413976cf
        return _animatedRoute(const UbahKataSandiPage());
      case AppRoutes.verifikasiKode:
        return _animatedRoute(const VerifikasiKodePage());
      case AppRoutes.buatPasswordBaru:
        return _animatedRoute(const BuatPasswordBaruPage());
      case AppRoutes.laluLintas:
        return _animatedRoute(const LaluLintasPage());
<<<<<<< HEAD
      case AppRoutes.vehicle:
        return _animatedRoute(const VehicleDetailPage());
      case AppRoutes.editKendaraan:
        return _animatedRoute(const EditKendaraanPage());
        
      case AppRoutes.orderHistory:
        final historyArgs = settings.arguments as int?;
        return _animatedRoute(OrderHistoryScreen(newOrderId: historyArgs));

      case AppRoutes.paymentPage:
        final args = settings.arguments as Map<String, dynamic>?; 
        if (args != null) {
          return _animatedRoute(PaymentPage(orderInput: args));
        }
        return _animatedRoute(const HomeScreen()); 

      case AppRoutes.search_result:
=======
      case chatbot:
        return _animatedRoute(const ChatbotPage());
      case vehicle:
        return _animatedRoute(const VehicleDetailPage());
      case editKendaraan:
        return _animatedRoute(const EditKendaraanPage()); 
      case spbuList: 
        return _animatedRoute(const SPBUListScreen());
      case orderHistory:
        return _animatedRoute(const OrderHistoryScreen());
      case addvehicle:
        return _animatedRoute(const TambahKendaraanPage());
      case search_result:
>>>>>>> 2d529be3e59b2d8c7d0c2387d5e2bd22413976cf
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
      transitionDuration: const Duration(milliseconds: 320),
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
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }
}