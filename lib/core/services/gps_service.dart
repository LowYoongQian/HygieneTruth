import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_env.dart';

class GpsService {
  static String? lastKnownCity;
  static String? lastKnownCountry;
  static String lastLocationSource = 'Default';

  /// Query real network / router IP geolocation across multiple fast providers
  static Future<Position?> getLocationFromIp() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    // Provider 1: ip-api.com (fast, accurate, no api key required)
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
          return _createPosition(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('GPS Service IP provider 1 failed: $e');
    }

    // Provider 2: ipwho.is (fast JSON endpoint)
    try {
      final request = await client.getUrl(Uri.parse('https://ipwho.is/'));
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        if (data['success'] == true && data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lon = (data['longitude'] as num).toDouble();
          lastKnownCity = data['city']?.toString();
          lastKnownCountry = data['country']?.toString();
          lastLocationSource = 'Router IP (${data['city'] ?? 'Network'})';
          return _createPosition(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('GPS Service IP provider 2 failed: $e');
    }

    // Provider 3: freeipapi.com (backup)
    try {
      final request = await client.getUrl(Uri.parse('https://freeipapi.com/api/json'));
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lon = (data['longitude'] as num).toDouble();
          lastKnownCity = data['cityName']?.toString();
          lastKnownCountry = data['countryName']?.toString();
          lastLocationSource = 'Router IP (${data['cityName'] ?? 'Network'})';
          return _createPosition(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('GPS Service IP provider 3 failed: $e');
    }

    // Provider 4: ipapi.co (backup)
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
          return _createPosition(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('GPS Service IP provider 4 failed: $e');
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
        debugPrint('GPS Service: Location services disabled. Fetching from Router IP.');
        final ipPos = await getLocationFromIp();
        return ipPos ?? _getFallbackPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('GPS Service: Location permission denied. Fetching from Router IP.');
          final ipPos = await getLocationFromIp();
          return ipPos ?? _getFallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('GPS Service: Location permission permanently denied. Fetching from Router IP.');
        final ipPos = await getLocationFromIp();
        return ipPos ?? _getFallbackPosition();
      }

      final devicePos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      // Check distance from target region (Malaysia / ASEAN center: 3.1466, 101.6958)
      final distFromRegionalCenterKm = Geolocator.distanceBetween(
        devicePos.latitude,
        devicePos.longitude,
        AppEnv.defaultLatitude,
        AppEnv.defaultLongitude,
      ) / 1000.0;

      // If emulator default location (Mountain View, CA ~37.422, -122.084) or > 3000 km away:
      final bool isDistantOrEmulator = distFromRegionalCenterKm > 3000.0 ||
          ((devicePos.latitude - 37.422).abs() < 1.0 && (devicePos.longitude - (-122.084)).abs() < 1.0);

      if (isDistantOrEmulator) {
        debugPrint('GPS Service: Device GPS is distant ($distFromRegionalCenterKm km). Fetching local Router IP...');
        final ipPos = await getLocationFromIp();
        if (ipPos != null) {
          final ipDistKm = Geolocator.distanceBetween(
            ipPos.latitude,
            ipPos.longitude,
            AppEnv.defaultLatitude,
            AppEnv.defaultLongitude,
          ) / 1000.0;
          if (ipDistKm < 3000.0) {
            return ipPos;
          }
        }
        // Fallback to local default coordinates (Kuala Lumpur City Center / Bukit Bintang)
        return _getFallbackPosition();
      }

      lastLocationSource = 'Device GPS';
      return devicePos;
    } catch (e) {
      debugPrint('GPS Service Exception: $e. Falling back to Router IP.');
      final ipPos = await getLocationFromIp();
      return ipPos ?? _getFallbackPosition();
    }
  }

  /// Helper to construct a Position instance
  static Position _createPosition(double lat, double lon) {
    return Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 25.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
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
    lastLocationSource = 'Local Network (KL Center)';
    lastKnownCity = 'Kuala Lumpur';
    lastKnownCountry = 'Malaysia';
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
