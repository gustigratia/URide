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
import 'package:uride/screen/search_result.dart';
import 'package:uride/screen/edit_kendaraan_page.dart';
import 'package:uride/screen/orderhistory_screen.dart';
import 'package:uride/screen/payment_page.dart';

class AppRoutes {
  static const home = '/home';
  static const signin = '/signin';
  static const signup = '/signup';
  static const search = '/search';
  static const parking = '/parking';
  static const vehicle = '/vehicle';
  static const search_result = '/search-result';
  static const ubahKataSandi = '/ubah-kata-sandi';
  static const verifikasiKode = '/verifikasi-kode';
  static const buatPasswordBaru = '/buat-password-baru'; 
  static const laluLintas = '/lalulintas';
  static const editKendaraan = '/edit-kendaraan';
  static const orderHistory = '/history';
  static const paymentPage = '/payment';


  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    signin: (_) => const SignInPage(),
    signup: (_) => const SignUpPage(),
    vehicle: (_) => const VehicleDetailPage(),
    search: (_) => const SearchPage(),
    ubahKataSandi: (_) => const UbahKataSandiPage(),
    verifikasiKode: (_) => const VerifikasiKodePage(),
    buatPasswordBaru: (_) => const BuatPasswordBaruPage(),
    laluLintas: (_)=> const LaluLintasPage(), 
    editKendaraan: (_) => const EditKendaraanPage(),
    // REVISI: orderHistory di sini menggunakan null karena ia opsional
    orderHistory: (_) => const OrderHistoryScreen(newOrderId: null), 
    // paymentPage DIHAPUS dari static routes
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
        
      case orderHistory:
        // REVISI: Mengambil ID pesanan jika ada
        final historyArgs = settings.arguments as int?;
        // newOrderId di-set ke historyArgs (bisa null)
        return _animatedRoute(OrderHistoryScreen(newOrderId: historyArgs));

      case paymentPage:
        // REVISI: Mengambil data pesanan (Map<String, dynamic>)
        final args = settings.arguments as Map<String, dynamic>?; 
        if (args != null) {
          // Panggil PaymentPage dan masukkan data ke orderInput
          return _animatedRoute(PaymentPage(orderInput: args));
        }
        // Jika argumen tidak ada, kembali ke Home
        return _animatedRoute(const HomeScreen()); 

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