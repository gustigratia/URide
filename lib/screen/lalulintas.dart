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
  double? bengkelLat;
  double? bengkelLng;
  String currentAddress = "Memuat alamat...";
  String bengkelAddress = "Memuat alamat...";
  String trafficCondition = "Memeriksa...";
  Color trafficColor = Colors.orange;

  bool loading = true;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

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
        // Bengkel terdekat: 5km ke arah timur laut (default)
        bengkelLat = pos.latitude + 0.025;
        bengkelLng = pos.longitude + 0.035;
      });

      // Get addresses & traffic
      await Future.wait([
        _getAddresses(),
        _getTrafficCondition(),
        _createRoute(),
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

  // GET ADDRESSES VIA REVERSE GEOCODING
  Future<void> _getAddresses() async {
    try {
      final mapsApiKey = dotenv.env['MAPS_API_KEY'];
      if (mapsApiKey == null) {
        print("MAPS_API_KEY not found");
        return;
      }

      // Current address
      if (currentLat != null && currentLng != null) {
        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$currentLat,$currentLng&key=$mapsApiKey";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['results'].isNotEmpty) {
            setState(() {
              currentAddress = data['results'][0]['formatted_address'];
            });
          }
        }
      }

      // Bengkel address
      if (bengkelLat != null && bengkelLng != null) {
        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$bengkelLat,$bengkelLng&key=$mapsApiKey";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['results'].isNotEmpty) {
            setState(() {
              bengkelAddress = data['results'][0]['formatted_address'];
            });
          }
        }
      }
    } catch (e) {
      print("Error getAddresses: $e");
    }
  }

  // GET TRAFFIC CONDITION
  Future<void> _getTrafficCondition() async {
    try {
      final mapsApiKey = dotenv.env['MAPS_API_KEY'];
      if (mapsApiKey == null) return;

      if (currentLat == null || currentLng == null) return;

      final url =
          "https://maps.googleapis.com/maps/api/distancematrix/json?"
          "origins=$currentLat,$currentLng&destinations=$bengkelLat,$bengkelLng"
          "&departure_time=now&traffic_model=best_guess&key=$mapsApiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['rows'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];
          final duration = element['duration_in_traffic']['value'] ?? 0;
          final normalDuration = element['duration']['value'] ?? 0;

          // Calculate traffic condition
          final ratio = normalDuration > 0 ? duration / normalDuration : 1.0;

          String condition = "Lancar";
          Color color = Colors.green;

          if (ratio > 2.0) {
            condition = "Sangat Macet";
            color = Colors.red;
          } else if (ratio > 1.5) {
            condition = "Macet";
            color = Colors.orange;
          } else if (ratio > 1.2) {
            condition = "Ramai";
            color = Colors.amber;
          }

          setState(() {
            trafficCondition = condition;
            trafficColor = color;
          });
        }
      }
    } catch (e) {
      print("Error traffic: $e");
    }
  }

  // CREATE ROUTE WITH POLYLINE
  Future<void> _createRoute() async {
    try {
      final mapsApiKey = dotenv.env['MAPS_API_KEY'];
      if (mapsApiKey == null) return;

      if (currentLat == null || currentLng == null) return;

      final url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=$currentLat,$currentLng&destination=$bengkelLat,$bengkelLng"
          "&key=$mapsApiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];

          // Decode polyline
          final points = _decodePolyline(polylinePoints);

          setState(() {
            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            };

            // Create markers
            markers = {
              Marker(
                markerId: const MarkerId('current'),
                position: LatLng(currentLat!, currentLng!),
                infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
              Marker(
                markerId: const MarkerId('bengkel'),
                position: LatLng(bengkelLat!, bengkelLng!),
                infoWindow: const InfoWindow(title: 'Bengkel Terdekat'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            };
          });
        }
      }
    } catch (e) {
      print("Error createRoute: $e");
    }
  }

  // DECODE POLYLINE FROM DIRECTIONS API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng((lat / 1e5).toDouble(), (lng / 1e5).toDouble()));
    }
    return poly;
  }

  // OPEN GOOGLE MAPS NAVIGATION
  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      "google.navigation:q=$bengkelLat,$bengkelLng&mode=d",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      final fallback = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$bengkelLat,$bengkelLng",
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
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
                  // GOOGLE MAPS WITH TRAFFIC
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
                      polylines: polylines,
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
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: trafficColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Kondisi Lalu Lintas",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    trafficCondition,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: trafficColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // LOCATION INFO
                        const Text(
                          "Informasi Rute",
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
                          title: "Lokasi Saat Ini",
                          address: currentAddress,
                        ),

                        const SizedBox(height: 12),

                        // BENGKEL LOCATION CARD
                        _buildLocationCard(
                          icon: Icons.location_on,
                          color: Colors.red,
                          title: "Bengkel Terdekat",
                          address: bengkelAddress,
                        ),

                        const SizedBox(height: 20),

                        // OPEN GOOGLE MAPS BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.directions),
                            label: const Text(
                              "Buka di Google Maps",
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
