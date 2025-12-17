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

      locationText =
      await _getDistrictCityProvince(pos.latitude, pos.longitude);
      _googleAddress =
      await _reverseGeocode(pos.latitude, pos.longitude);

      _weather = await _fetchWeather(pos);

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (data["status"] == "OK") {
      return data["results"][0]["formatted_address"];
    }
    return "Alamat tidak ditemukan";
  }

  Future<String> _getDistrictCityProvince(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'];
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["results"].isEmpty) return "Lokasi tidak diketahui";

    final components = data["results"][0]["address_components"];

    String? district, city, province;

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

    return Map<String, dynamic>.from(json);
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location service tidak aktif');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen');
    }

    return Geolocator.getCurrentPosition();
  }

  String get conditionText {
    final type = _weather?['weatherCondition']?['type'] ?? '';
    if (type.contains("LIGHT_RAIN")) return "Hujan Ringan";
    if (type.contains("RAIN")) return "Hujan";
    if (type.contains("CLOUD")) return "Berawan";
    if (type.contains("CLEAR")) return "Cerah";
    return "Cuaca";
  }

  IconData get conditionIcon {
    final type = _weather?['weatherCondition']?['type'] ?? '';
    if (type.contains("RAIN")) return Icons.umbrella;
    if (type.contains("CLOUD")) return Icons.cloud;
    return Icons.wb_sunny;
  }

  String _val(dynamic v, [String unit = ""]) =>
      v != null ? "$v$unit" : "--";

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFED993E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              _buildGradientHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 260, 20, 24),
                child: Column(
                  children: [
                    _buildLocationCard(),
                    const SizedBox(height: 24),
                    _buildDetails(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    final now = DateTime.now();
    final date =
        "${["Minggu","Senin","Selasa","Rabu","Kamis","Jumat","Sabtu"][now.weekday]}, "
        "${now.day} ${["","Jan","Feb","Mar","Apr","Mei","Jun","Jul","Agu","Sep","Okt","Nov","Des"][now.month]} ${now.year}";

    return Container(
      height: 350,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/gradient.png"),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
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
          const SizedBox(height: 24),
          Icon(conditionIcon, size: 90, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            conditionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(date, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

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
          Text(_googleAddress ?? "-"),
        ],
      ),
    );
  }

  Widget _buildDetails() {
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _tile("Suhu", _val(_weather?['temperature']?['degrees'], "°C"),
                "Terukur", Icons.thermostat),
            _tile(
                "Feels like",
                _val(
                    _weather?['feelsLikeTemperature']?['degrees'], "°C"),
                "Terasa",
                Icons.device_thermostat),
            _tile("Kelembapan",
                _val(_weather?['relativeHumidity'], "%"),
                "Relative humidity", Icons.water_drop),
            _tile("Cloud cover",
                _val(_weather?['cloudCover'], "%"),
                "Tingkat awan", Icons.cloud),
            _tile(
              "Presipitasi",
              "Kemungkinan hujan (${_weather?['precipitation']?['probability']?['percent'] ?? 0}%)",
              "",
              Icons.umbrella,
              full: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(
      String title,
      String value,
      String desc,
      IconData icon, {
        bool full = false,
      }) {
    return Container(
      width: full
          ? double.infinity
          : (MediaQuery.of(context).size.width - 52) / 2,
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (desc.isNotEmpty)
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.grey)),
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
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}