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
  final Completer<GoogleMapController> _controller = Completer();

  double? currentLat;
  double? currentLng;
  double? bengkelLat;
  double? bengkelLng;
  String bengkelName = "Bengkel Terdekat";
  String currentAddress = "Memuat alamat...";
  String bengkelAddress = "Memuat alamat...";

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  // GET CURRENT LOCATION
  Future<void> _loadCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLat = pos.latitude;
        currentLng = pos.longitude;
        // Default bengkel: 5km ke timur dari lokasi sekarang
        bengkelLat = pos.latitude;
        bengkelLng = pos.longitude + 0.05; // ~5km ke timur
      });

      // Get addresses
      await _getAddresses();

      setState(() => loading = false);
    } catch (e) {
      print("Error getLocation: $e");
      setState(() => loading = false);
    }
  }

  // GET ALAMAT FROM COORDINATES
  Future<void> _getAddresses() async {
    try {
      final mapsApiKey = dotenv.env['MAPS_API_KEY'];
      if (mapsApiKey == null) {
        print("MAPS_API_KEY not found in .env");
        return;
      }

      // Get current address
      if (currentLat != null && currentLng != null) {
        final currentUrl =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$currentLat,$currentLng&key=$mapsApiKey";
        final currentRes = await http.get(Uri.parse(currentUrl));
        if (currentRes.statusCode == 200) {
          final data = jsonDecode(currentRes.body);
          if (data['results'].isNotEmpty) {
            setState(() {
              currentAddress = data['results'][0]['formatted_address'];
            });
          }
        }
      }

      // Get bengkel address
      if (bengkelLat != null && bengkelLng != null) {
        final bengkelUrl =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$bengkelLat,$bengkelLng&key=$mapsApiKey";
        final bengkelRes = await http.get(Uri.parse(bengkelUrl));
        if (bengkelRes.statusCode == 200) {
          final data = jsonDecode(bengkelRes.body);
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

  // OPEN IN GOOGLE MAPS
  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse("google.navigation:q=$lat,$lng&mode=d");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      final fallback = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
      );
      launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
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
          ? const Center(child: CircularProgressIndicator())
          : currentLat == null
              ? const Center(child: Text("Gagal mendapatkan lokasi"))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GOOGLE MAPS
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 300,
                            child: GoogleMap(
                              onMapCreated: (controller) {
                                if (!_controller.isCompleted) {
                                  _controller.complete(controller);
                                }
                              },
                              initialCameraPosition: CameraPosition(
                                target: LatLng(currentLat!, currentLng!),
                                zoom: 13,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              markers: {
                                // Current location marker
                                Marker(
                                  markerId: const MarkerId('current'),
                                  position: LatLng(currentLat!, currentLng!),
                                  infoWindow:
                                      const InfoWindow(title: 'Lokasi Anda'),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueBlue,
                                  ),
                                ),
                                // Bengkel marker
                                if (bengkelLat != null && bengkelLng != null)
                                  Marker(
                                    markerId: const MarkerId('bengkel'),
                                    position:
                                        LatLng(bengkelLat!, bengkelLng!),
                                    infoWindow: InfoWindow(title: bengkelName),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                  ),
                              },
                              polylines: {
                                if (bengkelLat != null && bengkelLng != null)
                                  Polyline(
                                    polylineId: const PolylineId('route'),
                                    points: [
                                      LatLng(currentLat!, currentLng!),
                                      LatLng(bengkelLat!, bengkelLng!),
                                    ],
                                    color: Colors.blue,
                                    width: 5,
                                  ),
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // HEADER
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              "Rute ke Bengkel",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // CARD INFORMASI
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lokasi Saat Ini",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.radio_button_checked,
                                      color: Colors.blue, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      currentAddress,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Tujuan Bengkel",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      bengkelAddress,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // BUTTON BUKA DI GMAPS
                        Material(
                          borderRadius: BorderRadius.circular(40),
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(40),
                            onTap: () => _openInGoogleMaps(
                              bengkelLat!,
                              bengkelLng!,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: const Color(0xffDCDCDC),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      "Buka di Google Maps",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset("assets/icons/arrow.png",
                                      height: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
