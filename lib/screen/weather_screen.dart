import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  bool _loading = true;
  String? _error;

  String? _googleAddress;
  String locationText = "Memuat lokasi...";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await _determinePosition();
      _pos = pos;

      locationText = await getDistrictCityProvince(pos.latitude, pos.longitude);

      _googleAddress = await reverseGeocode(pos.latitude, pos.longitude);

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

  // REVERSE GEOCODING GOOGLE
  Future<String> reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey",
    );

    try {
      final res = await http.get(url);
      final jsonData = jsonDecode(res.body);

      if (jsonData["status"] == "OK") {
        return jsonData["results"][0]["formatted_address"];
      }
    } catch (_) {}

    return "Alamat tidak ditemukan";
  }

  Future<String> getDistrictCityProvince(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'];
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["results"].isEmpty) return "Lokasi tidak diketahui";

    List components = data["results"][0]["address_components"];

    String? district;
    String? city;
    String? province;

    for (var c in components) {
      if (c["types"].contains("administrative_area_level_3")) {
        district = c["long_name"];
      }
      if (c["types"].contains("administrative_area_level_2")) {
        city = c["long_name"];
      }
      if (c["types"].contains("administrative_area_level_1")) {
        province = c["long_name"];
      }
    }

    return "$district, $city, $province";
  }

  // GET WEATHER
  Future<Map<String, dynamic>> _fetchWeather(Position pos) async {
    final apiKey = dotenv.env['MAPS_API_KEY'];
    final uri = Uri.parse(
      'https://weather.googleapis.com/v1/currentConditions:lookup'
      '?key=$apiKey'
      '&location.latitude=${pos.latitude}'
      '&location.longitude=${pos.longitude}'
      '&unitsSystem=METRIC',
    );

    final res = await http.get(uri);
    final json = jsonDecode(res.body);

    if (json['currentConditions'] is List &&
        json['currentConditions'].isNotEmpty) {
      return Map<String, dynamic>.from(json['currentConditions'][0]);
    }

    return json;
  }

  // LOCATION PERMISSION
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

  // WEATHER TEXT
  String get conditionText {
    final type = _weather?['weatherCondition']?['type']?.toUpperCase() ?? '';

    if (type.contains("LIGHT_RAIN")) return "Hujan Ringan";
    if (type.contains("RAIN")) return "Hujan";
    if (type.contains("CLEAR")) return "Cerah";
    if (type.contains("PARTLY_CLOUDY")) return "Berawan Sebagian";
    if (type.contains("CLOUDY")) return "Berawan";
    if (type.contains("FOG")) return "Berkabut";

    return "Cuaca tidak diketahui";
  }

  IconData get conditionIcon {
    final type = _weather?['weatherCondition']?['type']?.toUpperCase() ?? '';

    if (type.contains("RAIN")) return Icons.umbrella;
    if (type.contains("CLOUD")) return Icons.cloud;
    if (type.contains("FOG")) return Icons.deblur;

    return Icons.wb_sunny;
  }

  double? get tempC => _weather?['temperature']?['degrees']?.toDouble();
  double? get feelsLikeC =>
      _weather?['feelsLikeTemperature']?['degrees']?.toDouble();
  int? get humidity => _weather?['relativeHumidity'];
  int? get cloud => _weather?['cloudCover'];
  int? get precipPercent =>
      _weather?['precipitation']?['probability']?['percent'];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
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
              Padding(
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

  // HEADER + HERO
  Widget _buildHeaderWithHero(bool small) {
    final now = DateTime.now();
    final dayNames = [
      "Minggu",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
    ];
    final months = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];

    final date =
        "${dayNames[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/images/gradient.png"),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Icon(conditionIcon, size: small ? 70 : 90, color: Colors.white),
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
          Text(date, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // LOCATION CARD
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Lokasi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _googleAddress ?? "Alamat tidak ditemukan",
            style: const TextStyle(fontSize: 14),
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
            color: Colors.white,
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
                _tile(
                  half,
                  Icons.water_drop,
                  "Kelembapan",
                  h,
                  "Relative humidity",
                ),
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

  // TILE
  Widget _tile(
    double width,
    IconData icon,
    String label,
    String val,
    String desc,
  ) {
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
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
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
