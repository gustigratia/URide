import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LokasiParkirPage extends StatefulWidget {
  const LokasiParkirPage({super.key});

  @override
  State<LokasiParkirPage> createState() => _LokasiParkirPageState();
}

class _LokasiParkirPageState extends State<LokasiParkirPage> {
  Map<String, dynamic>? activeParking;
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  final TextEditingController namaParkirController = TextEditingController();

  // Search bar controller
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

  // GET CURRENT LOCATION (UNTUK PREVIEW MAP) - SEKALI SAJA
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

  // LOAD DATA PARKIR USER (HANYA SAAT INIT / REFRESH PENUH)
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
      if (row["status"] == true && activeParking == null) {
        activeParking = row;
      } else {
        history.add(row);
      }
    }

    setState(() => loading = false);
  }

  // SIMPAN LOKASI PARKIR BARU
  Future<void> saveParkingLocation() async {
    if (namaParkirController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama parkir harus diisi")),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User belum login")),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final now = DateTime.now();
      final tanggal =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final waktu =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";

      if (activeParking != null) {
        final old = Map<String, dynamic>.from(activeParking!);
        old["status"] = false;
        history.insert(0, old);
      }

      await Supabase.instance.client
          .from('parking')
          .update({"status": false})
          .eq('userid', user.id)
          .eq('status', true);

      // INSERT SESI BARU + KEMBALIKAN ROW-NYA (BIAR DAPAT ID)
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
          })
          .select()
          .single();

      activeParking = Map<String, dynamic>.from(inserted);
      namaParkirController.clear();

      setState(() {});
    } catch (e) {
      print("Insert error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan lokasi parkir")),
      );
    }
  }

  // AKHIRI SESI PARKIR AKTIF
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengakhiri sesi parkir")),
      );
    }
  }

  // OPEN GOOGLE MAPS 
  Future<void> openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // SEARCH & FILTER HELPER
  bool _matchSearch(Map<String, dynamic> data) {
    if (searchQuery.trim().isEmpty) return true;
    final nama = (data["nama_parkir"] ?? "").toString().toLowerCase();
    return nama.contains(searchQuery.toLowerCase());
  }

  bool _matchFilter(Map<String, dynamic> data) {
    if (selectedFilter == 'Semua') return true;

    final tanggalStr = data["tanggal"]?.toString();
    if (tanggalStr == null) return false;

    DateTime? t;
    try {
      t = DateTime.parse(tanggalStr); 
    } catch (_) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (selectedFilter == 'Hari ini') {
      final d = DateTime(t.year, t.month, t.day);
      return d == today;
    }

    if (selectedFilter == 'Minggu ini') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1)); // Senin
      final d = DateTime(t.year, t.month, t.day);
      return d.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          d.isBefore(startOfWeek.add(const Duration(days: 7)));
    }

    if (selectedFilter == 'Bulan ini') {
      return t.year == now.year && t.month == now.month;
    }

    return true;
  }

  List<Map<String, dynamic>> get filteredHistory =>
      history.where((h) => _matchSearch(h) && _matchFilter(h)).toList();

  bool get showActiveCard {
    if (activeParking == null) return false;
    final m = activeParking!;
    return _matchSearch(m) && _matchFilter(m);
  }

  // FILTER
  void _openFilterSheet() {
    const options = ['Semua', 'Hari ini', 'Minggu ini', 'Bulan ini'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Riwayat",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final opt in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt,
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: Radio<String>(
                    value: opt,
                    groupValue: selectedFilter,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        selectedFilter = val;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      selectedFilter = opt;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // SEARCH BAR 
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
          const Icon(Icons.search, color: Color(0xffC7C7C7), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: "Search lokasi parkir...",
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xffC7C7C7),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openFilterSheet,
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: selectedFilter == 'Semua'
                      ? const Color(0xffC7C7C7)
                      : Colors.black87,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TOP CARD: MAP + INPUT + SIMPAN
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text(
                "Lokasi Parkir",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          if (previewLat != null && previewLng != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(previewLat!, previewLng!),
                    initialZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.uride',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(previewLat!, previewLng!),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xffF0F0F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "Mengambil lokasi...",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 20),

          TextField(
            controller: namaParkirController,
            decoration: InputDecoration(
              hintText: "Masukkan nama lokasi parkir...",
              filled: true,
              fillColor: const Color(0xffF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: saveParkingLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xffDCDCDC)),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Simpan Lokasi Parkir",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset("assets/icons/flag.png", height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ACTIVE CARD
  Widget buildActiveCard() {
    final lat = (activeParking!["latitude"] as num).toDouble();
    final lng = (activeParking!["longitude"] as num).toDouble();

    final String namaParkir = activeParking!["nama_parkir"] ?? "Lokasi Parkir";
    final String tanggal = activeParking!["tanggal"] ?? "";
    final String waktu = activeParking!["waktu"] ?? "";

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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaParkir,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        waktu,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        tanggal,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => openInGoogleMaps(lat, lng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xffDCDCDC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            "Tuju Lokasi Parkir",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          "assets/icons/arrow.png",
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () => endParkingSession(activeParking!["id"]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xffDCDCDC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            "Akhiri Sesi Parkir",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          "assets/icons/timer.png",
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HISTORY CARD
  Widget buildHistoryCard(Map<String, dynamic> data) {
    final nama = data["nama_parkir"] ?? "Lokasi tidak diketahui";
    final tanggal = data["tanggal"];
    final waktu = data["waktu"];

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Passed",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          // RIGHT SIDE — Jam & Tanggal (Stacked)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    waktu,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.black54,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    tanggal,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.black54,
                  ),
                ],
              ),
            ],
          ),
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
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Lokasi Parkir",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // search + filter bar
                  buildSearchBar(),

                  const SizedBox(height: 4),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTopCard(),

                        if (showActiveCard) buildActiveCard(),

                        const SizedBox(height: 30),
                        Row(
                          children: const [
                            Icon(
                              Icons.history,
                              size: 20,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Riwayat Lokasi Parkir",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        if (visibleHistory.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              "Belum ada riwayat parkir.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                        for (final h in visibleHistory) buildHistoryCard(h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
