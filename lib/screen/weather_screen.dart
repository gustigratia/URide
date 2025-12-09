import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Position? _pos;
  Map<String, dynamic>? _weather;
  String? _address;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await _determinePosition();
      _pos = pos;

      // Reverse geocoding aman
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          _address = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((e) => e != null && e!.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint("Reverse geocoding error: $e");
      }

      _weather = await _fetchWeather(pos);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------------- LOCATION ----------------

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location service tidak aktif");

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) throw Exception("Izin lokasi ditolak");
    }

    if (perm == LocationPermission.deniedForever) {
      throw Exception("Izin lokasi permanen ditolak");
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // ---------------- WEATHER API ----------------

  Future<Map<String, dynamic>> _fetchWeather(Position pos) async {
    final apiKey = dotenv.env['MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("MAPS_API_KEY kosong");
    }

    final url = Uri.parse(
      "https://weather.googleapis.com/v1/currentConditions:lookup"
      "?key=$apiKey"
      "&location.latitude=${pos.latitude}"
      "&location.longitude=${pos.longitude}"
      "&unitsSystem=METRIC",
    );

    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception("Weather API error");

    final json = jsonDecode(res.body);
    final list = json["currentConditions"];

    if (list is List && list.isNotEmpty) {
      return Map<String, dynamic>.from(list.first);
    }

    return json;
  }

  // ---------------- HELPERS ----------------

  int get precipPercent =>
      (_weather?["precipitation"]?["probability"]?["percent"] as num?)?.toInt() ?? 0;

  double get tempC =>
      (_weather?["temperature"]?["degrees"] as num?)?.toDouble() ?? 0;

  double get feelsLikeC =>
      (_weather?["feelsLikeTemperature"]?["degrees"] as num?)?.toDouble() ?? 0;

  int get humidity => (_weather?["relativeHumidity"] as num?)?.toInt() ?? 0;

  int get cloudCover => (_weather?["cloudCover"] as num?)?.toInt() ?? 0;

  String get conditionText {
    final type = _weather?["weatherCondition"]?["type"] ?? "";
    switch (type) {
      case "CLEAR":
        return "Cerah";
      case "PARTLY_CLOUDY":
        return "Berawan Sebagian";
      case "CLOUDY":
        return "Berawan";
      case "RAIN":
        return "Hujan";
      default:
        return _weather?["weatherCondition"]?["description"]?["text"] ??
            "Cuaca tidak diketahui";
    }
  }

  String get precipTitle {
    final p = precipPercent;
    if (p == 0) return "Tidak berpotensi\nhujan";
    if (p < 40) return "Kemungkinan\nhujan ringan";
    if (p < 70) return "Hujan sedang";
    return "Berpotensi\nhujan lebat";
  }

  String get precipSubtitle => "Kemungkinan hujan ($precipPercent%)";

  String get headerAddress {
    if (_address != null && _address!.isNotEmpty) return _address!;
    return "Lat ${_pos?.latitude}, Lng ${_pos?.longitude}";
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFED993E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFED993E),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // <--- BACKGROUND DIGANTI SESUAI PERMINTAAN
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _mainCard(),
                    const SizedBox(height: 20),
                    _locationInfo(),
                    const SizedBox(height: 20),
                    _detailsGrid(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER diperpanjang turun
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40), // <--- DIPERPANJANG
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFF9A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BACK
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                "Cuaca Saat Ini",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            headerAddress,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            conditionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          )
        ],
      ),
    );
  }

  Widget _mainCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kiri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  "$precipPercent%",
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  precipTitle,
                  style: const TextStyle(fontSize: 14, height: 1.2),
                ),
              ],
            ),
          ),

          // Kanan
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC93C), Color(0xFFFFD65C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset("assets/icons/weather.png", width: 38),
              ),
              const SizedBox(height: 6),
              Text(
                conditionText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Lokasi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 10),
          Text(_address ?? "Alamat tidak tersedia"),
          const SizedBox(height: 6),
          Text(
            "Latitude: ${_pos?.latitude}\nLongitude: ${_pos?.longitude}",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // UV INDEX DIHAPUS SESUAI PERMINTAAN
  Widget _detailsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rincian",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _detail("Suhu", "${tempC.toStringAsFixed(1)}°C", "Terukur", Icons.thermostat),
            _detail("Feels like", "${feelsLikeC.toStringAsFixed(1)}°C", "Terasa",
                Icons.device_thermostat),
            _detail("Kelembapan", "$humidity%", "Relative humidity",
                Icons.water_drop),
            _detail("Cloud cover", "$cloudCover%", "Tingkat awan", Icons.cloud),
            _detail("Presipitasi", precipSubtitle, "", Icons.umbrella),
          ],
        )
      ],
    );
  }

  Widget _detail(String title, String value, String desc, IconData icon) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Color(0xFFFFA000)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (desc.isNotEmpty)
                  Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
