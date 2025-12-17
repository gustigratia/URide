import 'package:flutter/material.dart';
import 'package:uride/features/home/home.dart';
import 'package:uride/features/auth/sign_in.dart';
import 'package:uride/features/auth/sign_up.dart';
import 'package:uride/features/home/search.dart';
import 'package:uride/features/home/lalulintas.dart';
import 'package:uride/features/home/lokasi_parkir.dart';
import 'package:uride/features/workshops/workshop_detail.dart';
import 'package:uride/features/order/order_service.dart';
import 'package:uride/features/order/order_confirmation.dart';
import 'package:uride/features/workshops/workshop.dart';
import 'package:uride/features/auth/ubah_kata_sandi.dart';
import 'package:uride/features/auth/verifikasi_kode.dart';
import 'package:uride/features/auth/buat_password_baru.dart';
import 'package:uride/features/vehicles/vehicle_detail_page.dart';
import 'package:uride/features/vehicles/addvehicle_screen.dart';
import 'package:uride/features/home/search_result.dart';
import 'package:uride/features/vehicles/edit_kendaraan_page.dart';
import 'package:uride/features/spbu/spbu.dart';
import 'package:uride/features/home/weather_screen.dart';
import 'package:uride/features/order/orderhistory_screen.dart';
import 'package:uride/features/home/chatbot.dart';
import 'package:uride/features/order/invoice.dart';
import 'package:uride/features/auth/splash_screen.dart';
import 'package:uride/features/profile/profile_page.dart';
import 'package:uride/features/workshops/dashboard_workshop.dart';
import 'package:uride/features/profile/join_workshop.dart';

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
  static const chatbot = '/chatbot';
  static const invoice = '/invoice';
  static const splash = '/splash';
  static const weather = '/weather';
  static const profilePage = '/profile';
  static const dashboardWorkshop = '/dashboard-workshop';
  static const joinWorkshop = '/join-workshop';




  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    signin: (_) => const SignInPage(),
    search: (_) => const SearchPage(),
    parking: (_) => const LokasiParkirPage(),
    listbengkel: (_) => const BengkelListScreen(),
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
    spbuList: (_) => const SPBUListScreen(),
    orderHistory: (_) => const OrderHistoryScreen(),
    chatbot: (_) => const ChatbotPage(),
    weather: (_) => const WeatherScreen(),
    splash: (_) => const SplashScreen(),
    profilePage: (_) => const ProfilePage(),
    dashboardWorkshop: (_) => const DashboardWorkshop(),
    joinWorkshop: (_) => const GabungMitraPage(),
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
            workshopId: args?['workshopId'] ?? '',
            workshopName: args?['workshopName'] ?? '',
            workshopAddress: args?['workshopAddress'] ?? '',
            userAddress: args?['userAddress'] ?? '',
            vehicleType: args?['vehicleType'] ?? '',
            requestType: args?['requestType'] ?? '',
            isOnLocation: args?['isOnLocation'] ?? false,
            price: args?['price'] ?? 0, // pastikan price dikirim
          ),
        );

      case invoice:
        final args = settings.arguments as Map<String, dynamic>?;
        return _animatedRoute(
          InvoiceScreen(
            orderId: args?['orderId'] ?? 0,
            workshopName: args?['workshopName'] ?? '',
            workshopAddress: args?['workshopAddress'] ?? '',
            userAddress: args?['userAddress'] ?? '',
            vehicleType: args?['vehicleType'] ?? '',
            requestType: args?['requestType'] ?? '',
            isOnLocation: args?['isOnLocation'] ?? false,
            price: args?['price'] ?? 0,
          ),
        );

      case search:
        return _animatedRoute(const SearchPage());
      case parking:
        return _animatedRoute(const LokasiParkirPage());
      case ubahKataSandi:
        return _animatedRoute(const UbahKataSandiPage());
      case verifikasiKode:
        return _animatedRoute(const VerifikasiKodePage());
      case buatPasswordBaru:
        return _animatedRoute(const BuatPasswordBaruPage());
      case laluLintas:
        return _animatedRoute(const LaluLintasPage());
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
      case weather:
        return _animatedRoute(const WeatherScreen());
      case profilePage:
        return _animatedRoute(const ProfilePage());
      case dashboardWorkshop:
        return _animatedRoute(const DashboardWorkshop());
      case joinWorkshop:
        return _animatedRoute(const GabungMitraPage());
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