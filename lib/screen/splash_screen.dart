// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 0 = Wave Bawah (Page 1), 1 = Wave Atas + Tombol (Page 2)
  int _currentPageIndex = 0; 

  @override
  void initState() {
    super.initState();
    // Transisi setelah 5 detik
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

  @override
  Widget build(BuildContext context) {
    if (_currentPageIndex == 0) {
      return _buildSplashPage1(context);
    } else {
      return _buildSplashPage2(context);
    }
  }

  // --- WIDGET LOGO (Detail Presisi) ---
  Widget _buildLogoText({required Color textColor, required String logoAsset, required double screenWidth}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, 
      crossAxisAlignment: CrossAxisAlignment.end, // Menyelaraskan teks dan logo di bagian bawah
      children: [
        Text( 
          'URide',
          style: TextStyle(
            fontSize: screenWidth * 0.08, 
            fontWeight: FontWeight.bold,
            fontFamily: 'DMSans', 
            color: textColor, 
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        
        // REVISI LOGO GESER KIRI (tetap): Mengurangi lebar SizedBox untuk mendekatkan logo ke teks
        SizedBox(width: screenWidth * 0.005), // Dipertahankan dari revisi sebelumnya
        Image.asset(
          logoAsset, 
          height: screenWidth * 0.065, // Ukuran logo sedikit lebih kecil agar pas dengan teks
          width: screenWidth * 0.065,
          alignment: Alignment.bottomCenter, // Agar logo menyelaraskan bagian bawahnya dengan teks
        ),
      ],
    );
  }

  // --- WIDGET CONTENT LOGO DAN SLOGAN ---
  Widget _buildLogoContent({required Color textColor, required String sloganColor, required String logoAsset, required double screenWidth, required double screenHeight, required double topSpacingFactor}) {
    return Center( 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * topSpacingFactor), 
          _buildLogoText(
            textColor: textColor, 
            logoAsset: logoAsset, 
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenHeight * 0.005), 
          Text(
            'Partner berkendara Anda!',
            style: TextStyle(
              fontSize: screenWidth * 0.025, 
              fontWeight: FontWeight.w400, 
              fontFamily: 'DMSans', 
              color: Color(int.parse(sloganColor)), 
              letterSpacing: 0.0, 
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
          // 1. Logo (Diatur posisinya)
          _buildLogoContent(
            textColor: const Color(0xFFFF9800), 
            sloganColor: '0xFF616161', 
            logoAsset: 'assets/images/logo uride yellow.png', 
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

          // 2. Konten Utama (diatur dengan Column agar Spacer bekerja)
          SizedBox(
            height: screenHeight, 
            child: Column(
              children: [
                // Logo dan Teks (di dalam wave kuning)
                Padding(
                  // REVISI 1: LOGO TURUNNN: Menaikkan nilai padding agar logo turun lebih banyak
                  padding: EdgeInsets.only(top: screenHeight * 0.12), // Diubah ke 0.12
                  child: _buildLogoContent(
                    textColor: Colors.white, 
                    sloganColor: '0xFFFFFFFF', 
                    logoAsset: 'assets/images/logo uride white.png', 
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    topSpacingFactor: 0.0, 
                  ),
                ),

                const Spacer(), 

                // 4. Area Tombol MASUK dan Daftar
                Padding(
                  padding: EdgeInsets.only(
                    bottom: screenHeight * 0.25, // REVISI 2: BUTTON NAIKIN WOOY: Diubah ke 0.25
                    left: horizontalPadding,
                    right: horizontalPadding
                  ),
                  child: Column(
                    children: [
                      // Tombol "MASUK"
                      Container(
                        width: double.infinity, 
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigasi
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00), 
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
                              fontFamily: 'DMSans', 
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Teks "Belum mempunyai akun? Daftar"
                      Text.rich(
                        TextSpan(
                          text: 'Belum mempunyai akun? ',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'DMSans', 
                            color: Colors.grey[600],
                          ),
                          children: const [
                            TextSpan(
                              text: 'Daftar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DMSans', 
                                color: Color(0xFFFFCC00),
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
          ),
        ],
      ),
    );
  }
}