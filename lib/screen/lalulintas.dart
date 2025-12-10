import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:uride/services/traffic_service.dart';

class LaluLintasPage extends StatefulWidget {
  const LaluLintasPage({super.key});

  @override
  State<LaluLintasPage> createState() => _LaluLintasPageState();
}

class _LaluLintasPageState extends State<LaluLintasPage> {
  GoogleMapController? mapController;
  LatLng? userLocation;
  LatLng? destinationLocation;

  TrafficData? trafficData;
  String errorMessage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      Location location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }

      if (permission == PermissionStatus.deniedForever) {
        setState(() {
          errorMessage = 'Izin lokasi ditolak permanen';
          isLoading = false;
        });
        return;
      }

      final loc = await location.getLocation();
      setState(() {
        userLocation = LatLng(loc.latitude ?? -7.913521, loc.longitude ?? 113.8213);
        // Default destination: pusat kota (misalnya)
        destinationLocation = const LatLng(-7.9072, 113.8130);
      });

      // Load traffic data setelah lokasi didapat
      _loadTrafficData();

      // Refresh traffic setiap 10 detik
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _loadTrafficData();
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTrafficData() async {
    if (userLocation == null || destinationLocation == null) return;

    try {
      final data = await TrafficService.getTrafficData(
        origin: userLocation!,
        destination: destinationLocation!,
      );

      setState(() {
        trafficData = data;
        errorMessage = '';
        isLoading = false;
      });

      // Refresh lagi setelah 10 detik
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _loadTrafficData();
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal load traffic: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lalu Lintas Real-Time",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === GOOGLE MAPS DENGAN REAL-TIME TRAFFIC ===
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 280,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: userLocation!,
                          zoom: 13,
                        ),
                        trafficEnabled: true, // REAL-TIME TRAFFIC LAYER
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: true,
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                        markers: {
                          // Marker lokasi user
                          Marker(
                            markerId: const MarkerId('user'),
                            position: userLocation!,
                            infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue,
                            ),
                          ),
                          // Marker destination
                          if (destinationLocation != null)
                            Marker(
                              markerId: const MarkerId('destination'),
                              position: destinationLocation!,
                              infoWindow: const InfoWindow(title: 'Tujuan'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                        },
                        polylines: {
                          if (destinationLocation != null)
                            Polyline(
                              polylineId: const PolylineId('route'),
                              points: [userLocation!, destinationLocation!],
                              color: Colors.blue,
                              width: 5,
                            ),
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // === STATUS TRAFFIC ===
                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (trafficData != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Kondisi Lalu Lintas",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  trafficData!.status,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: trafficData!.statusColor,
                                  ),
                                ),
                              ],
                            ),
                            // Status Icon Circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: trafficData!.statusColor.withOpacity(0.1),
                                border: Border.all(
                                  color: trafficData!.statusColor,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "${(trafficData!.congestionLevel * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: trafficData!.statusColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: trafficData!.congestionLevel,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              trafficData!.statusColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Durasi Perjalanan
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Waktu Tempuh Normal",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    trafficData!.durationNormal,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey.shade300,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Waktu Sekarang",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    trafficData!.durationTraffic,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: trafficData!.statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tips
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  trafficData!.congestionLevel >= 0.5
                                      ? "⚠️ Pertimbangkan rute alternatif untuk menghindari kemacetan"
                                      : trafficData!.congestionLevel >= 0.2
                                          ? "💡 Lalu lintas padat, beri waktu lebih untuk perjalanan"
                                          : "✅ Kondisi lalu lintas lancar, waktu perjalanan normal",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Last Updated
                        Center(
                          child: Text(
                            "🔄 Update otomatis setiap 10 detik",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
