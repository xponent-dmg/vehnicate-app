// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/config.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/services/imu_service.dart';
import 'package:vehnicate_frontend/services/map_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> with TickerProviderStateMixin {
  // Controllers
  final MapController _mapController = MapController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();

  // Location and tracking
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _autocompleteTimer;

  // Map state
  LatLng _currentLatLng = LatLng(Config.defaultLatitude, Config.defaultLongitude);
  List<LatLng> _routePoints = [];
  List<Marker> _markers = [];
  bool _isLoading = false;
  bool _isTrackingLocation = false;
  bool _isCollectingData = false;

  // Navigation state
  LatLng? _fromLocation;
  LatLng? _toLocation;
  double _totalDistance = 0.0;
  String _estimatedTime = '';
  int? _vehicleId;

  // Autocomplete state
  List<Map<String, dynamic>> _autocompleteSuggestions = [];
  bool _showAutocomplete = false;
  bool _isFromFieldActive = false;

  // IMU service
  final ImuService _imuService = ImuService();
  final MapService _mapService = const MapService();

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _setupPulseAnimation();
    _fromController.text = "Current location";
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _mapService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _fromLocation = _currentLatLng;
      });
      _mapController.move(_currentLatLng, Config.defaultZoom);
      _updateMarkers();
    } catch (e) {
      _showSnackBar('Error getting location: $e', Colors.red);
    }
  }

  void startLiveTracking() {
    if (_isTrackingLocation) return;

    setState(() => _isTrackingLocation = true);
    _positionStream = _mapService.positionStream(accuracy: LocationAccuracy.high, distanceFilter: 1).listen((
      Position position,
    ) {
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _fromLocation = _currentLatLng;
      });

      // Keep map centered on user location during live tracking
      _mapController.move(_currentLatLng, _mapController.camera.zoom);
      _updateMarkers();
    });

    _showSnackBar('🔄 Live tracking started', Colors.green);
  }

  void stopLiveTracking() {
    _positionStream?.cancel();
    setState(() => _isTrackingLocation = false);
    _showSnackBar('⏹️ Live tracking stopped', Colors.orange);
  }

  Future<void> _startDataCollection() async {
    if (_isCollectingData) return;

    // Ensure we have a vehicle ID from the provider
    final vehicleProvider = context.read<VehicleProvider>();
    int? vid = vehicleProvider.vehicleId;
    if (vid == null) {
      await vehicleProvider.refresh();
      vid = vehicleProvider.vehicleId;
    }
    if (vid == null) {
      _showSnackBar('❌ No vehicle linked. Please update your profile with a vehicle.', Colors.red);
      return;
    }
    _vehicleId = vid;

    setState(() => _isCollectingData = true);
    await _imuService.start(
      context: context,
      vehicleId: _vehicleId!,
      getCurrentPosition: () => _currentPosition,
      manageLocationStream: false,
      useUserAccelerometer: true,
      authProvider: AuthProvider.firebase,
    );
  }

  void _stopDataCollection() async {
    setState(() => _isCollectingData = false);
    await _imuService.stop(context, authProvider: AuthProvider.firebase);
  }

  Future<void> _searchAutocomplete(String query, bool isFromField) async {
    if (query.length < 2) {
      setState(() {
        _showAutocomplete = false;
        _autocompleteSuggestions.clear();
      });
      return;
    }

    // Cancel previous timer
    _autocompleteTimer?.cancel();

    // Debounce the search - wait 300ms after user stops typing
    _autocompleteTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        print('🔍 Autocomplete search: $query');
        final suggestions = await _mapService.fetchAutocompleteSuggestions(query);
        setState(() {
          _autocompleteSuggestions = suggestions;
          _showAutocomplete = suggestions.isNotEmpty;
          _isFromFieldActive = isFromField;
        });
        print('📍 Found ${suggestions.length} autocomplete suggestions');
      } catch (e) {
        print('❌ Autocomplete error: $e');
      }
    });
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final coordinates = suggestion['coordinates'];
    final location = LatLng(coordinates[1], coordinates[0]);
    final name = suggestion['name'];
    // final label = suggestion['label'];

    setState(() {
      if (_isFromFieldActive) {
        _fromLocation = location;
        _fromController.text = name;
      } else {
        _toLocation = location;
        _toController.text = name;
      }
      _showAutocomplete = false;
      _autocompleteSuggestions.clear();
    });

    // Remove focus to hide keyboard
    _fromFocusNode.unfocus();
    _toFocusNode.unfocus();

    _updateMarkers();
    _showSnackBar('✅ Selected: $name', Colors.green);

    // If both locations are set, offer to calculate route
    if (_fromLocation != null && _toLocation != null) {
      _showSnackBar('📍 Tap "Get Route" to calculate directions', Colors.blue);
    }
  }

  Future<void> _searchAndSetLocation(String query, bool isFromLocation) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      LatLng? location = await _mapService.geocodeLocation(query);

      if (location != null) {
        setState(() {
          if (isFromLocation) {
            _fromLocation = location;
            _fromController.text = query;
          } else {
            _toLocation = location;
            _toController.text = query;
          }
        });
        _updateMarkers();

        // If both locations are set, calculate route
        if (_fromLocation != null && _toLocation != null) {
          await _calculateRoute();
        }
      } else {
        _showSnackBar('Location not found', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error searching location: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    if (_fromLocation == null || _toLocation == null) return;

    setState(() => _isLoading = true);

    try {
      print('🗺️ Calculating route...');
      print('📍 From: ${_fromLocation!.latitude}, ${_fromLocation!.longitude}');
      print('📍 To: ${_toLocation!.latitude}, ${_toLocation!.longitude}');

      final result = await _mapService.calculateRoute(_fromLocation!, _toLocation!);

      setState(() {
        _routePoints = result.points;
        _totalDistance = result.totalDistanceKm;
        _estimatedTime = result.formattedDuration;
      });

      _updateMarkers();
      _fitMapToRoute();

      print('✅ Route calculated successfully: ${_routePoints.length} points');
      _showSnackBar('Route calculated: ${_totalDistance.toStringAsFixed(1)} km', Colors.green);
    } catch (e) {
      print('❌ Route calculation error: $e');
      _showSnackBar('Error calculating route: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    List<Marker> markers = [];

    // Current location marker with pulse animation
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentLatLng,
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.3 * _pulseAnimation.value),
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 12),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // From location marker
    if (_fromLocation != null && _fromLocation != _currentLatLng) {
      markers.add(
        Marker(
          point: _fromLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }

    // To location marker
    if (_toLocation != null) {
      markers.add(
        Marker(
          point: _toLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    final bounds = _mapService.boundsForRoute(_routePoints);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _toLocation = null;
      _toController.clear();
      _totalDistance = 0.0;
      _estimatedTime = '';
    });
    _updateMarkers();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _imuService.dispose();
    _autocompleteTimer?.cancel();
    _pulseController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(children: [_buildTopPanel(context), Expanded(child: _buildMap()), _buildBottomControls()]),
      ),
      //TODO: Add back the FAB in production
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _mapController.move(_currentLatLng, Config.defaultZoom);
      //   },
      //   backgroundColor: const Color(0xFF3d3d54),
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //   child: const Icon(Icons.my_location, color: Colors.white),
      // ),
    );
  }

  // UI components
  Widget _buildTopPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2d2d44),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Navigation',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // IconButton(
              //   onPressed: _isTrackingLocation ? stopLiveTracking : startLiveTracking,
              //   icon: Icon(
              //     _isTrackingLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
              //     color: _isTrackingLocation ? Colors.green : Colors.white,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationTextField(
            controller: _fromController,
            focusNode: _fromFocusNode,
            hintText: "From",
            prefixIcon: FontAwesomeIcons.locationCrosshairs,
            color: Color(0xFF8E44AD),
            onChanged: (value) => _searchAutocomplete(value, true),
            onSubmitted: (value) => _searchAndSetLocation(value, true),
            isFromFieldActive: true,
          ),
          const SizedBox(height: 12),
          _buildLocationTextField(
            controller: _toController,
            focusNode: _toFocusNode,
            hintText: "Where to? (e.g., London, Paris, Tokyo)",
            prefixIcon: FontAwesomeIcons.locationDot,
            color: Colors.white54,
            onChanged: (value) => _searchAutocomplete(value, false),
            onSubmitted: (value) => _searchAndSetLocation(value, false),
            isFromFieldActive: false,
          ),
          const SizedBox(height: 16),
          if (_showAutocomplete && _autocompleteSuggestions.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8E44AD).withOpacity(0.3)),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _autocompleteSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _autocompleteSuggestions[index];
                  final name = suggestion['name'] ?? '';
                  final label = suggestion['label'] ?? '';
                  final layer = suggestion['layer'] ?? '';
                  final confidence = suggestion['confidence'] ?? 0.0;

                  IconData icon = Icons.location_on;
                  Color iconColor = Colors.white54;

                  switch (layer) {
                    case 'venue':
                      icon = Icons.place;
                      iconColor = const Color(0xFF8E44AD);
                      break;
                    case 'address':
                      icon = Icons.home;
                      iconColor = Colors.blue;
                      break;
                    case 'street':
                      icon = Icons.route;
                      iconColor = Colors.orange;
                      break;
                    case 'locality':
                    case 'region':
                      icon = Icons.location_city;
                      iconColor = Colors.green;
                      break;
                    case 'country':
                      icon = Icons.flag;
                      iconColor = Colors.red;
                      break;
                  }

                  return ListTile(
                    dense: true,
                    leading: Icon(icon, color: iconColor, size: 20),
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle:
                        label.isNotEmpty && label != name
                            ? Text(
                              label,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                            : null,
                    trailing: confidence > 0.7 ? const Icon(Icons.star, color: Colors.amber, size: 16) : null,
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            print('From location: $_fromLocation');
                            print('To location: $_toLocation');
                            print('From text: ${_fromController.text}');
                            print('To text: ${_toController.text}');

                            if (_toController.text.isNotEmpty && _toLocation == null) {
                              _showSnackBar('Searching for destination...', Colors.blue);
                              await _searchAndSetLocation(_toController.text, false);
                            }

                            if (_fromLocation != null && _toLocation != null) {
                              await _calculateRoute();
                            } else {
                              String missingLocation = '';
                              if (_fromLocation == null) missingLocation += 'From ';
                              if (_toLocation == null) missingLocation += 'To ';
                              _showSnackBar('Please set $missingLocation location(s)', Colors.orange);
                            }
                          },
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : const Icon(Icons.directions, color: Colors.white),
                  label: Text(_isLoading ? 'Loading...' : 'Get Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E44AD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clearRoute,
                icon: const Icon(Icons.clear, color: Colors.white),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3d3d54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          if (_routePoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E44AD).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8E44AD)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.straighten, color: Color(0xFF8E44AD), size: 16),
                      Text(
                        '${_totalDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF8E44AD), size: 16),
                      Text(_estimatedTime, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLatLng,
        initialZoom: Config.defaultZoom,
        minZoom: Config.minZoom,
        maxZoom: Config.maxZoom,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.vehnicate.app',
          maxZoom: Config.maxZoom,
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: const Color(0xFF8E44AD),
                pattern: const StrokePattern.solid(),
              ),
            ],
          ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2d2d44),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCollectingData ? _stopDataCollection : _startDataCollection,
              icon: Icon(_isCollectingData ? Icons.stop : Icons.sensors, color: Colors.white),
              label: Text(_isCollectingData ? 'Stop IMU Collection' : 'Start IMU Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCollectingData ? Colors.red : const Color(0xFF8E44AD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _mapController.move(_currentLatLng, Config.defaultZoom);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3d3d54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    required Color color,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
    required bool isFromFieldActive,
  }) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white54),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
          prefixIcon: Icon(prefixIcon, color: color, size: 16),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => onChanged(value),
        onSubmitted: (value) => onSubmitted(value),
        onTap: () {
          setState(() {
            isFromFieldActive = isFromFieldActive;
            if (controller.text.isNotEmpty) {
              _searchAutocomplete(controller.text, isFromFieldActive);
            }
          });
        },
      ),
    );
  }
}
