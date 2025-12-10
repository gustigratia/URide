import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrafficData {
  final String status; // Lancar, Padat, Macet Parah
  final double congestionLevel; // 0.0 - 1.0
  final String durationNormal; // waktu normal
  final String durationTraffic; // waktu dengan traffic
  final int duration; // durasi dalam detik
  final int durationInTraffic; // durasi dengan traffic
  final Color statusColor;

  TrafficData({
    required this.status,
    required this.congestionLevel,
    required this.durationNormal,
    required this.durationTraffic,
    required this.duration,
    required this.durationInTraffic,
    required this.statusColor,
  });
}

class TrafficService {
  static final String? _apiKey = dotenv.env["MAPS_API_KEY"];

  /// Format detik ke format readable (e.g., "45 menit")
  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) {
      return "${hours}j ${minutes % 60}m";
    } else if (minutes > 0) {
      return "$minutes menit";
    } else {
      return "$seconds detik";
    }
  }

  /// Tentukan warna berdasarkan level kemacetan
  static Color _getStatusColor(double congestionLevel) {
    if (congestionLevel >= 0.5) {
      return const Color(0xFFE74C3C); // Red - Macet Parah
    } else if (congestionLevel >= 0.2) {
      return const Color(0xFFF39C12); // Orange - Padat
    } else {
      return const Color(0xFF27AE60); // Green - Lancar
    }
  }

  /// Tentukan status text
  static String _getStatusText(double congestionLevel) {
    if (congestionLevel >= 0.5) {
      return "Macet Parah 🚗🚗";
    } else if (congestionLevel >= 0.2) {
      return "Padat 🚗";
    } else {
      return "Lancar ✅";
    }
  }

  /// Get traffic data dari origin ke destination
  static Future<TrafficData> getTrafficData({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('MAPS_API_KEY tidak ditemukan di .env');
      }

      final url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${origin.latitude},${origin.longitude}"
          "&destination=${destination.latitude},${destination.longitude}"
          "&departure_time=now"
          "&traffic_model=best_guess"
          "&key=$_apiKey";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Error API: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data["status"] != "OK" || data["routes"].isEmpty) {
        throw Exception('Route tidak ditemukan');
      }

      final leg = data["routes"][0]["legs"][0];
      final int duration = leg["duration"]["value"] ?? 0;
      final int durationInTraffic = leg["duration_in_traffic"]["value"] ?? duration;

      // Hitung persentase kemacetan
      final diff = durationInTraffic - duration;
      final double congestionLevel = duration > 0 ? (diff / duration) : 0.0;

      return TrafficData(
        status: _getStatusText(congestionLevel),
        congestionLevel: congestionLevel.clamp(0.0, 1.0),
        durationNormal: _formatDuration(duration),
        durationTraffic: _formatDuration(durationInTraffic),
        duration: duration,
        durationInTraffic: durationInTraffic,
        statusColor: _getStatusColor(congestionLevel),
      );
    } catch (e) {
      throw Exception('Gagal load traffic: ${e.toString()}');
    }
  }

  /// Get nearby locations dari koordinat
  static Future<List<String>> getNearbyPlaces({
    required LatLng location,
    String type = "point_of_interest",
  }) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('MAPS_API_KEY tidak ditemukan');
      }

      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
          "location=${location.latitude},${location.longitude}"
          "&radius=1000"
          "&type=$type"
          "&key=$_apiKey";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final results = data["results"] as List? ?? [];

      final places = results
          .take(5)
          .map((place) => (place["name"] ?? "Unknown").toString())
          .toList();
      
      return places;
    } catch (e) {
      return ["Error: ${e.toString()}"];
    }
  }
}
