import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class LokasiParkirPage extends StatefulWidget {
  const LokasiParkirPage({super.key});

  @override
  State<LokasiParkirPage> createState() => _LokasiParkirPageState();
}

class _LokasiParkirPageState extends State<LokasiParkirPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? activeParking;
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  final Completer<GoogleMapController> _controller = Completer();

  final TextEditingController namaParkirController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedFilter = 'Semua';

  double? previewLat;
  double? previewLng;

  @override
  void initState() {
    super.initState();
    loadParkingData();
    loadPreviewLocation();
  }

  @override
  void dispose() {
    namaParkirController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

    try {
      final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey");

      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data["status"] == "OK") {
        return data["results"][0]["formatted_address"];
      }
    } catch (_) {}

    return "Alamat tidak ditemukan";
  }

  Future<void> loadPreviewLocation() async {
    try {
      await Geolocator.requestPermission();

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        previewLat = pos.latitude;
        previewLng = pos.longitude;
      });
    } catch (e) {
      print("Preview Error: $e");
    }
  }

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

    for (final row in res) {
      final data = Map<String, dynamic>.from(row);

      if (data["status"] == true && activeParking == null) {
        activeParking = data;
      } else {
        history.add(data);
      }
    }

    setState(() => loading = false);
  }

  Future<void> saveParkingLocation() async {
    if (namaParkirController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Nama parkir harus diisi")));
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User belum login")));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final alamat = await reverseGeocode(pos.latitude, pos.longitude);

      final now = DateTime.now();
      final tanggal =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final waktu =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      await Supabase.instance.client
          .from('parking')
          .update({"status": false})
          .eq('userid', user.id)
          .eq('status', true);

      final inserted = await Supabase.instance.client
          .from('parking')
          .insert({
            "userid": user.id,
            "latitude": pos.latitude,
            "longitude": pos.longitude,
            "tanggal": tanggal,
            "waktu": waktu,
            "status": true,
            "nama_parkir": namaParkirController.text.trim(),
            "alamat": alamat,
          })
          .select()
          .single();

      activeParking = inserted;
      namaParkirController.clear();

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi parkir berhasil disimpan")),
      );
    } catch (e) {
      print("Insert error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    }
  }

  Future<void> endParkingSession(int id) async {
    try {
      await Supabase.instance.client
          .from('parking')
          .update({"status": false})
          .eq('id', id);

      if (activeParking != null && activeParking!["id"] == id) {
        final finished = Map<String, dynamic>.from(activeParking!);
        finished["status"] = false;
        history.insert(0, finished);
        activeParking = null;
      }

      setState(() {});
    } catch (e) {
      print("End session error: $e");
    }
  }

  Future<void> openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  bool _matchSearch(data) {
    if (searchQuery.isEmpty) return true;

    final nama = (data["nama_parkir"] ?? "").toString().toLowerCase();
    return nama.contains(searchQuery.toLowerCase());
  }

  bool _matchFilter(data) {
    if (selectedFilter == "Semua") return true;

    if (data["tanggal"] == null) return false;

    final t = DateTime.tryParse(data["tanggal"]);
    if (t == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (selectedFilter == "Hari ini") {
      return DateTime(t.year, t.month, t.day) == today;
    }

    if (selectedFilter == "Minggu ini") {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return t.isAfter(start.subtract(const Duration(seconds: 1))) &&
          t.isBefore(start.add(const Duration(days: 7)));
    }

    if (selectedFilter == "Bulan ini") {
      return t.year == now.year && t.month == now.month;
    }

    return true;
  }

  List<Map<String, dynamic>> get filteredHistory =>
      history.where((h) => _matchSearch(h) && _matchFilter(h)).toList();

  bool get showActiveCard {
    if (activeParking == null) return false;
    return _matchSearch(activeParking!) && _matchFilter(activeParking!);
  }

  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 12, 22, 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xffE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xffC7C7C7)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                  hintText: "Search lokasi parkir...", border: InputBorder.none),
            ),
          ),
          Icon(
            Icons.tune_rounded,
            color: selectedFilter == 'Semua'
                ? const Color(0xffC7C7C7)
                : Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget buildMapPreview() {
    if (previewLat == null || previewLng == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Text("Mengambil lokasi..."),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          onMapCreated: (controller) {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
            }
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(previewLat!, previewLng!),
            zoom: 17,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("current"),
              position: LatLng(previewLat!, previewLng!),
            ),
          },
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

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
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text("Lokasi Parkir",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ]),

          const SizedBox(height: 15),

          buildMapPreview(),
          const SizedBox(height: 20),

          TextField(
            controller: namaParkirController,
            decoration: InputDecoration(
              hintText: "Masukkan nama lokasi parkir...",
              filled: true,
              fillColor: const Color(0xffF8F8F8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 20),

          // FIXED BUTTON
          Material(
            borderRadius: BorderRadius.circular(40),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () async {
                FocusScope.of(context).unfocus();
                await saveParkingLocation();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: const Color(0xffDCDCDC))),
                alignment: Alignment.center,
                child: const Text(
                  "Simpan Lokasi Parkir",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActiveCard() {
    final lat = (activeParking!["latitude"] as num).toDouble();
    final lng = (activeParking!["longitude"] as num).toDouble();

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
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activeParking!["nama_parkir"] ?? "-",
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text("Active",
                        style: TextStyle(color: Colors.green)),
                  ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(children: [
                    Text(activeParking!["waktu"] ?? "-"),
                    const SizedBox(width: 6),
                    const Icon(Icons.access_time, size: 18),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(activeParking!["tanggal"] ?? "-"),
                    const SizedBox(width: 6),
                    const Icon(Icons.calendar_today, size: 18),
                  ]),
                ],
              )
            ],
          ),

          const SizedBox(height: 12),

          Text(
            activeParking!["alamat"] ?? "Alamat tidak ditemukan",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => openInGoogleMaps(lat, lng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border:
                            Border.all(color: const Color(0xffDCDCDC))),
                    alignment: Alignment.center,
                    child: const Text("Tuju Lokasi Parkir"),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => endParkingSession(activeParking!["id"]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border:
                            Border.all(color: const Color(0xffDCDCDC))),
                    alignment: Alignment.center,
                    child: const Text("Akhiri Sesi Parkir"),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildHistoryCard(Map<String, dynamic> data) {
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
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data["nama_parkir"] ?? "-",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            data["alamat"] ?? "Alamat tidak ditemukan",
            style: const TextStyle(
                fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(data["waktu"] ?? "-"),
              const SizedBox(width: 6),
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 20),
              Text(data["tanggal"] ?? "-"),
              const SizedBox(width: 6),
              const Icon(Icons.calendar_today, size: 18),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleHistory = filteredHistory;

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Lokasi Parkir",
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  buildSearchBar(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTopCard(),

                        if (showActiveCard) buildActiveCard(),

                        const SizedBox(height: 30),

                        const Row(children: [
                          Icon(Icons.history),
                          SizedBox(width: 8),
                          Text(
                            "Riwayat Lokasi Parkir",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),

                        if (visibleHistory.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text("Belum ada riwayat parkir.",
                                style: TextStyle(color: Colors.grey)),
                          ),

                        for (final h in visibleHistory)
                          buildHistoryCard(h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
