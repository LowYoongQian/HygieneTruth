import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_env.dart';

class GpsService {
  /// Check GPS permissions and retrieve current device position
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS Service Warning: Location services are disabled.');
        return _getFallbackPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('GPS Service Warning: Location permissions are denied.');
          return _getFallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('GPS Service Warning: Location permissions are permanently denied.');
        return _getFallbackPosition();
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('GPS Service Exception: $e');
      return _getFallbackPosition();
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

  /// Fallback position using environment defaults if GPS is unavailable
  static Position _getFallbackPosition() {
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
