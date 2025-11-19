import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          print("Tapped: $index");
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),
              _buildHeader(),

              const SizedBox(height: 20),
              _buildSearchBar(),

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
      ),
    );
  }

  // ===============================
  // HEADER
  // ===============================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFF8400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "URide",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              Row(
                children: const [
                  Icon(Icons.notifications_none, color: Colors.white),
                  SizedBox(width: 15),
                  Icon(Icons.settings, color: Colors.white),
                ],
              )
            ],
          ),

          const SizedBox(height: 10),
          const Text(
            "Selamat Pagi Razan!",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // SEARCH BAR
  // ===============================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Search...",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Icon(Icons.filter_list, color: Colors.grey),
        ],
      ),
    );
  }

  // ===============================
  // TRAFFIC CARD
  // ===============================
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Kondisi lalu lintas",
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  "Macet",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "12.9 Kilometer\nPerjalanan anda hari ini",
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  "Lihat selengkapnya",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          )
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
        _weatherCard(79, "Berpotensi hujan", Icons.cloudy_snowing, true),
        _weatherCard(null, "Log Perjalanan", Icons.route, false),
        _weatherCard(null, "Lokasi Parkir", Icons.location_on, false),
      ],
    );
  }

  Widget _weatherCard(int? percent, String title, IconData icon, bool isActive) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFFFFC93C) : const Color(0xFFE0E0E0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 28),
          const SizedBox(height: 10),
          if (percent != null)
            Text(
              "$percent%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        Text(
          "Lihat Semua",
          style: TextStyle(color: Colors.orange),
        ),
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
              )
            ],
          ),
        )
      ],
    );
  }

}
