import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class LaluLintasPage extends StatefulWidget {
  const LaluLintasPage({super.key});

  @override
  State<LaluLintasPage> createState() => _LaluLintasPageState();
}

class _LaluLintasPageState extends State<LaluLintasPage> {
  final Completer<GoogleMapController> _mapController = Completer();

  double? currentLat;
  double? currentLng;
  String currentAddress = "Memuat alamat...";
  String trafficStatus = "Memeriksa...";
  String trafficDuration = "--";
  Color trafficColor = Colors.orange;

  bool loading = true;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  // INITIALIZE MAP & LOCATION
  Future<void> _initializeMap() async {
    try {
      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLat = pos.latitude;
        currentLng = pos.longitude;
      });

      // Get address & traffic status
      await Future.wait([
        _getAddress(),
        _fetchTrafficStatus(),
      ]);

      setState(() => loading = false);
    } catch (e) {
      print("Error initialize: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      setState(() => loading = false);
    }
  }

  // GET ADDRESS VIA REVERSE GEOCODING
  Future<void> _getAddress() async {
    try {
      final mapsApiKey = dotenv.env['MAPS_API_KEY'];
      if (mapsApiKey == null) {
        print("MAPS_API_KEY not found");
        return;
      }

      if (currentLat != null && currentLng != null) {
        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$currentLat,$currentLng&key=$mapsApiKey";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['results'].isNotEmpty) {
            setState(() {
              currentAddress = data['results'][0]['formatted_address'];
              // Create marker for current location
              markers = {
                Marker(
                  markerId: const MarkerId('current'),
                  position: LatLng(currentLat!, currentLng!),
                  infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
              };
            });
          }
        }
      }
    } catch (e) {
      print("Error getAddress: $e");
    }
  }

  // FETCH REAL-TIME TRAFFIC STATUS (RADIUS 5KM)
  Future<void> _fetchTrafficStatus() async {
    try {
      if (currentLat == null || currentLng == null) {
        setState(() {
          trafficStatus = "Lokasi tidak tersedia";
        });
        return;
      }

      final mapsApiKey = dotenv.env['MAPS_API_KEY'];
      if (mapsApiKey == null || mapsApiKey.isEmpty) {
        setState(() {
          trafficStatus = "Kunci API Hilang";
        });
        return;
      }

      LatLng userLatLng = LatLng(currentLat!, currentLng!);
      final LatLng origin = LatLng(currentLat!, currentLng!);

      // Generate random bearing (0-360 degrees)
      final randomBearing = Random().nextInt(360).toDouble();
      // 1km offset untuk traffic check
      LatLng destination = _offsetPosition(userLatLng, 1000, randomBearing);

      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$mapsApiKey'
          '&departure_time=now';

      print("🚗 Traffic API Call:");
      print("   Origin: ${origin.latitude}, ${origin.longitude}");
      print("   Destination: ${destination.latitude}, ${destination.longitude}");
      print("   URL: $url");

      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15))
          .catchError((error) {
        print("❌ Network Error: $error");
        throw error;
      });

      print("📡 Traffic Response Code: ${response.statusCode}");
      print("📡 Response Body: ${response.body.substring(0, 200)}...");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for API errors in response
        if (data['status'] != 'OK') {
          print("❌ API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}");
          setState(() {
            trafficStatus = "API Error: ${data['status']}";
            trafficColor = Colors.grey;
          });
          return;
        }

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final String durationText = leg['duration']['text'] ?? 'N/A';
          final int durationSeconds = leg['duration']['value'] ?? 0;

          String status = "Lancar";
          String duration = durationText;

          if (leg['duration_in_traffic'] != null) {
            final int trafficDurationSeconds =
                leg['duration_in_traffic']['value'] ?? durationSeconds;
            duration = leg['duration_in_traffic']['text'] ?? durationText;

            // Logika untuk menentukan status
            final double ratio =
                durationSeconds > 0 ? trafficDurationSeconds / durationSeconds : 1.0;

            print("📊 DEBUG ratio: $ratio");
            print("📊 DEBUG duration: $durationSeconds | traffic: $trafficDurationSeconds");

            if (ratio >= 1.5) {
              status = "Macet";
            } else if (ratio >= 1.2) {
              status = "Padat";
            } else {
              status = "Lancar";
            }
          }

          // Update UI
          if (mounted) {
            setState(() {
              trafficStatus = status;
              trafficDuration = duration;

              // Set color based on status
              if (status == "Macet") {
                trafficColor = Colors.red;
              } else if (status == "Padat") {
                trafficColor = Colors.amber;
              } else {
                trafficColor = Colors.green;
              }
            });
            print("✅ Traffic Status Updated: $status - $duration");
          }
        } else {
          setState(() {
            trafficStatus = "Rute tidak ditemukan";
            trafficColor = Colors.grey;
          });
          print("❌ No routes found in response");
        }
      } else {
        print('❌ Failed to load traffic data: ${response.statusCode}');
        print('Response: ${response.body}');
        setState(() {
          trafficStatus = "Error ${response.statusCode}";
          trafficColor = Colors.grey;
        });
      }
    } on TimeoutException {
      print('⏱️ Traffic API TIMEOUT after 15s');
      setState(() {
        trafficStatus = "Timeout";
        trafficColor = Colors.grey;
      });
    } catch (e) {
      print('❌ Traffic API Error: $e');
      print('Error Type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          trafficStatus = "Error jaringan";
          trafficColor = Colors.grey;
        });
      }
    }
  }

  // OFFSET POSITION USING BEARING & DISTANCE
  LatLng _offsetPosition(LatLng origin, double distanceMeters, double bearingDegrees) {
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

  // OPEN GOOGLE MAPS (USER SEARCH SENDIRI)
  Future<void> _openGoogleMaps() async {
    final url = Uri.parse("https://www.google.com/maps");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lalu Lintas",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // GOOGLE MAPS - LOKASI SAAT INI DENGAN TRAFFIC
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        if (!_mapController.isCompleted) {
                          _mapController.complete(controller);
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(currentLat ?? 0, currentLng ?? 0),
                        zoom: 13,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      trafficEnabled: true,
                      markers: markers,
                    ),
                  ),

                  // CONTENT BELOW MAP
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TRAFFIC STATUS CARD - PREMIUM DESIGN
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                trafficColor.withOpacity(0.1),
                                trafficColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: trafficColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: trafficColor.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: trafficColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: trafficColor.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Kondisi Lalu Lintas",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                trafficStatus,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: trafficColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: trafficColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Radius 1km ke semua arah",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: trafficColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // LOCATION INFO SECTION
                        const Text(
                          "Lokasi Anda",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // LOCATION CARD
                        _buildPremiumLocationCard(
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFF2196F3),
                          address: currentAddress,
                        ),

                        const SizedBox(height: 28),

                        // ACTION BUTTONS
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Navigasi Cepat",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openGoogleMaps,
                                  icon: const Icon(Icons.map_rounded),
                                  label: const Text(
                                    "Buka Google Maps",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9800),
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // PREMIUM LOCATION CARD
  Widget _buildPremiumLocationCard({
    required IconData icon,
    required Color color,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Alamat Saat Ini",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
