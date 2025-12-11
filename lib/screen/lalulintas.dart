import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';

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

      final LatLng origin = LatLng(currentLat!, currentLng!);
      
      // Destinasi: 4 titik di sekitar radius 5km (utama: N, E, S, W)
      // 1 degree ≈ 111 km, jadi 5km ≈ 0.045 degree
      final List<LatLng> destinations = [
        // Utara
        LatLng(currentLat! + 0.045, currentLng!),
        // Timur
        LatLng(currentLat!, currentLng! + 0.045),
        // Selatan
        LatLng(currentLat! - 0.045, currentLng!),
        // Barat
        LatLng(currentLat!, currentLng! - 0.045),
      ];

      // Hitung rata-rata traffic dari semua arah
      int totalSeconds = 0;
      int totalTrafficSeconds = 0;
      int successCount = 0;

      print("🚗 Starting traffic check from ${origin.latitude}, ${origin.longitude}");

      for (int i = 0; i < destinations.length; i++) {
        final destination = destinations[i];
        
        final String url =
            'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&key=$mapsApiKey'
            '&departure_time=now';

        try {
          final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

          print("Direction $i Response Code: ${response.statusCode}");

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            if (data['routes'] != null && data['routes'].isNotEmpty) {
              final route = data['routes'][0];
              final leg = route['legs'][0];

              final int durationSeconds = leg['duration']['value'] ?? 0;
              final int trafficDurationSeconds = 
                  leg['duration_in_traffic']['value'] ?? durationSeconds;

              print("Direction $i - Normal: ${durationSeconds}s, Traffic: ${trafficDurationSeconds}s");

              totalSeconds += durationSeconds;
              totalTrafficSeconds += trafficDurationSeconds;
              successCount++;
            } else {
              print("Direction $i - No routes found");
            }
          } else {
            print('Direction $i Failed: ${response.statusCode}');
          }
        } on TimeoutException {
          print('Direction $i - TIMEOUT');
          continue;
        } catch (e) {
          print('Error checking direction $i: $e');
          continue;
        }
      }

      print("✅ Success Count: $successCount, Total Normal: $totalSeconds, Total Traffic: $totalTrafficSeconds");

      if (successCount > 0) {
        final double avgDuration = totalSeconds / successCount;
        final double avgTraffic = totalTrafficSeconds / successCount;
        final double ratio = avgDuration > 0 ? avgTraffic / avgDuration : 1.0;

        String status = "Lancar";
        Color color = Colors.green;

        print("📊 Ratio: $ratio (avg normal: ${avgDuration}s, avg traffic: ${avgTraffic}s)");

        if (ratio >= 1.5) {
          status = "Macet";
          color = Colors.red;
        } else if (ratio >= 1.2) {
          status = "Padat";
          color = Colors.amber;
        } else {
          status = "Lancar";
          color = Colors.green;
        }

        if (mounted) {
          setState(() {
            trafficStatus = status;
            trafficColor = color;
          });
          print("✅ Traffic Status Updated: $status");
        }
      } else {
        setState(() {
          trafficStatus = "Tidak ada data";
          trafficColor = Colors.grey;
        });
        print("❌ No successful API calls");
      }
    } catch (e) {
      print('Traffic API Error: $e');
      if (mounted) {
        setState(() {
          trafficStatus = "Error jaringan";
          trafficColor = Colors.grey;
        });
      }
    }
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
                                "Radius 5km ke semua arah (bundar)",
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
