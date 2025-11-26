import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          print("Tapped: $index");
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 10),
            _buildHeader(context),
            // const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTrafficCard(),

                  const SizedBox(height: 20),
                  _buildWeatherRow(),

                  const SizedBox(height: 20),
                  _buildNearestWorkshopTitle(),

                  const SizedBox(height: 12),
                  _buildWorkshopCard(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFF8400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 100,
                height: 40,
                child: Image.asset(
                  "assets/icons/header-icon.png",
                  fit: BoxFit.contain,
                ),
              ),

              Row(
                children: const [
                  Icon(Icons.notifications_none, color: Colors.white),
                  SizedBox(width: 15),
                  Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ],
          ),
          const Text(
            "Selamat Pagi Gusti!",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: Text("Search...", style: TextStyle(color: Colors.grey)),
          ),
          // Icon(Icons.filter_list, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTrafficCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Fake map image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage("assets/images/map.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Traffic info
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final String status = "Padat"; // <-- nanti bisa dynamic
                final Color lineColor = _getTrafficColor(status);
                final double lineWidth = _getTrafficLineWidth(
                  status,
                  constraints.maxWidth,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kondisi lalu lintas",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      status,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff3d3d3d),
                        fontSize: 20,
                      ),
                    ),

                    // Garis dinamis
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 3,
                      width: lineWidth,
                      color: lineColor,
                    ),

                    const Text(
                      "12.9 Kilometer",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xff3d3d3d),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),
                    const Text(
                      "Perjalanan anda hari ini",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Text(
                        "Lihat selengkapnya",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // WEATHER + BUTTON ROW
  // ===============================
  Widget _buildWeatherRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _weatherCard(
          percent: 79,
          title: "Berpotensi\nhujan",
          subtitle: "Berawan",
          // icon: Icons.cloud,
          icon: Image.asset('assets/icons/weather.png'),
          isActive: true,
        ),
        _menuCards(),
      ],
    );
  }

  Widget _weatherCard({
    required int percent,
    required String title,
    required String subtitle,
    required Widget icon,
    required bool isActive,
  }) {
    return Container(
      width: 200,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kiri: persentase dan judul
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$percent%",
                      style: const TextStyle(
                        fontSize: 35,
                        color: Color(0xff292D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC93C), Color(0xFFFFD65C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SizedBox(width: 36, height: 36, child: icon),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 90,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff3d3d3d),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuCards() {
    return Container(
      width: 200,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _menuCard("Log Perjalanan", "assets/icons/log.png"),
          _menuCard("Lokasi Parkir", "assets/icons/parkir.png"),
        ],
      ),
    );
  }

  Widget _menuCard(String title, String iconPath) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(iconPath, width: 26, height: 26),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          softWrap: false,   // ⬅️ tidak boleh turun baris
          overflow: TextOverflow.fade,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }



  // ===============================
  // WORKSHOP TITLE
  // ===============================
  Widget _buildNearestWorkshopTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Bengkel terdekat",
          style: TextStyle(
            fontSize: 17,
            color: Color(0xff3d3d3d),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text("Lihat Semua", style: TextStyle(color: Colors.orange)),
      ],
    );
  }

  // ===============================
  // WORKSHOP CARD
  // ===============================
  Widget _buildWorkshopCard() {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage("assets/images/workshop.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Bengkel Sinar Makmur",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff3d3d3d),
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 3),
                      Text("1 Km"),
                      SizedBox(width: 10),
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 3),
                      Text("4.7"),
                    ],
                  ),
                ],
              ),

              // Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Buka",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _getTrafficColor(String status) {
  switch (status.toLowerCase()) {
    case "macet":
      return Colors.red;
    case "padat":
      return Colors.orange;
    case "normal":
      return Colors.yellow.shade700;
    case "lancar":
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

double _getTrafficLineWidth(String status, double maxWidth) {
  switch (status.toLowerCase()) {
    case "macet":
      return maxWidth;
    case "padat":
      return maxWidth * 0.75;
    case "normal":
      return maxWidth * 0.50;
    case "lancar":
      return maxWidth * 0.30;
    default:
      return maxWidth * 0.40;
  }
}
