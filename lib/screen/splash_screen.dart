// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async'; 
// Import yang sudah diperbaiki
import 'package:uride/routes/app_routes.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); 

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Logic transisi state/page
  int _currentPageIndex = 0; 

  // Definisikan warna-warna yang digunakan
  static const Color kPrimaryOrange = Color(0xFFFF9800); 
  static const Color kPrimaryShadow = Color(0x33000000); 
  // Warna tombol yang seimbang (tidak terlalu oranye/kuning)
  static const Color kPrimaryButtonBalancedOrange = Color(0xFFFFB000); 

  @override
  void initState() {
    super.initState();
    // Jeda 5 detik untuk transisi ke Screen 2
    Timer(const Duration(seconds: 5), () { 
      if (mounted) {
        setState(() {
          _currentPageIndex = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fungsi Navigasi
  void _navigateToSignIn() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signin); 
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup); 
  }

  
  @override
  Widget build(BuildContext context) {
    if (_currentPageIndex == 0) {
      return _buildSplashPage1(context);
    } else {
      return _buildSplashPage2(context);
    }
  }

  // --- WIDGET LOGO (Asset Gambar Gabungan) ---
  // Menampilkan satu Image.asset yang berisi teks 'URide' dan logo
  Widget _buildLogoImage({required String logoAsset, required double screenWidth}) {
    return Image.asset(
      logoAsset,
      width: screenWidth * 0.45, 
      fit: BoxFit.contain,
    );
  }

  // --- WIDGET CONTENT LOGO DAN SLOGAN ---
  // Menggabungkan logo dan slogan. Ini adalah tempat perbaikan jarak
  Widget _buildLogoContent({required String sloganColor, required String logoAsset, required double screenWidth, required double screenHeight, required double topSpacingFactor}) {
    return Center( 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * topSpacingFactor), 
          
          // Logo/Teks URide (dari asset)
          _buildLogoImage(
            logoAsset: logoAsset, 
            screenWidth: screenWidth,
          ),
          
          // SOLUSI MERAPATKAN JARAK: Menaikkan teks slogan 8.0 unit ke atas
          Transform.translate(
            offset: const Offset(0, -8.0), // <-- DIGESER KE ATAS
            child: Text(
              'Partner berkendara Anda!',
              style: TextStyle(
                fontSize: screenWidth * 0.025, 
                fontWeight: FontWeight.w400, 
                fontFamily: 'Euclid', 
                color: Color(int.parse(sloganColor)), 
                letterSpacing: 0.0, 
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // --- TAMPILAN 1: SPLASH SCREEN (WAVE DI BAWAH) ---
  // =========================================================
  Widget _buildSplashPage1(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          // 1. Logo Content (Menggunakan uride.png)
          _buildLogoContent(
            sloganColor: '0xFF616161', 
            // Asset untuk Screen 1
            logoAsset: 'assets/images/uride.png', 
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            topSpacingFactor: 0.28, 
          ),

          // 2. Gambar Wave di Bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/wave.png', 
              width: double.infinity, 
              height: screenHeight * 0.45, 
              fit: BoxFit.fill, 
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // --- TAMPILAN 2: WELCOME SCREEN (WAVE DI ATAS + TOMBOL) ---
  // =========================================================
  Widget _buildSplashPage2(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 80.0;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          // 1. Gambar Wave Kuning di ATAS
          Positioned(
            top: screenHeight * -0.05, 
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave 2.png', 
              width: double.infinity, 
              height: screenHeight * 0.45, 
              fit: BoxFit.fill,
            ),
          ),

          // 2. Konten Utama
          SizedBox(
            height: screenHeight, 
            child: Column(
              children: [
                // Logo dan Teks
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.12),
                  child: _buildLogoContent(
                    sloganColor: '0xFFFFFFFF', 
                    // Asset untuk Screen 2
                    logoAsset: 'assets/images/uride white.png', 
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    topSpacingFactor: 0.0, 
                  ),
                ),

                const Spacer(), 

                // 4. Area Tombol MASUK dan Daftar
                Padding(
                  padding: EdgeInsets.only(
                    bottom: screenHeight * 0.25,
                    left: horizontalPadding,
                    right: horizontalPadding
                  ),
                  child: Column(
                    children: [
                      // Tombol "Masuk"
                      Container(
                        width: double.infinity, 
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _navigateToSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryButtonBalancedOrange, 
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Euclid', 
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Teks "Belum mempunyai akun? Daftar"
                      GestureDetector( 
                        onTap: _navigateToSignUp,
                        child: Text.rich(
                          TextSpan(
                            text: 'Belum mempunyai akun? ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Euclid', 
                              color: Colors.grey[600],
                            ),
                            children: const [
                              TextSpan(
                                text: 'Daftar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Euclid', 
                                  color: kPrimaryButtonBalancedOrange, 
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}