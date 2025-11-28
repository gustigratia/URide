import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';
import 'package:uride/screen/search.dart';
import 'package:uride/routes/app_routes.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const workshops = [
    {
      "name": "Bengkel Sinar Makmur",
      "distance": "1 Km",
      "rating": "4.7",
      "image": "assets/images/workshop.png",
      "status": "Buka",
    },
    {
      "name": "Bengkel Jaya Motor",
      "distance": "2.3 Km",
      "rating": "4.5",
      "image": "assets/images/workshop.png",
      "status": "Tutup",
    },
    {
      "name": "Bengkel FastFix",
      "distance": "3 Km",
      "rating": "4.8",
      "image": "assets/images/workshop.png",
      "status": "Buka",
    },
  ];

  static const spbu = [
    {
      "name": "SPBU Pertamina 54.612.19",
      "distance": "0.8 Km",
      "rating": "4.6",
      "image": "assets/images/spbu.png",
      "status": "Buka",
    },
    {
      "name": "SPBU Pertamina 54.601.83",
      "distance": "1.4 Km",
      "rating": "4.4",
      "image": "assets/images/spbu.png",
      "status": "Buka",
    },
    {
      "name": "SPBU Shell Raya",
      "distance": "2.1 Km",
      "rating": "4.7",
      "image": "assets/images/spbu.png",
      "status": "Tutup",
    },
  ];


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
                  _buildWeatherRow(context),

                  const SizedBox(height: 20),
                  _buildNearestWorkshopTitle(),

                  const SizedBox(height: 12),
                  buildWorkshopCarousel(),

                  const SizedBox(height: 20),
                  _buildNearestSpbuTitle(),

                  const SizedBox(height: 12),
                  buildSpbuCarousel(),

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
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/search');
      },
      child: Container(
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
          ],
        ),
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/lalulintas');
                        },
                        child: const Text(
                          "Lihat selengkapnya",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )

                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(BuildContext context) {
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
        _menuCards(context),
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

  Widget _menuCards(BuildContext context) {
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
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/parking');
            },
            child: _menuCard("Lokasi Parkir", "assets/icons/parkir.png"),
          ),
        ],
      ),
    );
  }



  Widget _menuCard(String title, String iconPath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
            softWrap: false,
            overflow: TextOverflow.fade,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }



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

  Widget _buildNearestSpbuTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "SPBU terdekat",
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


  Widget _buildWorkshopCard({
    required String name,
    required String distance,
    required String rating,
    required String image,
    required String status,
  }) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gambar
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Card info
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Info kiri
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff3d3d3d),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(distance, style: const TextStyle(fontSize: 13)),
                          SizedBox(width: 12),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: status == "Buka" ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(30),

                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWorkshopCarousel() {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        clipBehavior: Clip.none,
        controller: PageController(
          viewportFraction: 0.85,
        ),
        itemCount: workshops.length,
        itemBuilder: (context, index) {
          final item = workshops[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildWorkshopCard(
              name: item["name"]!,
              distance: item["distance"]!,
              rating: item["rating"]!,
              image: item["image"]!,
              status: item["status"]!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpbuCard({
    required String name,
    required String distance,
    required String rating,
    required String image,
    required String status,
  }) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gambar
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Card info
          Positioned(
            left: 16,
            right: 16,
            bottom: -12,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Info kiri
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff3d3d3d),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(distance, style: const TextStyle(fontSize: 13)),
                          SizedBox(width: 12),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: status == "Buka" ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSpbuCarousel() {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        clipBehavior: Clip.none,
        controller: PageController(
          viewportFraction: 0.85,
        ),
        itemCount: spbu.length,
        itemBuilder: (context, index) {
          final item = spbu[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSpbuCard(
              name: item["name"]!,
              distance: item["distance"]!,
              rating: item["rating"]!,
              image: item["image"]!,
              status: item["status"]!,
            ),
          );
        },
      ),
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
