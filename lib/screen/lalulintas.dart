import 'package:flutter/material.dart';

class LaluLintasPage extends StatelessWidget {
  const LaluLintasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lalu Lintas",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 18, 
            fontWeight: FontWeight.w500, 
            fontStyle: FontStyle.normal,
            height: 1.0, 
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAP IMAGE CONTAINER
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                "assets/images/map.png",
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Kondisi lalu lintas",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 5),

            const Text(
              "Macet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            const SizedBox(height: 5),

            // RED PROGRESS BAR
            Container(
              height: 6,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 25),

            // TITLE REPORT
            Row(
              children: const [
                Icon(Icons.traffic, color: Colors.orange, size: 26),
                SizedBox(width: 8),
                Text(
                  "Laporan lalu lintas Kota Bondowoso",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // LIST REPORT ITEMS
            buildReportItem(
              color: Colors.red,
              time: "5 menit yang lalu",
              text:
                  "Telah terjadi tabrakan di Jalan Medan Merdeka Barat No. 15.",
            ),
            buildReportItem(
              color: Colors.yellow[800]!,
              time: "30 menit yang lalu",
              text: "Jalan Tol Probowangi dialihkan ke jalur pantura.",
            ),
            buildReportItem(
              color: Colors.yellow[700]!,
              time: "1 jam yang lalu",
              text: "Terdapat pohon tumbang di Jalan Raya Situbondo.",
            ),
            buildReportItem(
              color: Colors.yellow[700]!,
              time: "1 jam yang lalu",
              text: "Terdapat pohon tumbang di Jalan Bondowoso.",
            ),
            buildReportItem(
              color: const Color.fromARGB(255, 25, 207, 1),
              time: "2 jam yang lalu",
              text: "Kemacetan di Pintu Exit Tol Mojokerto telah terurai.",
            ),
            buildReportItem(
              color: Colors.red,
              time: "1 jam yang lalu",
              text: "Terjadi kecelakaan di dekat Jalan Situbondo–Bondowoso.",
              isLast: true, // ⬅ garis di bawah titik terakhir hilang
            ),
          ],
        ),
      ),
    );
  }

  // REUSABLE WIDGET FOR REPORT ITEMS
  Widget buildReportItem({
    required Color color,
    required String time,
    required String text,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 30,
      ), // geser sedikit ke kanan
      child: Stack(
        children: [
          // === GARIS VERTIKAL ===
          if (!isLast)
            Positioned(
              left: 7, // posisinya di tengah dot
              top: 16, // mulai dari bawah dot
              bottom: 0,
              child: Container(width: 2, color: const Color(0xFFE0E0E0)),
            ),

          // === ISI TIMELINE ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DOT
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),

              const SizedBox(width: 20),

              // TEKS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
