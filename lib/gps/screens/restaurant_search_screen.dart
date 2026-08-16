import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/language_manager.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_skeletons.dart';
import '../widgets/restaurant_card.dart';

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isLoading = true;

  StreamSubscription? _realtimeSub;

  // Filter States
  String _selectedCategory = 'All';
  String _selectedRanking = 'All'; // 'All', 'Low', 'Medium', 'High'
  bool _isNearbyOnly = false;

  List<RestaurantModel> _allRestaurants = [];
  List<RestaurantModel> _filteredList = [];

  // Reference User Location for Nearby calculation (Kuala Lumpur City Center)
  final double _userLat = 3.1466;
  final double _userLng = 101.6958;

  bool _initializedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _selectedCategory = args;
        _applyFilters();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _setupRealtimeSubscription();
    _loadRestaurantsFromSupabase();
    RestaurantStoreService.restaurantsNotifier.addListener(_onRestaurantsUpdated);
  }

  void _onRestaurantsUpdated() {
    if (mounted) {
      setState(() {
        _allRestaurants = RestaurantStoreService.restaurantsNotifier.value;
      });
      _applyFilters();
    }
  }

  Future<void> _loadRestaurantsFromSupabase() async {
    setState(() => _isLoading = true);
    final list = await RestaurantStoreService.fetchAllRestaurants(forceRefresh: true);
    if (mounted) {
      setState(() {
        _allRestaurants = list;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final supabase = SupabaseService.client;
      _realtimeSub = supabase
          .from('restaurants')
          .stream(primaryKey: ['id'])
          .listen((data) async {
            final updatedList = await RestaurantStoreService.fetchAllRestaurants(forceRefresh: true);
            if (mounted) {
              setState(() {
                _allRestaurants = updatedList;
              });
              _applyFilters();
            }
          });
    } catch (e) {
      debugPrint('Realtime search stream error: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _realtimeSub?.cancel();
    RestaurantStoreService.restaurantsNotifier.removeListener(_onRestaurantsUpdated);
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing SpeechToText: $e');
    }
  }

  void _startVoiceSearch() async {
    if (!_isSpeechAvailable) {
      _isSpeechAvailable = await _speechToText.initialize();
      if (!_isSpeechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice search speech recognition not available on this device.')),
          );
        }
        return;
      }
    }

    setState(() {
      _isListening = true;
    });

    _showVoiceSearchBottomSheet();

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _searchCtrl.text = result.recognizedWords;
            _applyFilters();
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
                    'Try saying "Noodle", "Bistro", "Mamak" or "Chinese"',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),

                  // Animated Pulsing Mic Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.2),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                          ),
                          child: const Icon(
                            Icons.mic,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Speech Recognized Words Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _searchCtrl.text.isEmpty ? 'Say something...' : _searchCtrl.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _searchCtrl.text.isEmpty ? Colors.grey : AppTheme.navyColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _stopVoiceSearch,
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (_isListening) {
        _speechToText.stop();
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();

    setState(() {
      _filteredList = _allRestaurants.where((r) {
        final matchesQuery = query.isEmpty ||
            r.name.toLowerCase().contains(query) ||
            r.category.toLowerCase().contains(query) ||
            r.address.toLowerCase().contains(query);

        final matchesCategory = _selectedCategory == 'All' ||
            r.category.toLowerCase() == _selectedCategory.toLowerCase();

        bool matchesRanking = true;
        if (_selectedRanking == 'Low') {
          matchesRanking = r.riskCategory == RiskCategory.safe;
        } else if (_selectedRanking == 'Medium') {
          matchesRanking = r.riskCategory == RiskCategory.moderate;
        } else if (_selectedRanking == 'High') {
          matchesRanking = r.riskCategory == RiskCategory.high;
        }

        bool matchesNearby = true;
        if (_isNearbyOnly) {
          final distanceMeters = Geolocator.distanceBetween(
            _userLat,
            _userLng,
            r.latitude,
            r.longitude,
          );
          matchesNearby = (distanceMeters / 1000) <= 8.0;
        }

        return matchesQuery && matchesCategory && matchesRanking && matchesNearby;
      }).toList();

      if (_isNearbyOnly) {
        _filteredList.sort((a, b) {
          final distA = Geolocator.distanceBetween(_userLat, _userLng, a.latitude, a.longitude);
          final distB = Geolocator.distanceBetween(_userLat, _userLng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }
    });
  }

  void _openFilterBottomSheet() {
    final List<String> categories = [
      'All',
      ..._allRestaurants.map((r) => r.category).where((c) => c.isNotEmpty).toSet(),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setFilterState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Outlets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Cuisine Category Dropdown
                  const Text(
                    'Cuisine Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categories.contains(_selectedCategory) ? _selectedCategory : 'All',
                        isExpanded: true,
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setFilterState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hygiene Risk Level Selector
                  const Text(
                    'Hygiene Risk Level',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Low', 'Medium', 'High'].map((rank) {
                      final isSelected = _selectedRanking == rank;
                      return ChoiceChip(
                        label: Text(
                          rank == 'All' ? 'All Risk Levels' : '$rank Risk',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.navyColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (selected) {
                          setFilterState(() {
                            _selectedRanking = selected ? rank : 'All';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Nearby Only Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Nearby Outlets Only (< 8 km)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                    ),
                    subtitle: const Text(
                      'Sort outlets closest to your current GPS location',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _isNearbyOnly,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      setFilterState(() {
                        _isNearbyOnly = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Apply Filter Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'All' || _selectedRanking != 'All' || _isNearbyOnly;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        return Scaffold(
          appBar: CustomAppBar(title: t('search_outlets').split('.').first),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // Search Input Bar with Speech-to-Text Mic and Custom Equalizer Filter Icon at Far Right
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText: 'Search outlets...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchCtrl.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _applyFilters();
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
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Custom Equalizer Slider Filter Button at FAR RIGHT
                      Stack(
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: _hasActiveFilters ? AppTheme.primaryColor : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hasActiveFilters ? AppTheme.primaryColor : Colors.grey.shade300,
                                width: 1.2,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.tune_rounded,
                                color: _hasActiveFilters ? Colors.white : AppTheme.navyColor,
                              ),
                              tooltip: 'Filter Outlets',
                              onPressed: _openFilterBottomSheet,
                            ),
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF80EE98),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Filter Chips Summary (if any)
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_selectedCategory != 'All')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text('Category: $_selectedCategory'),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                          if (_selectedRanking != 'All')
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text('Risk: $_selectedRanking'),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setState(() {
                                    _selectedRanking = 'All';
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                          if (_isNearbyOnly)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: const Text('Nearby Only (< 8 km)'),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setState(() {
                                    _isNearbyOnly = false;
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Outlets Count & Map View Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredList.length} Outlets',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('Map View'),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantMap),
                      ),
                    ],
                  ),
                ),

                // Outlet Results List with Pull to Refresh & Shimmer Loading
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: 4,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: BaseSkeleton(
                              width: double.infinity,
                              height: 230,
                              borderRadius: 16,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRestaurantsFromSupabase,
                          color: AppTheme.primaryColor,
                          child: _filteredList.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 80),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'No outlets match your filters',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _searchCtrl.clear();
                                                _selectedCategory = 'All';
                                                _selectedRanking = 'All';
                                                _isNearbyOnly = false;
                                                _applyFilters();
                                              });
                                            },
                                            child: const Text('Reset All Search Filters'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _filteredList.length,
                                  itemBuilder: (context, index) {
                                    return RestaurantCard(restaurant: _filteredList[index]);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
