import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_env.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String distanceText;
  final String durationText;
  final List<String> instructions;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.distanceText,
    required this.durationText,
    this.instructions = const [],
  });
}

class RoutingService {
  /// In-memory cache for recent routes
  static final Map<String, RouteResult> _routeCache = {};

  /// Fetches real road turn-by-turn routing using Google Directions API or OpenStreetMap / OSRM
  static Future<RouteResult> getRealRoadRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}->${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    // 1. Try Google Directions API if API key is configured
    try {
      final googleKey = _getGoogleMapsApiKey();
      if (googleKey.isNotEmpty &&
          !googleKey.contains('YOUR_') &&
          !googleKey.contains('placeholder')) {
        final googleRoute = await _fetchGoogleDirections(origin, destination, googleKey);
        if (googleRoute != null && googleRoute.points.isNotEmpty) {
          _routeCache[cacheKey] = googleRoute;
          return googleRoute;
        }
      }
    } catch (_) {}

    // 2. Try Open Source Routing Machine (OSRM) primary & mirror servers
    try {
      final osrmRoute = await _fetchOsrmRoute(origin, destination);
      if (osrmRoute != null && osrmRoute.points.isNotEmpty) {
        _routeCache[cacheKey] = osrmRoute;
        return osrmRoute;
      }
    } catch (_) {}

    // 3. Fallback to smart orthogonal street grid path
    final fallback = _generateSmartRoadPath(origin, destination);
    _routeCache[cacheKey] = fallback;
    return fallback;
  }

  static String _getGoogleMapsApiKey() {
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return AppEnv.googleMapsApiKey;
  }

  static Future<RouteResult?> _fetchGoogleDirections(
    LatLng origin,
    LatLng destination,
    String apiKey,
  ) async {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$apiKey',
      );

      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['status'] == 'OK' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final polylineStr = route['overview_polyline']?['points']?.toString() ?? '';
          final legs = route['legs'] as List<dynamic>?;
          double distanceMeters = 0;
          int durationSecs = 0;
          String distanceText = '';
          String durationText = '';
          List<String> instructions = [];

          if (legs != null && legs.isNotEmpty) {
            final firstLeg = legs[0] as Map<String, dynamic>;
            distanceMeters = (firstLeg['distance']?['value'] as num?)?.toDouble() ?? 0;
            durationSecs = (firstLeg['duration']?['value'] as num?)?.toInt() ?? 0;
            distanceText = firstLeg['distance']?['text']?.toString() ?? '';
            durationText = firstLeg['duration']?['text']?.toString() ?? '';

            final steps = firstLeg['steps'] as List<dynamic>?;
            if (steps != null) {
              for (final s in steps) {
                final htmlInst = s['html_instructions']?.toString() ?? '';
                final cleanInst = htmlInst.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
                if (cleanInst.isNotEmpty) instructions.add(cleanInst);
              }
            }
          }

          final List<LatLng> decodedPoints = decodePolyline(polylineStr);
          if (decodedPoints.isNotEmpty) {
            final double distanceKm = distanceMeters > 0
                ? (distanceMeters / 1000.0)
                : _calculateHaversineKm(origin, destination);
            final int durationMins = durationSecs > 0
                ? math.max(1, (durationSecs / 60.0).round())
                : math.max(2, (distanceKm / 0.45).round());

            final String distStr = distanceText.isNotEmpty
                ? distanceText
                : (distanceKm < 1 ? '${distanceMeters.round()} m' : '${distanceKm.toStringAsFixed(1)} km');
            final String durStr = durationText.isNotEmpty ? durationText : '$durationMins mins';

            return RouteResult(
              points: decodedPoints,
              distanceKm: distanceKm,
              durationMinutes: durationMins,
              distanceText: distStr,
              durationText: durStr,
              instructions: instructions,
            );
          }
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

  static Future<RouteResult?> _fetchOsrmRoute(LatLng origin, LatLng destination) async {
    final urls = [
      'https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true',
      'https://routing.openstreetmap.de/routed-car/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true',
    ];

    for (final urlStr in urls) {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = const Duration(seconds: 6);
      try {
        final uri = Uri.parse(urlStr);
        final request = await client.getUrl(uri);
        request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10; Mobile)');
        request.headers.set('Accept', 'application/json');
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['code'] == 'Ok' &&
              data['routes'] is List &&
              (data['routes'] as List).isNotEmpty) {
            final route = data['routes'][0] as Map<String, dynamic>;
            final double distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
            final double durationSecs = (route['duration'] as num?)?.toDouble() ?? 0.0;
            final geometry = route['geometry'] as Map<String, dynamic>?;
            final coords = geometry?['coordinates'] as List<dynamic>?;

            final List<LatLng> points = [];
            if (coords != null) {
              for (final c in coords) {
                if (c is List && c.length >= 2) {
                  final lng = (c[0] as num).toDouble();
                  final lat = (c[1] as num).toDouble();
                  points.add(LatLng(lat, lng));
                }
              }
            }

            final List<String> instructions = [];
            final legs = route['legs'] as List<dynamic>?;
            if (legs != null && legs.isNotEmpty) {
              final steps = legs[0]['steps'] as List<dynamic>?;
              if (steps != null) {
                for (final s in steps) {
                  final name = s['name']?.toString() ?? '';
                  final type = s['maneuver']?['type']?.toString() ?? '';
                  final modifier = s['maneuver']?['modifier']?.toString() ?? '';
                  if (name.isNotEmpty) {
                    final prefix = [type, modifier].where((e) => e.isNotEmpty).join(' ');
                    instructions.add(prefix.isNotEmpty ? '$prefix onto $name' : 'Proceed onto $name');
                  }
                }
              }
            }

            if (points.isNotEmpty) {
              final double distanceKm = distanceMeters / 1000.0;
              final int durationMins = math.max(1, (durationSecs / 60.0).round());
              final String distStr = distanceKm < 1
                  ? '${distanceMeters.round()} m'
                  : '${distanceKm.toStringAsFixed(1)} km';
              final String durStr = '$durationMins mins';

              return RouteResult(
                points: points,
                distanceKm: distanceKm,
                durationMinutes: durationMins,
                distanceText: distStr,
                durationText: durStr,
                instructions: instructions,
              );
            }
          }
        }
      } catch (_) {
        // Try next mirror
      } finally {
        client.close();
      }
    }
    return null;
  }

  static RouteResult _generateSmartRoadPath(LatLng start, LatLng end) {
    final double distMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    final double distKm = (distMeters / 1000.0) * 1.25;
    final int minutes = math.max(2, (distKm / 0.45).round() + 2);

    final List<LatLng> pts = [start];
    final double dLat = end.latitude - start.latitude;
    final double dLng = end.longitude - start.longitude;

    pts.add(LatLng(start.latitude + dLat * 0.35, start.longitude));
    pts.add(LatLng(start.latitude + dLat * 0.35, start.longitude + dLng * 0.45));
    pts.add(LatLng(start.latitude + dLat * 0.70, start.longitude + dLng * 0.45));
    pts.add(LatLng(start.latitude + dLat * 0.70, start.longitude + dLng * 0.85));
    pts.add(LatLng(start.latitude + dLat * 0.95, start.longitude + dLng * 0.85));
    pts.add(LatLng(start.latitude + dLat * 0.95, end.longitude));
    pts.add(end);

    final String distStr = distKm < 1
        ? '${(distKm * 1000).round()} m'
        : '${distKm.toStringAsFixed(1)} km';
    final String durStr = '$minutes mins';

    return RouteResult(
      points: pts,
      distanceKm: distKm,
      durationMinutes: minutes,
      distanceText: distStr,
      durationText: durStr,
    );
  }

  static double _calculateHaversineKm(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude) /
        1000.0;
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
