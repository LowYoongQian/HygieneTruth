import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_env.dart';

class GpsService {
  static String? lastKnownCity;
  static String? lastKnownCountry;
  static String lastLocationSource = 'Default';

  /// Query real network / router IP geolocation
  static Future<Position?> getLocationFromIp() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      // Provider 1: ip-api.com (high speed & accuracy)
      try {
        final request = await client.getUrl(Uri.parse('http://ip-api.com/json'));
        final response = await request.close().timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          if (data['status'] == 'success' && data['lat'] != null && data['lon'] != null) {
            final lat = (data['lat'] as num).toDouble();
            final lon = (data['lon'] as num).toDouble();
            lastKnownCity = data['city']?.toString();
            lastKnownCountry = data['country']?.toString();
            lastLocationSource = 'Router IP (${data['city'] ?? 'Network'})';
            debugPrint('GPS Service: Retrieved exact location from IP: $lat, $lon ($lastKnownCity, $lastKnownCountry)');
            return Position(
              latitude: lat,
              longitude: lon,
              timestamp: DateTime.now(),
              accuracy: 50.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
            );
          }
        }
      } catch (e) {
        debugPrint('GPS Service IP provider 1 failed: $e');
      }

      // Provider 2: ipapi.co (backup)
      try {
        final request = await client.getUrl(Uri.parse('https://ipapi.co/json/'));
        final response = await request.close().timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          if (data['latitude'] != null && data['longitude'] != null) {
            final lat = (data['latitude'] as num).toDouble();
            final lon = (data['longitude'] as num).toDouble();
            lastKnownCity = data['city']?.toString();
            lastKnownCountry = data['country_name']?.toString();
            lastLocationSource = 'Router IP (${data['city'] ?? 'Network'})';
            debugPrint('GPS Service: Retrieved exact location from backup IP provider: $lat, $lon');
            return Position(
              latitude: lat,
              longitude: lon,
              timestamp: DateTime.now(),
              accuracy: 50.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
            );
          }
        }
      } catch (e) {
        debugPrint('GPS Service IP provider 2 failed: $e');
      }
    } catch (e) {
      debugPrint('GPS Service: Exception querying IP geolocation: $e');
    }
    return null;
  }

  /// Check GPS permissions and retrieve exact current device/network position
  static Future<Position?> getCurrentLocation({bool forceIp = false}) async {
    if (forceIp) {
      final ipPos = await getLocationFromIp();
      if (ipPos != null) return ipPos;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS Service Warning: Location services are disabled. Falling back to Router IP.');
        final ipPos = await getLocationFromIp();
        return ipPos ?? _getFallbackPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('GPS Service Warning: Location permissions are denied. Falling back to Router IP.');
          final ipPos = await getLocationFromIp();
          return ipPos ?? _getFallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('GPS Service Warning: Location permissions permanently denied. Falling back to Router IP.');
        final ipPos = await getLocationFromIp();
        return ipPos ?? _getFallbackPosition();
      }

      final devicePos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      // Check if Android emulator default location (Mountain View, California: ~37.422, -122.084)
      final bool isEmulatorDefault = (devicePos.latitude - 37.422).abs() < 0.05 &&
          (devicePos.longitude - (-122.084)).abs() < 0.05;

      if (isEmulatorDefault) {
        debugPrint('GPS Service: Detected Android Emulator default coordinates. Fetching exact location via router IP...');
        final ipPos = await getLocationFromIp();
        if (ipPos != null) {
          return ipPos;
        }
      }

      lastLocationSource = 'Device GPS';
      return devicePos;
    } catch (e) {
      debugPrint('GPS Service Exception: $e. Falling back to Router IP.');
      final ipPos = await getLocationFromIp();
      return ipPos ?? _getFallbackPosition();
    }
  }

  /// Calculates distance in meters between two coordinates
  static double calculateDistanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculates distance string formatted in KM or meters
  static String formatDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final meters = calculateDistanceMeters(startLat, startLng, endLat, endLng);
    if (meters < 1000) {
      return '${meters.round()} m away';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  /// Auto-check if complaint location matches restaurant location within threshold
  static bool verifyLocationMatch(
    double complaintLat,
    double complaintLng,
    double restaurantLat,
    double restaurantLng, {
    double thresholdMeters = 150.0,
  }) {
    final distance = calculateDistanceMeters(complaintLat, complaintLng, restaurantLat, restaurantLng);
    return distance <= thresholdMeters;
  }

  /// Fallback position using environment defaults if GPS and IP are unavailable
  static Position _getFallbackPosition() {
    lastLocationSource = 'Default';
    return Position(
      latitude: AppEnv.defaultLatitude,
      longitude: AppEnv.defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
}
