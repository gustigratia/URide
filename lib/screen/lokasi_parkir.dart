import 'package:flutter/material.dart';

class LokasiParkir extends StatelessWidget {
  const LokasiParkir({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double scale(num value) => value * (width / 390);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scale(20),
                vertical: scale(10),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: scale(20),
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: scale(16)),
                  Expanded(
                    child: Text(
                      "Lokasi Parkir",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: scale(20),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: scale(36)),
                ],
              ),
            ),

            // CONTENT (SCROLLABLE)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: scale(16)),

                  // SEARCH BAR (now scrollable)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scale(20)),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: scale(16)),
                      height: scale(50),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(scale(14)),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/icons/search.png",
                            width: scale(20),
                            height: scale(20),
                            color: Colors.grey,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: scale(10)),
                          Text(
                            "Search...",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: scale(14),
                            ),
                          ),
                          Spacer(),
                          Image.asset(
                            "assets/icons/filter.png",
                            width: scale(20),
                            height: scale(20),
                            color: Colors.grey,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: scale(20)),

                  // CARD PARKIR TERKINI
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scale(20)),
                    child: parkirTerkiniCard(scale),
                  ),

                  SizedBox(height: scale(20)),

                  // TITLE: RIWAYAT
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scale(20)),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/clock.png",
                          width: scale(20),
                          height: scale(20),
                          fit: BoxFit.contain,
                          color: Colors.black87,
                        ),
                        SizedBox(width: scale(8)),
                        Text(
                          "Riwayat",
                          style: TextStyle(
                            fontSize: scale(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scale(12)),

                  // HISTORY LIST
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scale(20)),
                    child: Column(
                      children: [
                        historyItem(
                          scale: scale,
                          alamat:
                              "Jl. Sulawesi, Ngagel, Kec. Wonokromo, Surabaya, Jawa Timur 60281",
                          tanggal: "24 April 2024",
                          jam: "13.21",
                        ),
                        historyItem(
                          scale: scale,
                          alamat:
                              "Jl. Dharmahusada No.144, Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60285",
                          tanggal: "23 April 2024",
                          jam: "12.23",
                        ),
                        historyItem(
                          scale: scale,
                          alamat:
                              "Kampus A UNAIR, Jl. Prof. DR. Moestopo No.47, Pacar Kembang,\nKec. Tambaksari, Surabaya, Jawa Timur 60132",
                          tanggal: "20 April 2024",
                          jam: "06.21",
                        ),
                        historyItem(
                          scale: scale,
                          alamat:
                              "Jl. Pahlawan, Alun-alun Contong, Kec. Bubutan, Surabaya, Jawa Timur",
                          tanggal: "19 April 2024",
                          jam: "10.12",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: scale(20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PARKIR TERKINI CARD
  Widget parkirTerkiniCard(Function scale) {
    return Container(
      padding: EdgeInsets.all(scale(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                "assets/icons/location.png",
                width: scale(22),
                height: scale(22),
                fit: BoxFit.contain,
              ),
              SizedBox(width: scale(8)),
              Text(
                "Lokasi Parkir",
                style: TextStyle(
                  fontSize: scale(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: scale(16)),

          ClipRRect(
            borderRadius: BorderRadius.circular(scale(14)),
            child: Image.asset(
              "assets/images/map_placeholder.png",
              height: scale(170),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          SizedBox(height: scale(18)),

          Text(
            "Jl. Raya Kertajaya Indah No.79, Manyar Sabrangan,\n"
            "Kec. Mulyorejo, Surabaya, Jawa Timur 60116",
            style: TextStyle(
              fontSize: scale(15),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),

          SizedBox(height: scale(20)),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "assets/icons/calendar.png",
                        width: scale(18),
                        height: scale(18),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: scale(8)),
                      Text(
                        "24 April 2024",
                        style: TextStyle(
                          fontSize: scale(14),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: scale(10)),
                  Row(
                    children: [
                      Image.asset(
                        "assets/icons/clock.png",
                        width: scale(18),
                        height: scale(18),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: scale(8)),
                      Text(
                        "13.21",
                        style: TextStyle(
                          fontSize: scale(14),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale(18),
                  vertical: scale(10),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scale(40)),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Text(
                      "Tuju Lokasi",
                      style: TextStyle(
                        fontSize: scale(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: scale(10)),
                    Image.asset(
                      "assets/icons/arrow.png",
                      width: scale(16),
                      height: scale(16),
                      fit: BoxFit.contain,
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

  // HISTORY ITEM CARD
  Widget historyItem({
    required Function scale,
    required String alamat,
    required String tanggal,
    required String jam,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: scale(14)),
      padding: EdgeInsets.all(scale(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              alamat,
              style: TextStyle(
                fontSize: scale(15),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: scale(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    tanggal,
                    style: TextStyle(
                      fontSize: scale(14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(width: scale(6)),
                  Image.asset(
                    "assets/icons/calendar.png",
                    width: scale(18),
                    height: scale(18),
                    fit: BoxFit.contain,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              SizedBox(height: scale(10)),
              Row(
                children: [
                  Text(
                    jam,
                    style: TextStyle(
                      fontSize: scale(14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(width: scale(6)),
                  Image.asset(
                    "assets/icons/clock.png",
                    width: scale(18),
                    height: scale(18),
                    fit: BoxFit.contain,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
