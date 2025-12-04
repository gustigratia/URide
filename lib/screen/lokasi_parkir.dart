import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const String GOOGLE_API_KEY = "ISI_API_KEY_KAMU";

class LokasiParkirPage extends StatefulWidget {
  const LokasiParkirPage({super.key});

  @override
  State<LokasiParkirPage> createState() => _LokasiParkirPageState();
}

class _LokasiParkirPageState extends State<LokasiParkirPage> {
  Map<String, dynamic>? activeParking;
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadParkingData();
  }

  // ============================================================
  //  LOAD DATA PARKING
  // ============================================================
  Future<void> loadParkingData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final res = await Supabase.instance.client
        .from('parking')
        .select('*')
        .eq('userid', user.id)
        .order('id', ascending: false);

    if (res.isNotEmpty) {
      activeParking = res.first;
      if (res.length > 1) {
        history = res.sublist(1).map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    setState(() => loading = false);
  }

  // ============================================================
  // AMBIL ALAMAT DARI LAT / LNG
  // ============================================================
  Future<String> getAddress(double lat, double lng) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$GOOGLE_API_KEY");

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data["status"] == "OK") {
      return data["results"][0]["formatted_address"];
    } else {
      return "Alamat tidak ditemukan";
    }
  }

  // ============================================================
  //  SIMPAN LOKASI PARKIR KE DATABASE
  // ============================================================
  Future<void> saveParkingLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final user = Supabase.instance.client.auth.currentUser;

      final now = DateTime.now();
      final tanggal = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final waktu = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

      final res = await Supabase.instance.client.from('parking').insert({
        'userid': user!.id,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'tanggal': tanggal,
        'waktu': waktu,
      }).select();

      print("INSERT RESULT = $res");

      loadParkingData();
    } catch (e) {
      print("ERROR INSERT: $e");
    }
  }

  // ============================================================
  //  OPEN GOOGLE MAPS
  // ============================================================
  Future<void> openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak bisa membuka Google Maps");
    }
  }

  // ============================================================
  //  CARD LOKASI PARKIR (AKTIF)
  // ============================================================
  Widget buildActiveCard() {
    final lat = activeParking!["latitude"];
    final lng = activeParking!["longitude"];
    final tanggal = activeParking!["tanggal"];
    final waktu = activeParking!["waktu"];

    final mapUrl =
        "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng"
        "&zoom=17&size=600x300&maptype=roadmap&markers=color:red%7C$lat,$lng"
        "&key=$GOOGLE_API_KEY";

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Lokasi Parkir",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              mapUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 14),

          FutureBuilder(
            future: getAddress(lat, lng),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text("Memuat alamat...");
              }
              return Text(
                snapshot.data!,
                style: const TextStyle(fontSize: 14),
              );
            },
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text("$tanggal"),
              const SizedBox(width: 18),
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text("$waktu"),
            ],
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => openInGoogleMaps(lat, lng),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("Tuju Lokasi Parkir", style: TextStyle(color: Colors.black)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ============================================================
  //  CARD RIWAYAT
  // ============================================================
  Widget buildHistoryCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder(
            future: getAddress(data["latitude"], data["longitude"]),
            builder: (c, s) =>
                Text(s.data?.toString() ?? "Memuat alamat..."),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text("${data["tanggal"]}"),
              const Spacer(),
              Text("${data["waktu"]}"),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BUILD UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Lokasi Parkir",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BUTTON SIMPAN LOKASI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveParkingLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFAE9C4),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Simpan Lokasi Parkir",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (activeParking != null) buildActiveCard(),

            const SizedBox(height: 20),
            const Text(
              "Riwayat",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Belum ada riwayat parkir.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            for (var item in history) buildHistoryCard(item),
          ],
        ),
      ),
    );
  }
}
