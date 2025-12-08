import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;

  CameraPosition _initialPos = const CameraPosition(
    target: LatLng(-6.200000, 106.816666), // Jakarta
    zoom: 14,
  );

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location service disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission permanently denied");
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _initialPos = CameraPosition(target: currentLatLng, zoom: 16);

      markers = {
        Marker(
          markerId: const MarkerId("current_location"),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      };
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map View")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // MAP FRAME
          Center(
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 400,
                  child: GoogleMap(
                    initialCameraPosition: _initialPos,
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    markers: markers,
                    myLocationEnabled: true,
                    zoomGesturesEnabled: true,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // BUTTON REFRESH POSITION
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _getCurrentLocation();
            },
            child: const Text(
              "Get Current Location",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
