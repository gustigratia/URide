import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uride/routes/app_routes.dart';

class AjukanLayananScreen extends StatefulWidget {
  final int workshopId;
  final String workshopName;
  final String workshopAddress;
  final int price;

  const AjukanLayananScreen({
    Key? key,
    required this.workshopId,
    required this.workshopName,
    required this.workshopAddress,
    required this.price,
  }) : super(key: key);

  @override
  State<AjukanLayananScreen> createState() => _AjukanLayananScreenState();
}

class _AjukanLayananScreenState extends State<AjukanLayananScreen> {
  final MapController mapController = MapController();
  LatLng? currentLocation;
  bool isLoading = true;
  StreamSubscription<Position>? positionStream;

  String selectedVehicle = 'sepeda';
  String selectedType = 'normal';
  final TextEditingController addressController = TextEditingController();
  final bool isOnLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentLocation != null) {
          mapController.move(currentLocation!, 16);
        }
      });

      positionStream = Geolocator.getPositionStream().listen((pos) {
        final newPos = LatLng(pos.latitude, pos.longitude);

        setState(() {
          currentLocation = newPos;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            mapController.move(newPos, mapController.camera.zoom);
          }
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPinToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentLocation != null) {
          mapController.move(currentLocation!, 16);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajukan Layanan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Map Section
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 200,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : currentLocation == null
                        ? const Center(child: Text('Lokasi tidak tersedia'))
                        : Stack(
                            children: [
                              FlutterMap(
                                mapController: mapController,
                                options: MapOptions(
                                  initialCenter: currentLocation!,
                                  initialZoom: 16,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                    userAgentPackageName: "com.example.uride",
                                  ),
                                ],
                              ),
                              Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: FloatingActionButton(
                                  mini: true,
                                  onPressed: _setPinToCurrentLocation,
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            // Detail Alamat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Detail Alamat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan detail lokasi Anda...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Kendaraan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Jenis Kendaraan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVehicleOption(icon: Icons.pedal_bike, label: 'Sepeda', value: 'sepeda'),
                  const SizedBox(height: 8),
                  _buildVehicleOption(icon: Icons.two_wheeler, label: 'Motor', value: 'motor'),
                  const SizedBox(height: 8),
                  _buildVehicleOption(icon: Icons.directions_car, label: 'Mobil', value: 'mobil'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Jenis Ajuan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Ajuan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequestType(color: Colors.red, label: 'Emergency', value: 'emergency'),
                  const SizedBox(height: 8),
                  _buildRequestType(color: Colors.amber, label: 'Normal', value: 'normal'),
                  const SizedBox(height: 8),
                  _buildRequestType(color: Colors.green, label: 'Santai', value: 'santai'),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      bottomSheet: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitLayanan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: const Text(
            'Ajukan Layanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),

    );
  }

  Widget _buildVehicleOption({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = selectedVehicle == value;
    return InkWell(
      onTap: () => setState(() => selectedVehicle = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber),
            const SizedBox(width: 12),
            Text(label),
            const Spacer(),
            isSelected
                ? const Icon(Icons.check_circle, color: Colors.amber)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestType({
    required Color color,
    required String label,
    required String value,
  }) {
    final isSelected = selectedType == value;
    return InkWell(
      onTap: () => setState(() => selectedType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(label),
            const Spacer(),
            isSelected
                ? const Icon(Icons.check_circle, color: Colors.amber)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _submitLayanan() {
    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi detail alamat'), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.konfirmasiAjuan,
      arguments: {
        'workshopId': widget.workshopId,
        'workshopName': widget.workshopName,
        'workshopAddress': widget.workshopAddress,
        'vehicleType': selectedVehicle,
        'requestType': selectedType,
        'isOnLocation': isOnLocation,
        'userAddress': addressController.text,
        'price': widget.price,
      },
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    positionStream?.cancel();
    super.dispose();
  }
}
