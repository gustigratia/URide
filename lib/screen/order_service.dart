import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uride/routes/app_routes.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  GoogleMapController? mapController;
  LatLng? currentLocation;
  bool isLoading = true;
  StreamSubscription<Position>? positionStream;

  String selectedVehicle = 'motor';
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
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
        isLoading = false;
      });

      positionStream = Geolocator.getPositionStream().listen((pos) {
        final newPos = LatLng(pos.latitude, pos.longitude);
        setState(() => currentLocation = newPos);
        mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['MAPS_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("MAPS_API_KEY kosong dari .env");
      return "Alamat tidak ditemukan";
    }

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey",
    );

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);

        if (jsonData["status"] == "OK" &&
            jsonData["results"] != null &&
            jsonData["results"].isNotEmpty) {
          return jsonData["results"][0]["formatted_address"];
        }
      }
    } catch (e) {
      print("reverseGeocode error: $e");
    }

    return "Alamat tidak ditemukan";
  }



  void _setPinToCurrentLocation() {
    if (currentLocation != null) {
      mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation!));
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
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: currentLocation!,
                                  zoom: 16,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                onMapCreated: (controller) => mapController = controller,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('userLocation'),
                                    position: currentLocation!,
                                  ),
                                },
                              ),
                              // Center(
                              //   child: Icon(
                              //     Icons.location_on,
                              //     color: Colors.red,
                              //     size: 50,
                              //   ),
                              // ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: FloatingActionButton(
                                  mini: true,
                                    onPressed: () async {
                                      _setPinToCurrentLocation();

                                      if (currentLocation != null) {
                                        final address = await reverseGeocode(
                                          currentLocation!.latitude,
                                          currentLocation!.longitude,
                                        );

                                        setState(() {
                                          addressController.text = address;
                                        });
                                      }
                                    },
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
                        borderSide: BorderSide(color: Colors.grey[300]!),
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
