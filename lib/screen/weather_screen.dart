import 'dart:async';
import 'dart:convert';

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
      } catch (_) {}

      _weather = await _fetchWeather(pos);

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location service tidak aktif');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi permanen ditolak');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, dynamic>> _fetchWeather(Position pos) async {
    final apiKey = dotenv.env['MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('MAPS_API_KEY tidak ditemukan di .env');
    }

    final uri = Uri.parse(
      'https://weather.googleapis.com/v1/currentConditions:lookup'
      '?key=$apiKey'
      '&location.latitude=${pos.latitude}'
      '&location.longitude=${pos.longitude}'
      '&unitsSystem=METRIC',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Weather API error (HTTP ${res.statusCode})');
    }

    final json = jsonDecode(res.body);

    if (json['currentConditions'] is List &&
        json['currentConditions'].isNotEmpty) {
      return Map<String, dynamic>.from(json['currentConditions'][0]);
    }

    if (json.containsKey('weatherCondition')) return json;

    for (final v in json.values) {
      if (v is Map<String, dynamic> && v.containsKey('weatherCondition')) {
        return v;
      }
      if (v is List &&
          v.isNotEmpty &&
          v.first is Map &&
          v.first.containsKey('weatherCondition')) {
        return Map<String, dynamic>.from(v.first);
      }
    }

    throw Exception("Format API tidak sesuai: $json");
  }


  int? get precipPercent {
    final p = _weather?['precipitation']?['probability']?['percent'];
    return p is num ? p.toInt() : null;
  }

  String get conditionText {
    final type = _weather?['weatherCondition']?['type']?.toUpperCase() ?? '';
    final desc = _weather?['weatherCondition']?['description']?['text'];

    if (type.contains("LIGHT_RAIN")) return "Hujan ringan";
    if (type.contains("RAIN")) return "Hujan";
    if (type.contains("CLEAR")) return "Cerah";
    if (type.contains("PARTLY_CLOUDY")) return "Berawan sebagian";
    if (type.contains("CLOUDY")) return "Berawan";
    if (type.contains("FOG")) return "Berkabut";

    return desc ?? "Cuaca tidak diketahui";
  }

  IconData get conditionIcon {
    final type = _weather?['weatherCondition']?['type']?.toUpperCase() ?? '';

    if (type.contains("LIGHT_RAIN")) return Icons.grain;          // gerimis
    if (type.contains("RAIN")) return Icons.umbrella;             // hujan
    if (type.contains("SNOW")) return Icons.ac_unit;              // salju
    if (type.contains("FOG")) return Icons.deblur;                // kabut
    if (type.contains("CLOUD")) return Icons.cloud;               // berawan
    if (type.contains("CLEAR")) return Icons.wb_sunny;            // cerah

    return Icons.wb_sunny;
  }

  double? get tempC =>
      _weather?['temperature']?['degrees']?.toDouble();

  double? get feelsLikeC =>
      _weather?['feelsLikeTemperature']?['degrees']?.toDouble();

  int? get humidity => _weather?['relativeHumidity'];
  int? get cloud => _weather?['cloudCover'];

  String get _headerAddress {
    if (_address != null && _address!.isNotEmpty) return _address!;
    if (_pos == null) return "Lokasi tidak diketahui";
    return "Lat ${_pos!.latitude.toStringAsFixed(3)}, "
        "Lng ${_pos!.longitude.toStringAsFixed(3)}";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    final isSmall = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFED993E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            _buildHeaderWithHero(isSmall),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildLocationCard(),
                    const SizedBox(height: 20),
                    _buildDetailsGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //HEADER
  Widget _buildHeader(bool small) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFF9A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
      ),
      child: Row(
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  //HERO SECTION

  Widget _buildHeaderWithHero(bool small) {
  final now = DateTime.now();

  String dayName(int d) {
    switch (d) {
      case 1: return "Senin";
      case 2: return "Selasa";
      case 3: return "Rabu";
      case 4: return "Kamis";
      case 5: return "Jumat";
      case 6: return "Sabtu";
      default: return "Minggu";
    }
  }

  String monthName(int m) {
    const bulan = [
      "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return bulan[m];
  }

  final date = "${dayName(now.weekday)}, ${now.day} ${monthName(now.month)} ${now.year}";

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFFD93D), Color(0xFFFF9A3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(26),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
        const SizedBox(height: 10),

        Center(
          child: Column(
            children: [
              Icon(
                conditionIcon,
                size: small ? 70 : 90,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                conditionText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: small ? 22 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  //LOCATION CARD
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Lokasi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _address ?? "Alamat tidak tersedia",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "Latitude: ${_pos?.latitude.toStringAsFixed(6)}\n"
            "Longitude: ${_pos?.longitude.toStringAsFixed(6)}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // DETAILS GRID

  Widget _buildDetailsGrid() {
  final t = tempC != null ? "${tempC!.toStringAsFixed(1)}°C" : "--";
  final f = feelsLikeC != null ? "${feelsLikeC!.toStringAsFixed(1)}°C" : "--";
  final h = humidity != null ? "$humidity%" : "--";
  final c = cloud != null ? "$cloud%" : "--";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Rincian",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      const SizedBox(height: 14),

      LayoutBuilder(
        builder: (context, cst) {
          final half = (cst.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _tile(half, Icons.thermostat, "Suhu", t, "Terukur"),
              _tile(half, Icons.device_thermostat, "Feels like", f, "Terasa"),
              _tile(half, Icons.water_drop, "Kelembapan", h, "Relative humidity"),
              _tile(half, Icons.cloud, "Cloud cover", c, "Tingkat awan"),
              _tile(
                cst.maxWidth,
                Icons.umbrella,
                "Presipitasi",
                "Kemungkinan hujan (${precipPercent ?? 0}%)",
                "",
              ),
            ],
          );
        },
      ),
    ],
  );
}


  Widget _tile(double width, IconData icon, String label, String val, String desc) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: _whiteCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2CC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFFA000)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  val,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (desc.isNotEmpty)
                  Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
