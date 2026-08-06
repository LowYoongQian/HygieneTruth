import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/gps_service.dart';
import '../../core/widgets/custom_app_bar.dart';

class RestaurantMapScreen extends StatefulWidget {
  const RestaurantMapScreen({super.key});

  @override
  State<RestaurantMapScreen> createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  GoogleMapController? _mapController;
  RestaurantModel? _focusedRestaurant;
  Position? _userPosition;
  bool _isLoadingGps = true;
  Set<Marker> _markers = {};

  static const LatLng _defaultCenter = LatLng(3.1466, 101.6958);

  @override
  void initState() {
    super.initState();
    _initMapMarkers();
    _fetchUserLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RestaurantModel) {
      _focusedRestaurant = args;
    }
  }

  void _initMapMarkers() {
    final restaurants = MockSeedData.restaurants;
    final Set<Marker> markers = {};

    for (final restaurant in restaurants) {
      markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(restaurant.latitude, restaurant.longitude),
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet: restaurant.category,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            setState(() {
              _focusedRestaurant = restaurant;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _isLoadingGps = true);
    final pos = await GpsService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = pos;
        _isLoadingGps = false;
        if (pos != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(pos.latitude, pos.longitude),
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        }
      });

      if (pos != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(pos.latitude, pos.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : (_focusedRestaurant != null
            ? LatLng(_focusedRestaurant!.latitude, _focusedRestaurant!.longitude)
            : _defaultCenter);

    return Scaffold(
      appBar: CustomAppBar(
        title: _focusedRestaurant != null ? _focusedRestaurant!.name : 'Outlet Map',
      ),
      body: Stack(
        children: [
          // Live Google Maps Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top GPS Status Banner / Location Indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isLoadingGps ? Icons.gps_fixed : Icons.gps_fixed_sharp,
                    color: const Color(0xFF0284C7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isLoadingGps
                          ? 'Acquiring GPS Signal...'
                          : 'GPS Active • Near ${_userPosition != null ? "${_userPosition!.latitude.toStringAsFixed(3)}, ${_userPosition!.longitude.toStringAsFixed(3)}" : "Kuala Lumpur"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_isLoadingGps)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Sheet Card for Selected Outlet
          if (_focusedRestaurant != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(_focusedRestaurant!.imageUrl),
                            radius: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _focusedRestaurant!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '${_focusedRestaurant!.category} • ${GpsService.formatDistance(
                                    _userPosition?.latitude ?? 3.1466,
                                    _userPosition?.longitude ?? 101.6958,
                                    _focusedRestaurant!.latitude,
                                    _focusedRestaurant!.longitude,
                                  )}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _focusedRestaurant = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: const Color(0xFF0284C7),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.restaurantDetail,
                            arguments: _focusedRestaurant,
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchUserLocation,
        backgroundColor: const Color(0xFF0284C7),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
