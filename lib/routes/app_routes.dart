import 'package:flutter/material.dart';

import 'package:uride/screen/home.dart';
import 'package:uride/screen/sign_in.dart';
import 'package:uride/screen/search.dart';
import 'package:uride/screen/lokasi_parkir.dart';

class AppRoutes {
  static const home = '/home';
  static const signin = '/signin';
  static const search = '/search';
  static const parking = '/parking';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    signin: (_) => const SignInPage(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case search:
        return _animatedRoute(const SearchPage());
      case parking:
        return _animatedRoute(const LokasiParkir());
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
          begin: const Offset(0, 0.05), // sedikit naik
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

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
