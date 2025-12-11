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
      backgroundColor: const Color(0xFFF6F6F6),
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
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // GOOGLE MAPS - LOKASI SAAT INI DENGAN TRAFFIC
                  SizedBox(
                    height: 350,
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
                      trafficEnabled: true, // ✅ TRAFFIC ENABLED
                      markers: markers,
                    ),
                  ),

                  // CONTENT BELOW MAP
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TRAFFIC STATUS CARD
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Kondisi Lalu Lintas",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: trafficColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    trafficStatus,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: trafficColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Radius 1km ke semua arah (bundar)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // LOCATION INFO
                        const Text(
                          "Lokasi Saat Ini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // CURRENT LOCATION CARD
                        _buildLocationCard(
                          icon: Icons.radio_button_checked,
                          color: Colors.blue,
                          title: "Alamat Anda",
                          address: currentAddress,
                        ),

                        const SizedBox(height: 20),

                        // OPEN GOOGLE MAPS BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.directions),
                            label: const Text(
                              "Buka Google Maps",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // HELPER: BUILD LOCATION CARD
  Widget _buildLocationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
