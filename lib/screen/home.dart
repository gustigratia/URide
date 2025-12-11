import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  GoogleMapController? mapController;
  static const LatLng _defaultLocation = LatLng(-6.200000, 106.816666);
  List<Map<String, dynamic>> workshops = [];
  List<Map<String, dynamic>> spbu = [];
  String currentTrafficStatus = "Loading...";
  String currentDuration = "N/A";
  bool isLoading = true;
  Position? userPosition;
  String locationError = '';
  String firstName = "";
  String mapsApiKey = dotenv.env['MAPS_API_KEY'] ?? '';
  Map<String, dynamic>? _weather;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    // 1. Ambil API Key dari .env sebelum digunakan
    mapsApiKey = dotenv.env['MAPS_API_KEY'] ?? '';

    // Peringatan jika kunci tidak ditemukan
    if (mapsApiKey.isEmpty) {
      debugPrint("ERROR: MAPS_API_KEY not found in environment variables.");
    }

    await _loadFirstName();
    await _determinePosition();
    await _fetchTrafficStatus();
    await fetchData();
    await _loadWeather();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      locationError = '';
    });

    try {
      final workshopData = await supabase
          .from('workshops')
          .select()
          .order('id');
      final spbuData = await supabase.from('spbu').select().order('id');

      // Convert to List<Map<String,dynamic>>
      final w = List<Map<String, dynamic>>.from(workshopData);
      final s = List<Map<String, dynamic>>.from(spbuData);

      // Compute distance string for each item (if we have userPosition)
      final updatedW = w.map((e) => _withDistance(e)).toList();
      final updatedS = s.map((e) => _withDistance(e)).toList();

      if (mounted) {
        setState(() {
          workshops = updatedW;
          spbu = updatedS;
          isLoading = false;
        });
      }
    } catch (err, st) {
      debugPrint('Error fetching data from Supabase: $err\n$st');
      if (mounted) {
        setState(() {
          isLoading = false;
          locationError = 'Gagal mengambil data: $err';
        });
      }
    }
  }

  String get conditionText {
    final type = _weather?['weatherCondition']?['type']?.toUpperCase() ?? '';

    if (type.contains("LIGHT_RAIN")) return "Hujan Ringan";
    if (type.contains("RAIN")) return "Hujan";
    if (type.contains("CLEAR")) return "Cerah";
    if (type.contains("PARTLY_CLOUDY")) return "Berawan Sebagian";
    if (type.contains("CLOUDY")) return "Berawan";
    if (type.contains("FOG")) return "Berkabut";

    return "Tidak diketahui";
  }

  IconData get conditionIcon {
    final type = _weather?['weatherCondition']?['type']?.toUpperCase() ?? '';

    if (type.contains("RAIN")) return Icons.umbrella;
    if (type.contains("CLOUD")) return Icons.cloud;
    if (type.contains("FOG")) return Icons.deblur;

    return Icons.wb_sunny;
  }

  double? get tempC => _weather?['temperature']?['degrees']?.toDouble();
  int? get precipPercent =>
      _weather?['precipitation']?['probability']?['percent'];
  int? get humidity => _weather?['relativeHumidity'];

  Future<void> _loadWeather() async {
    try {
      if (userPosition == null) {
        print("DEBUG: userPosition null");
        return;
      }

      final pos = userPosition!;
      final uri = Uri.parse(
        'https://weather.googleapis.com/v1/currentConditions:lookup'
            '?key=$mapsApiKey'
            '&location.latitude=${pos.latitude}'
            '&location.longitude=${pos.longitude}'
            '&unitsSystem=METRIC',
      );

      print("DEBUG URL: $uri");

      final res = await http.get(uri);
      print("DEBUG status: ${res.statusCode}");
      print("DEBUG body: ${res.body}");

      final json = jsonDecode(res.body);

      // GOOGLE WEATHER API return langsung OBJECT, bukan list
      setState(() {
        _weather = Map<String, dynamic>.from(json);
        _isLoadingWeather = false;
      });
    } catch (e) {
      print("Weather error: $e");
      setState(() => _isLoadingWeather = false);
    }
  }

  LatLng offsetPosition(LatLng origin, double distanceMeters, double bearingDegrees) {
    const double earthRadius = 6371000; // meters
    final double bearing = bearingDegrees * pi / 180;

    final double lat1 = origin.latitude * pi / 180;
    final double lon1 = origin.longitude * pi / 180;

    final double lat2 = asin(
      sin(lat1) * cos(distanceMeters / earthRadius) +
          cos(lat1) * sin(distanceMeters / earthRadius) * sin(bearing),
    );

    final double lon2 = lon1 +
        atan2(
          sin(bearing) * sin(distanceMeters / earthRadius) * cos(lat1),
          cos(distanceMeters / earthRadius) - sin(lat1) * sin(lat2),
        );

    return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }

  Future<void> _fetchTrafficStatus() async {
    if (userPosition == null) {
      if (mounted) {
        setState(() {
          currentTrafficStatus = "Lokasi tidak tersedia";
          currentDuration = "--";
        });
      }
      return;
    }

    // Tambahkan cek kunci API
    if (mapsApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          currentTrafficStatus = "Kunci API Hilang";
          currentDuration = "N/A";
        });
      }
      return;
    }

    LatLng userLatLng = LatLng(
      userPosition!.latitude,
      userPosition!.longitude,
    );
    final LatLng origin = LatLng(userPosition!.latitude, userPosition!.longitude);

    final randomBearing = Random().nextInt(360).toDouble();
    LatLng destination = offsetPosition(userLatLng, 1000, randomBearing);

    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$mapsApiKey'
        '&departure_time=now';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final String durationText = leg['duration']['text'] ?? 'N/A';
          final int durationSeconds = leg['duration']['value'] ?? 0;

          String trafficStatus = "Macet";
          String durationWithTraffic = durationText;

          if (leg['duration_in_traffic'] != null) {
            final int trafficDurationSeconds = leg['duration_in_traffic']['value'] ?? durationSeconds;
            durationWithTraffic = leg['duration_in_traffic']['text'] ?? durationText;

            // Logika sederhana untuk menentukan status
            final double ratio = trafficDurationSeconds / durationSeconds;
            print("DEBUG ratio: $ratio");
            print("DEBUG duration: $durationSeconds | traffic: $trafficDurationSeconds");
            if (ratio >= 1.5) {
              trafficStatus = "Macet";
            } else if (ratio >= 1.2) {
              trafficStatus = "Padat";
            } else {
              trafficStatus = "Lancar";
            }
          }

          if (mounted) {
            setState(() {
              currentTrafficStatus = trafficStatus;
              currentDuration = durationWithTraffic;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              currentTrafficStatus = "Rute tidak ditemukan";
              currentDuration = "N/A";
            });
          }
        }
      } else {
        debugPrint('Failed to load traffic data: ${response.statusCode}');
        if (mounted) {
          setState(() {
            currentTrafficStatus = "Gagal mengambil data";
            currentDuration = "N/A";
          });
        }
      }
    } catch (e) {
      debugPrint('Traffic API Error: $e');
      if (mounted) {
        setState(() {
          currentTrafficStatus = "Error jaringan";
          currentDuration = "N/A";
        });
      }
    }
  }

  Future<void> _loadFirstName() async {
    print("=== LOAD FIRSTNAME START ===");

    final user = supabase.auth.currentUser;

    // Debug cek user
    if (user == null) {
      print("User is NULL (belum login)");
      return;
    }

    print("Current User ID: ${user.id}");

    try {
      print("Querying users table...");

      final data = await supabase
          .from('users')
          .select('firstname')
          .eq('id', user.id)
          .maybeSingle();

      print("Raw Supabase Response: $data");

      if (data == null) {
        print("Data is NULL → kemungkinan record belum ada di tabel users.");
        return;
      }

      if (data['firstname'] == null) {
        print("firstname is NULL → record ada tapi kolom kosong.");
        return;
      }

      print("Firstname found: ${data['firstname']}");

      if (mounted) {
        setState(() {
          firstName = data['firstname'];
        });
        print("Firstname set to state: $firstName");
      }
    } catch (e) {
      print("Error loading firstname: $e");
    }

    print("=== LOAD FIRSTNAME END ===");
  }

  Map<String, dynamic> _withDistance(Map<String, dynamic> item) {
    print("=== DEBUG ITEM ===");
    print("Item raw: $item");
    print(
      "User position: ${userPosition?.latitude}, ${userPosition?.longitude}",
    );

    try {
      final lat = item['latitude'];
      final lng = item['longitude'];
      print("Lat from DB: $lat  | Lng from DB: $lng");

      if (lat != null && lng != null && userPosition != null) {
        final double latD = (lat is num)
            ? lat.toDouble()
            : double.parse(lat.toString());
        final double lngD = (lng is num)
            ? lng.toDouble()
            : double.parse(lng.toString());

        print("Lat parsed: $latD | Lng parsed: $lngD");

        final meters = Geolocator.distanceBetween(
          userPosition!.latitude,
          userPosition!.longitude,
          latD,
          lngD,
        );

        print("Distance calculated: $meters meters");

        item['distance_m'] = meters;
        item['distance'] = _formatDistance(meters);
      } else {
        print("Lat/Lng null, skipping distance calc.");
        item['distance_m'] = null;
        item['distance'] = '--';
      }
    } catch (e) {
      print("ERROR distance calc: $e");
      item['distance_m'] = null;
      item['distance'] = '--';
    }

    // DEBUG rating
    print("Raw rating: ${item['rating']}");

    try {
      final r = item['rating'];
      if (r != null) {
        final numeric = (r is num) ? r.toDouble() : double.parse(r.toString());
        item['rating'] = numeric.toStringAsFixed(1);
      } else {
        item['rating'] = '0.0';
      }
    } catch (_) {
      print("Error parsing rating");
      item['rating'] = item['rating']?.toString() ?? '0.0';
    }

    print("=== END DEBUG ITEM ===\n\n");

    return item;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  // Geolocator helpers
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError = 'Location services are disabled.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError = 'Location permissions are denied';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError = 'Location permissions are permanently denied';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          userPosition = pos;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      locationError = 'Gagal mendapatkan lokasi: $e';
    }
  }

  // UI building below (kept similar to original file, but using fetched data)
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          // handle bottom nav tap if needed
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chatbot');
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTrafficCard(),
                  const SizedBox(height: 20),
                  _buildWeatherRow(context),
                  const SizedBox(height: 20),
                  _buildNearestWorkshopTitle(),
                  const SizedBox(height: 12),
                  buildWorkshopCarousel(),
                  const SizedBox(height: 20),
                  _buildNearestSpbuTitle(),
                  const SizedBox(height: 12),
                  buildSpbuCarousel(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFF8400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 100,
                height: 40,
                child: Image.asset(
                  "assets/icons/header-icon.png",
                  fit: BoxFit.contain,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            firstName.isEmpty ? "Selamat Pagi!" : "Selamat Pagi, $firstName!",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/search');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Text("Search...", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficCard() {
    // Tentukan posisi awal
    final initialPosition = userPosition != null
        ? LatLng(userPosition!.latitude, userPosition!.longitude)
        : _defaultLocation;

    final String status = currentTrafficStatus;
    final String duration = currentDuration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false, // Nonaktifkan interaksi agar map terlihat statis di card
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                trafficEnabled: true, //
                mapType: MapType.normal,

              ),
            ),
          ),
          const SizedBox(width: 15),
          // Traffic info
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Color lineColor = _getTrafficColor(status);
                final double lineWidth = _getTrafficLineWidth(
                  status,
                  constraints.maxWidth,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kondisi lalu lintas",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff3d3d3d),
                        fontSize: 20,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 3,
                      width: lineWidth,
                      color: lineColor,
                    ),
                    const Text(
                      "12.9 Kilometer", // <-- Tetap statis, perlu API untuk data real
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xff3d3d3d),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Perjalanan anda hari ini",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          // Navigasi ke halaman detail atau buka Map full-screen
                          Navigator.pushNamed(context, '/lalulintas');
                        },
                        child: const Text(
                          "Lihat selengkapnya",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWeatherRow(BuildContext context) {
    if (_isLoadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weather == null) {
      return const Text("Gagal memuat cuaca");
    }

    return Row(
      children: [
        Expanded(
          child: _weatherCard(
            percent: precipPercent ?? 0,
            subtitle: conditionText,
            title: "Presipitasi",
            icon: Icon(conditionIcon, size: 36),
            isActive: true,
            context: context,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _menuCards(context)),
      ],
    );
  }


  Widget _weatherCard({
    required int percent,
    required String title,
    required String subtitle,
    required Widget icon,
    required bool isActive,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "/weather");
      },
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        "$percent%",
                        style: const TextStyle(
                          fontSize: 35,
                          color: Color(0xff292D32),
                          fontWeight: FontWeight.bold,
                        ),
                        minFontSize: 10,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        title,
                        style: const TextStyle(fontSize: 14),
                        minFontSize: 8,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC93C), Color(0xFFFFD65C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SizedBox(width: 36, height: 36, child: icon),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 90,
                      child: AutoSizeText(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xff3d3d3d),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        minFontSize: 8,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _menuCards(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _menuCard("Log Perjalanan", "assets/icons/log.png"),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/parking');
            },
            child: _menuCard("Lokasi Parkir", "assets/icons/parkir.png"),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(String title, String iconPath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(iconPath, width: 26, height: 26),
          ),
          const SizedBox(height: 6),

          SizedBox(
            width: 60,
            child: AutoSizeText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              minFontSize: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearestWorkshopTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Bengkel terdekat",
          style: TextStyle(
            fontSize: 17,
            color: Color(0xff3d3d3d),
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/workshop');
          },
          child: const Text(
            "Lihat Semua",
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildNearestSpbuTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "SPBU terdekat",
          style: TextStyle(
            fontSize: 17,
            color: Color(0xff3d3d3d),
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/spbu-list'); // Ganti sesuai route kamu
          },
          child: const Text(
            "Lihat Semua",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkshopCard({
    required String name,
    required String distance,
    required String rating,
    required String image,
    required String status,
  }) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Image error: $exception');
                },
              ),
            ),
          ),
          // Card info
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Info kiri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff3d3d3d),
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                distance,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                rating,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: status == "Buka" ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWorkshopCarousel() {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        clipBehavior: Clip.none,
        controller: PageController(viewportFraction: 0.85),
        itemCount: workshops.length,
        itemBuilder: (context, index) {
          final item = workshops[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildWorkshopCard(
              name: item["bengkelname"] ?? 'Unnamed',
              distance: item["distance"] ?? '--',
              rating: item["rating"]?.toString() ?? '0.0',
              image: item["image"] ?? 'assets/images/workshop.png',
              status: (item["is_open"] == true) ? 'Buka' : 'Tutup',
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpbuCard({
    required String name,
    required String distance,
    required String rating,
    required String image,
    required String status,
  }) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gambar
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Image error: $exception');
                },
              ),
            ),
          ),
          // Card info
          Positioned(
            left: 16,
            right: 16,
            bottom: -12,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Info kiri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff3d3d3d),
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                distance,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                rating,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: status == "Buka" ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSpbuCarousel() {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        clipBehavior: Clip.none,
        controller: PageController(viewportFraction: 0.85),
        itemCount: spbu.length,
        itemBuilder: (context, index) {
          final item = spbu[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSpbuCard(
              name: item["name"] ?? 'Unnamed',
              distance: item["distance"] ?? '--',
              rating: item["rating"]?.toString() ?? '0.0',
              image: item["image_url"] ?? 'assets/images/spbu.png',
              status: (item["is_open"] == true) ? 'Buka' : 'Tutup',
            ),
          );
        },
      ),
    );
  }
}

// Helper functions outside the class
Color _getTrafficColor(String status) {
  switch (status.toLowerCase()) {
    case "macet":
      return Colors.red;
    case "padat":
      return Colors.orange;
    case "lancar":
    case "normal":
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

double _getTrafficLineWidth(String status, double maxWidth) {
  switch (status.toLowerCase()) {
    case "macet":
      return maxWidth;
    case "padat":
      return maxWidth * 0.75;
    case "normal":
      return maxWidth * 0.50;
    case "lancar":
      return maxWidth * 0.30;
    default:
      return maxWidth * 0.40;
  }
}
