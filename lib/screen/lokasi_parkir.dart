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
  // FETCH & PROCESS PARKING DATA
  // ============================================================
  Future<void> loadParkingData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from('parking')
        .select('*')
        .eq('userid', user.id)
        .order('id', ascending: false);

    activeParking = null;
    history.clear();

    for (var raw in res) {
      final row = Map<String, dynamic>.from(raw);
      final bool isActive = (row["status"] == true);

      if (isActive && activeParking == null) {
        activeParking = row;
      } else {
        history.add(row);
      }
    }

    setState(() => loading = false);
  }

  // ============================================================
  // GEOCODE → GET ADDRESS
  // ============================================================
  Future<String> getAddress(double lat, double lng) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$GOOGLE_API_KEY",
    );

    final res = await http.get(url);
    final body = jsonDecode(res.body);

    if (body["status"] == "OK") {
      return body["results"][0]["formatted_address"];
    }
    return "Alamat tidak ditemukan";
  }

  // ============================================================
  // SAVE NEW PARKING SESSION (SET ACTIVE)
  // ============================================================
  Future<void> saveParkingLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final user = Supabase.instance.client.auth.currentUser!;
      final now = DateTime.now();

      final tanggal =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final waktu =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

      // MATIKAN SEMUA SESI ACTIVE SEBELUMNYA
      await Supabase.instance.client
          .from('parking')
          .update({"status": false})
          .eq('userid', user.id)
          .eq('status', true);

      // INSERT SESI BARU
      await Supabase.instance.client.from('parking').insert({
        "userid": user.id,
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "tanggal": tanggal,
        "waktu": waktu,
        "status": true, // ACTIVE
      });

      await loadParkingData();
    } catch (e) {
      print("ERROR INSERT: $e");
    }
  }

  // ============================================================
  // END ACTIVE SESSION
  // ============================================================
  Future<void> endParkingSession(int id) async {
    await Supabase.instance.client
        .from('parking')
        .update({"status": false})
        .eq('id', id);

    await loadParkingData();
  }

  // ============================================================
  // OPEN GOOGLE MAPS
  // ============================================================
  Future<void> openInGoogleMaps(double lat, double lng) async {
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // TOP STATIC CARD — ALWAYS VISIBLE
  // ============================================================
  Widget buildTopCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text("Lokasi Parkir",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ],
          ),

          const SizedBox(height: 20),

          // BUTTON SIMPAN LOKASI PARKIR
          GestureDetector(
            onTap: saveParkingLocation,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xffDCDCDC)),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Simpan Lokasi Parkir",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(width: 10),
                  Image.asset("assets/icons/arrow.png", height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE SESSION CARD — WITH 2 BUTTONS
  // ============================================================
  Widget buildActiveCard() {
    final lat = activeParking!["latitude"] * 1.0;
    final lng = activeParking!["longitude"] * 1.0;

    return Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ADDRESS
          FutureBuilder(
            future: getAddress(lat, lng),
            builder: (c, s) => Text(
              s.data?.toString() ?? "Memuat alamat...",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // DATE + TIME + STATUS
          Row(
            children: [
              Text(activeParking!["tanggal"]),
              const Spacer(),
              Text(activeParking!["waktu"]),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 18),
            ],
          ),

          const SizedBox(height: 6),
          const Text("Active",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.green)),

          const SizedBox(height: 20),

          // BUTTONS ROW
          Row(
            children: [
              // TUJU LOKASI
              Expanded(
                child: GestureDetector(
                  onTap: () => openInGoogleMaps(lat, lng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xffDCDCDC)),
                      color: Colors.white,
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Tuju Lokasi Parkir",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                          const SizedBox(width: 10),
                          Image.asset("assets/icons/arrow.png", height: 16),
                        ]),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // AKHIRI SESI
              Expanded(
                child: GestureDetector(
                  onTap: () => endParkingSession(activeParking!["id"]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xffDCDCDC)),
                      color: Colors.white,
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Akhiri Sesi Parkir",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                          const SizedBox(width: 10),
                          Image.asset("assets/icons/arrow.png", height: 16),
                        ]),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================
  Widget buildHistoryCard(Map<String, dynamic> data) {
    final lat = data["latitude"] * 1.0;
    final lng = data["longitude"] * 1.0;

    return Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder(
            future: getAddress(lat, lng),
            builder: (c, s) => Text(
              s.data?.toString() ?? "Memuat alamat...",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(data["tanggal"]),
              const Spacer(),
              Text(data["waktu"]),
              const SizedBox(width: 6),
              const Icon(Icons.access_time, size: 18),
            ],
          ),

          const SizedBox(height: 6),
          const Text("Passed",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent)),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Lokasi Parkir",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTopCard(),

                  if (activeParking != null) buildActiveCard(),

                  const SizedBox(height: 25),
                  const Text("Riwayat",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text("Belum ada riwayat parkir.",
                          style: TextStyle(color: Colors.grey)),
                    ),

                  for (final h in history) buildHistoryCard(h),
                ],
              ),
            ),
    );
  }
}
