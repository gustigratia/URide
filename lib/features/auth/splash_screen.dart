import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uride/routes/app_routes.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); 

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentPageIndex = 0;
  static const Color kPrimaryOrange = Color(0xFFFF9800); 
  static const Color kPrimaryShadow = Color(0x33000000);
  static const Color kPrimaryButtonBalancedOrange = Color(0xFFFFB000); 

  @override
  void initState() {
    super.initState();
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

  void _navigateToSignIn() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signin); 
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup); 
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (widget, animation) {
        return FadeTransition(
          opacity: animation,
          child: widget,
        );
      },
      child: _currentPageIndex == 0
          ? _buildSplashPage1(context)
          : _buildSplashPage2(context),
    );
  }

  Widget _buildLogoImage({required String logoAsset, required double screenWidth}) {
    return Image.asset(
      logoAsset,
      width: screenWidth * 0.45, 
      fit: BoxFit.contain,
    );
  }

  Widget _buildLogoContent({required String sloganColor, required String logoAsset, required double screenWidth, required double screenHeight, required double topSpacingFactor}) {
    return Center( 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * topSpacingFactor), 

          _buildLogoImage(
            logoAsset: logoAsset, 
            screenWidth: screenWidth,
          ),

          Transform.translate(
            offset: const Offset(0, -8.0),
            child: Text(
              'Partner berkendara Anda!',
              style: TextStyle(
                fontSize: 13, 
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


  Widget _buildSplashPage1(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return KeyedSubtree(
      key: const ValueKey('SplashPage1'),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildLogoContent(
              sloganColor: '0xFF616161',
              logoAsset: 'assets/images/uride.png',
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              topSpacingFactor: 0.28,
            ),

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
      ),
    );
  }

  Widget _buildSplashPage2(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 80.0;

    return KeyedSubtree(
      key: const ValueKey('SplashPage2'),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOut,
              top: _currentPageIndex == 0
                  ? screenHeight
                  : screenHeight * -0.05,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave 2.png',
                width: double.infinity,
                height: screenHeight * 0.45,
                fit: BoxFit.fill,
              ),
            ),

            SizedBox(
              height: screenHeight,
              child: Column(
                children: [
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

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.25,
                      left: horizontalPadding,
                      right: horizontalPadding
                    ),
                    child: Column(
                      children: [
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

                        GestureDetector(
                          onTap: _navigateToSignUp,
                          child: Text.rich(
                            TextSpan(
                              text: 'Belum mempunyai akun? ',
                              style: TextStyle(
                                fontSize: 13, 
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
      ),
    );
  }
}