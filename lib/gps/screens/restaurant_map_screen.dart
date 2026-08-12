import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/language_manager.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_skeletons.dart';

class RestaurantMapScreen extends StatefulWidget {
  final bool showAppBar;
  const RestaurantMapScreen({super.key, this.showAppBar = true});

  @override
  State<RestaurantMapScreen> createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  GoogleMapController? _mapController;
  late PageController _pageController;

  RestaurantModel? _focusedRestaurant;
  Position? _userPosition;
  bool _showHeatmap = true; // Toggle for Risk Heatmap Layer
  MapType _currentMapType = MapType.normal; // Default 3D Vector Map with 3D Buildings & Tilt
  int _currentPageIndex = 0;

  String _filterRisk = 'All'; // 'All', 'Safe', 'Moderate', 'High Risk'
  final TextEditingController _listSearchCtrl = TextEditingController();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  Set<Marker> _markers = {};
  Set<Circle> _heatmapCircles = {};
  List<RestaurantModel> _allRestaurants = [];
  List<RestaurantModel> _filteredList = [];

  static const LatLng _defaultCenter = LatLng(3.1466, 101.6958);

  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
    _loadRestaurantsFromSupabase();
    _fetchUserLocation();
    _initSpeechState();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    });
  }

  Future<void> _loadRestaurantsFromSupabase() async {
    final list = await RestaurantStoreService.fetchOwnerRestaurants(null);
    if (mounted) {
      setState(() {
        _allRestaurants = list;
        _filteredList = list;
      });
      _initMapMarkersAndHeatmap();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _listSearchCtrl.dispose();
    super.dispose();
  }

  bool get _isSatellite => _currentMapType == MapType.hybrid;

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.hybrid;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  void _showMapTypeOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Google Map View',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMapTypeCard('3D Vector Map', MapType.normal, Icons.view_in_ar),
                    _buildMapTypeCard('Satellite View', MapType.hybrid, Icons.satellite_alt),
                    _buildMapTypeCard('Terrain View', MapType.terrain, Icons.terrain),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTypeCard(String label, MapType type, IconData icon) {
    final isSelected = _currentMapType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMapType = type;
        });
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : AppTheme.navyColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initSpeechState() async {
    try {
      await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
    } catch (_) {}
  }

  Future<void> _startVoiceSearch() async {
    bool available = await _speechToText.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available on this device.')),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
    });

    _showVoiceSearchBottomSheet();

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _listSearchCtrl.text = result.recognizedWords;
            _filterRestaurantList();
          });
        }
        if (result.finalResult) {
          _speechToText.stop();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _stopVoiceSearch() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showVoiceSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Listening for Outlets & Cuisine...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _listSearchCtrl.text.isEmpty ? 'Speak outlet name (e.g. Golden Dragon)' : _listSearchCtrl.text,
                    style: TextStyle(fontSize: 14, color: _listSearchCtrl.text.isEmpty ? Colors.grey : AppTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),

                  // Animated Voice Pulse Waveform
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.mic, color: Colors.white, size: 28),
                          onPressed: _stopVoiceSearch,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _stopVoiceSearch,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchUserLocation() async {
    final pos = await GpsService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _userPosition = pos;
      });
      _animateMapToLocation(pos.latitude, pos.longitude);
    }
  }

  void _initMapMarkersAndHeatmap() {
    final Set<Marker> newMarkers = {};
    final Set<Circle> newCircles = {};

    for (var i = 0; i < _filteredList.length; i++) {
      final r = _filteredList[i];
      final pos = LatLng(r.latitude, r.longitude);

      // Marker Icon Color based on Hygiene Risk Category
      BitmapDescriptor markerColor;
      switch (r.riskCategory) {
        case RiskCategory.safe:
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case RiskCategory.moderate:
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        case RiskCategory.high:
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(r.id),
          position: pos,
          icon: markerColor,
          infoWindow: InfoWindow(
            title: r.name,
            snippet: 'Risk: ${r.hygieneRiskScore.toStringAsFixed(1)} | ${r.category}',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: r);
            },
          ),
          onTap: () {
            _onMarkerTapped(i, r);
          },
        ),
      );

      // Semi-transparent Risk Heatmap Zone Circle
      Color circleColor;
      switch (r.riskCategory) {
        case RiskCategory.safe:
          circleColor = Colors.green.withValues(alpha: 0.18);
          break;
        case RiskCategory.moderate:
          circleColor = Colors.orange.withValues(alpha: 0.22);
          break;
        case RiskCategory.high:
          circleColor = Colors.red.withValues(alpha: 0.28);
          break;
      }

      newCircles.add(
        Circle(
          circleId: CircleId('circle_${r.id}'),
          center: pos,
          radius: 120 + (r.hygieneRiskScore * 2.5),
          fillColor: circleColor,
          strokeColor: circleColor.withValues(alpha: 0.6),
          strokeWidth: 1,
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
      _heatmapCircles = newCircles;
    });
  }

  void _onMarkerTapped(int index, RestaurantModel restaurant) {
    setState(() {
      _focusedRestaurant = restaurant;
      _currentPageIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    _animateMapToLocation(restaurant.latitude, restaurant.longitude);
  }

  void _onPageChanged(int index) {
    if (index >= 0 && index < _filteredList.length) {
      final restaurant = _filteredList[index];
      setState(() {
        _focusedRestaurant = restaurant;
        _currentPageIndex = index;
      });
      _animateMapToLocation(restaurant.latitude, restaurant.longitude);
    }
  }

  void _animateMapToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 17.5,
          tilt: 60.0,
          bearing: 45.0,
        ),
      ),
    );
  }

  void _filterRestaurantList() {
    final query = _listSearchCtrl.text.toLowerCase().trim();
    List<RestaurantModel> temp = List.from(_allRestaurants);

    if (query.isNotEmpty) {
      temp = temp.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.category.toLowerCase().contains(query) ||
            r.address.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterRisk != 'All') {
      temp = temp.where((r) {
        if (_filterRisk == 'Safe') return r.riskCategory == RiskCategory.safe;
        if (_filterRisk == 'Moderate') return r.riskCategory == RiskCategory.moderate;
        if (_filterRisk == 'High Risk') return r.riskCategory == RiskCategory.high;
        return true;
      }).toList();
    }

    setState(() {
      _filteredList = temp;
      _currentPageIndex = 0;
    });

    _initMapMarkersAndHeatmap();

    if (_filteredList.isNotEmpty && _mapController != null) {
      _animateMapToLocation(_filteredList[0].latitude, _filteredList[0].longitude);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  String _calculateDistanceText(double lat, double lng) {
    if (_userPosition != null) {
      final meters = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, lat, lng);
      final km = meters / 1000.0;
      final miles = km * 0.621371;
      return '${miles.toStringAsFixed(1)} mi (${km.toStringAsFixed(1)} km)';
    }
    return '0.2 mi (0.3 km)';
  }

  Color _getRiskColor(RiskCategory category) {
    switch (category) {
      case RiskCategory.safe:
        return const Color(0xFF10B981);
      case RiskCategory.moderate:
        return const Color(0xFFF59E0B);
      case RiskCategory.high:
        return const Color(0xFFEF4444);
    }
  }

  void _showFilterBottomSheet() {
    String tempFilter = _filterRisk;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Title & Reset Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('filter_by_hygiene'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() => tempFilter = 'All');
                          },
                          child: Text(t('reset'), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Choice Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'raw': 'All', 'label': t('all')},
                        {'raw': 'Safe', 'label': t('safe')},
                        {'raw': 'Moderate', 'label': t('moderate')},
                        {'raw': 'High Risk', 'label': t('high_risk')},
                      ].map((item) {
                        final filterKey = item['raw']!;
                        final displayLabel = item['label']!;
                        final isSelected = tempFilter == filterKey;
                        Color chipColor = AppTheme.primaryColor;
                        if (filterKey == 'Safe') chipColor = const Color(0xFF10B981);
                        if (filterKey == 'Moderate') chipColor = const Color(0xFFF59E0B);
                        if (filterKey == 'High Risk') chipColor = const Color(0xFFEF4444);

                        return ChoiceChip(
                          label: Text(displayLabel),
                          selected: isSelected,
                          selectedColor: chipColor,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => tempFilter = filterKey);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Apply Filter Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _filterRisk = tempFilter;
                            _filterRestaurantList();
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          t('apply_filter'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        if (_isMapLoading) {
          return Scaffold(
            appBar: widget.showAppBar ? CustomAppBar(title: t('map')) : null,
            body: const MapSkeletonLoader(),
          );
        }

        final initialTarget = _focusedRestaurant != null
            ? LatLng(_focusedRestaurant!.latitude, _focusedRestaurant!.longitude)
            : (_userPosition != null
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : _defaultCenter);

        return Scaffold(
          appBar: widget.showAppBar ? CustomAppBar(title: t('map')) : null,
          body: Stack(
            children: [
              // 1. FULL-SCREEN GOOGLE MAP BACKGROUND
              GoogleMap(
                mapType: _currentMapType,
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 17.5,
                  tilt: 60.0,
                  bearing: 45.0,
                ),
                buildingsEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _markers,
                circles: _showHeatmap ? _heatmapCircles : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // 2. FLOATING SEARCH BAR WITH SPEECH-TO-TEXT & RISK LEGEND AT TOP
              Positioned(
                top: widget.showAppBar ? 2 : 12,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Floating Search Input Bar with Speech-to-Text Mic Icon in front of Filter Button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _listSearchCtrl,
                            onChanged: (_) => _filterRestaurantList(),
                            decoration: InputDecoration(
                              hintText: t('search_map_hint'),
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.navyColor),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_listSearchCtrl.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                      onPressed: () {
                                        _listSearchCtrl.clear();
                                        _filterRestaurantList();
                                      },
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: _isListening ? Colors.red : AppTheme.primaryColor,
                                    ),
                                    tooltip: 'Voice Search',
                                    onPressed: _startVoiceSearch,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.tune, color: AppTheme.primaryColor),
                                    tooltip: 'Filter Outlets',
                                    onPressed: _showFilterBottomSheet,
                                  ),
                                ],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Floating Risk Heatmap Legend Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendDot(t('safe'), Colors.green),
                              _buildLegendDot(t('moderate'), Colors.amber),
                              _buildLegendDot(t('high_risk'), Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

          // 3. MAP CONTROLS: GOOGLE SATELLITE LAYER, HEATMAP TOGGLE & MY LOCATION BUTTONS
          Positioned(
            right: 16,
            bottom: 260,
            child: Column(
              children: [
                GestureDetector(
                  onLongPress: _showMapTypeOptionsSheet,
                  child: FloatingActionButton.small(
                    heroTag: 'btn_satellite',
                    onPressed: _toggleMapType,
                    backgroundColor: _isSatellite ? AppTheme.navyColor : Colors.white,
                    foregroundColor: _isSatellite ? Colors.white : AppTheme.navyColor,
                    tooltip: 'Toggle Satellite / Map Layer',
                    child: Icon(_isSatellite ? Icons.satellite_alt : Icons.layers_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btn_heatmap',
                  onPressed: () {
                    setState(() {
                      _showHeatmap = !_showHeatmap;
                    });
                  },
                  backgroundColor: _showHeatmap ? Colors.red.shade600 : Colors.white,
                  foregroundColor: _showHeatmap ? Colors.white : AppTheme.navyColor,
                  tooltip: 'Toggle Heatmap',
                  child: const Icon(Icons.local_fire_department, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btn_gps',
                  onPressed: _fetchUserLocation,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  tooltip: 'Current Location',
                  child: const Icon(Icons.my_location, size: 18),
                ),
              ],
            ),
          ),

          // 4. FLOATING SWIPABLE RESTAURANT CARDS LIST AT BOTTOM WITH BACKDROP BLUR
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SizedBox(
              height: 235,
              child: _filteredList.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          'No outlets match your search filter',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _filteredList.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final restaurant = _filteredList[index];
                        final isSelectedCard = index == _currentPageIndex;
                        final distanceText = _calculateDistanceText(restaurant.latitude, restaurant.longitude);
                        final riskColor = _getRiskColor(restaurant.riskCategory);

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: restaurant);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: isSelectedCard
                                  ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.6), width: 2)
                                  : Border.all(color: Colors.transparent),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelectedCard ? 0.18 : 0.10),
                                  blurRadius: isSelectedCard ? 18 : 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Image Container with Badge
                                      SizedBox(
                                        height: 125,
                                        width: double.infinity,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              restaurant.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                                              ),
                                            ),
                                            // Top Right Hygiene Risk Chip Badge
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: riskColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.2),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  restaurant.riskCategory.name.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Card Body Container with Backdrop Filter Blur
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              color: Colors.white.withValues(alpha: 0.88),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  // Title
                                                  Text(
                                                    restaurant.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: AppTheme.navyColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),

                                                  // Rating & Distance Row
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.star, color: Colors.amber, size: 15),
                                                      const SizedBox(width: 3),
                                                      const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                      const SizedBox(width: 4),
                                                      Text('(128)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                                      const SizedBox(width: 6),
                                                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                                                      const SizedBox(width: 6),
                                                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                                      const SizedBox(width: 2),
                                                      Expanded(
                                                        child: Text(
                                                          distanceText,
                                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  // Tags Row (Category & Amenities)
                                                  Row(
                                                    children: [
                                                      _buildCardTag(restaurant.category, Colors.pink.shade50, Colors.pink.shade700),
                                                      const SizedBox(width: 6),
                                                      _buildCardTag('Indoor Seating', Colors.blue.shade50, Colors.blue.shade700),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  },
);
}

  Widget _buildCardTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
        ),
      ],
    );
  }
}
