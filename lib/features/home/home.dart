import 'package:flutter/material.dart';
import 'package:uride/core/widgets/bottom_nav.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uride/routes/app_routes.dart';
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
  String? currentAddress;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    mapsApiKey = dotenv.env['MAPS_API_KEY'] ?? '';

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

      final w = List<Map<String, dynamic>>.from(workshopData);
      final s = List<Map<String, dynamic>>.from(spbuData);

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

      setState(() {
        _weather = Map<String, dynamic>.from(json);
        _isLoadingWeather = false;
      });
    } catch (e) {
      print("Weather error: $e");
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Tidak bisa membuka Google Maps';
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

  Future<String> _reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (data["status"] == "OK") {
      final components = data["results"][0]["address_components"] as List;

      String? city;
      String? province;

      for (final c in components) {
        final types = List<String>.from(c["types"]);

        if (types.contains("administrative_area_level_2") ||
            types.contains("locality")) {
          city = c["long_name"];
        }

        if (types.contains("administrative_area_level_1")) {
          province = c["long_name"];
        }
      }

      if (city != null && province != null) {
        return "$city, $province";
      } else if (province != null) {
        return province;
      }
    }

    return "Lokasi tidak diketahui";
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
      if (!mounted) return;

      final address = await _reverseGeocode(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        userPosition = pos;
        currentAddress = address;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      locationError = 'Gagal mendapatkan lokasi: $e';
    }
  }

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
                  _buildSectionTitle(title: "Bengkel Terdekat", routeName: '/workshop'),
                  const SizedBox(height: 12),
                  buildWorkshopCarousel(),
                  const SizedBox(height: 20),
                  _buildSectionTitle(title: "SPBU Terdekat", routeName: '/spbu-list'),
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
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                trafficEnabled: true,
                mapType: MapType.normal,

              ),
            ),
          ),
          const SizedBox(width: 15),
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
                    Text(
                      currentAddress ?? "Menentukan lokasi...",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xff3d3d3d),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Lokasi anda saat ini",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _weatherCard(
            percent: precipPercent ?? 0,
            subtitle: conditionText,
            title: "Presipitasi",
            icon: Icon(
              conditionIcon,
              size: 30,
              color: Colors.white,
            ),
            isActive: true,
            context: context,
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _menuCards(context),
        ),
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
        padding: const EdgeInsets.all(20),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  fit: FlexFit.loose,
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
                        minFontSize: 5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        title,
                        style: const TextStyle(fontSize: 14),
                        minFontSize: 5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                Column(
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
                      width: 80,
                      child: AutoSizeText(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xff3d3d3d),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        minFontSize: 10,
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
      height: 140,
      padding: const EdgeInsets.all(8),
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
      child: _menuCard(
        "Lokasi Parkir",
        "assets/icons/parkir.png",
        onTap: () {
          Navigator.pushNamed(context, '/parking');
        },
      ),
    );
  }

  Widget _menuCard(String title, String iconPath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 200;

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 0),

            child: isWide
                ? _buildHorizontalLayout(title, iconPath)
                : _buildVerticalLayout(title, iconPath),
          );
        },
      ),
    );
  }

  Widget _buildVerticalLayout(String title, String iconPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: FractionallySizedBox(
            heightFactor: 0.6,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(iconPath, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 1,
          child: Center(
            child: AutoSizeText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Color(0xff292D32),
              ),
              maxLines: 2,
              minFontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(String title, String iconPath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(iconPath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AutoSizeText(
            title,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff292D32),
            ),
            maxLines: 2,
            minFontSize: 10,
          ),
        ),
      ],
    );
  }




  Widget _buildSectionTitle({
    required String title,
    required String routeName,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xff3d3d3d),
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, routeName);
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
    required int workshopId,
    required String name,
    required String distance,
    required String rating,
    required String image,
    required String status,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.workshopDetail,
          arguments: {'workshopId': workshopId},
        );
      },
      child: SizedBox(
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
              status: getStatus(
                item["open_time"],
                item["close_time"],
              ),
              workshopId: item["id"],
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
    required double latitude,
    required double longitude,
  }) {
    return GestureDetector(
      onTap: () {
        openGoogleMaps(latitude, longitude);
      },
      child: SizedBox(
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
              status: getStatus(
                item["open_time"],
                item["close_time"],
              ),
              latitude: item["latitude"],
              longitude: item["longitude"],
            ),
          );
        },
      ),
    );
  }
}

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

String getStatus(String? openTime, String? closeTime) {
  print('=== getStatus CALLED ===');
  print('openTime  : $openTime');
  print('closeTime : $closeTime');

  if (openTime == null || closeTime == null) {
    print('❌ openTime / closeTime NULL → Tutup');
    return 'Tutup';
  }

  try {
    final now = DateTime.now();
    print('⏰ now      : $now');

    DateTime parseTime(String time) {
      final parts = time.split(':');
      print('Parsing time "$time" → $parts');

      final parsed = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );

      print('Parsed DateTime: $parsed');
      return parsed;
    }

    final open = parseTime(openTime);
    final close = parseTime(closeTime);

    print('🟢 open  : $open');
    print('🔴 close : $close');

    if (close.isAfter(open)) {
      print('📌 Normal hours detected');

      final isOpen = now.isAfter(open) && now.isBefore(close);
      print('isOpen (normal) = $isOpen');

      return isOpen ? 'Buka' : 'Tutup';
    }

    print('🌙 Overnight hours detected');

    final isOpen = now.isAfter(open) || now.isBefore(close);
    print('isOpen (overnight) = $isOpen');

    return isOpen ? 'Buka' : 'Tutup';
  } catch (e, stack) {
    print('🔥 ERROR in getStatus');
    print(e);
    print(stack);
    return 'Tutup';
  }
}

