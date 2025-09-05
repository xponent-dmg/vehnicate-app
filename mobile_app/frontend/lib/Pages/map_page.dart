// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import '../config/config.dart';

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
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  Timer? _uploadTimer;
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

  // Autocomplete state
  List<Map<String, dynamic>> _autocompleteSuggestions = [];
  bool _showAutocomplete = false;
  bool _isFromFieldActive = false;

  final _vehicleId = VehicleProvider().vehicleId;

  // IMU data collection (similar to imu_collector_screen.dart)
  List<Map<String, dynamic>> _imuBuffer = [];
  final _supabase = Supabase.instance.client;
  double? _gx, _gy, _gz;

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled', Colors.orange);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions denied', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions permanently denied', Colors.red);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _fromLocation = _currentLatLng;
      });

      // Move map to current location
      _mapController.move(_currentLatLng, Config.defaultZoom);
      _updateMarkers();
    } catch (e) {
      _showSnackBar('Error getting location: $e', Colors.red);
    }
  }

  void startLiveTracking() {
    if (_isTrackingLocation) return;

    setState(() => _isTrackingLocation = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update every 1 meter
      ),
    ).listen((Position position) {
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

  void _startDataCollection() {
    if (_isCollectingData) return;

    setState(() => _isCollectingData = true);

    // Show snackbar for starting collection (exactly like imu_collector_screen.dart)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Started sensor data collection'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Gyroscope stream (exactly like imu_collector_screen.dart)
    _gyroSub = gyroscopeEvents.listen((event) {
      _gx = event.x;
      _gy = event.y;
      _gz = event.z;
    });

    // Accelerometer stream (exactly like imu_collector_screen.dart)
    _accelSub = accelerometerEvents.listen((event) {
      final imuData = {
        "vehicleid": _vehicleId,
        "timesent": DateTime.now().toIso8601String(),
        "accelx": event.x,
        "accely": event.y,
        "accelz": event.z,
        "gyrox": _gx ?? 0,
        "gyroy": _gy ?? 0,
        "gyroz": _gz ?? 0,
        "latitude": _currentPosition?.latitude ?? 0,
        "longitude": _currentPosition?.longitude ?? 0,
        "speed": _currentPosition?.speed ?? 0,
      };
      // print("Adding IMU data to buffer: $imuData");
      _imuBuffer.add(imuData);
    });

    // Upload buffer every 10s (exactly like imu_collector_screen.dart)
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_imuBuffer.isNotEmpty) {
        // Show snackbar for data upload
        print("📤 Timer triggered - uploading ${_imuBuffer.length} records");
        List<Map<String, dynamic>> temp = List.from(_imuBuffer);
        _imuBuffer.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📤 Uploaded ${temp.length} sensor records'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
        await _sendToSupabase(temp);
      } else {
        print("⏰ Upload timer triggered but buffer is empty");
      }
    });
  }

  void _stopDataCollection() async {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _uploadTimer?.cancel();
    setState(() => _isCollectingData = false);

    if (_imuBuffer.isNotEmpty) {
      // Show snackbar for data upload
      print("📤 Timer triggered - uploading ${_imuBuffer.length} records");
      List<Map<String, dynamic>> temp = List.from(_imuBuffer);
      _imuBuffer.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📤 Uploaded ${temp.length} sensor records'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
      await _sendToSupabase(temp);
    } else {
      print("buffer is empty. nothing to send and it is stopped");
    }

    // Show snackbar for stopping collection (exactly like imu_collector_screen.dart)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏹️ Stopped sensor data collection'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendToSupabase(List<Map<String, dynamic>> data) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ User not authenticated with Firebase");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please login to upload data'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      print("✅ User authenticated: ${user.uid}");

      print("📤 Sending ${data.length} records to Supabase...");

      // Transform data to match database schema
      final transformedData =
          data.map((item) {
            return {
              // Don't send dataid - let database auto-generate it
              'vehicleid': item['vehicleid'],
              // Keep as ISO8601 string to avoid JSON encoding issues
              'timesent': item['timesent'],
              'accelx': item['accelx'],
              'accely': item['accely'],
              'accelz': item['accelz'],
              'gyrox': item['gyrox'],
              'gyroy': item['gyroy'],
              'gyroz': item['gyroz'],
              'latitude': item['latitude'],
              'longitude': item['longitude'],
              'speed': item['speed'],
            };
          }).toList();

      print("📋 Transformed data structure: ${transformedData.isNotEmpty ? transformedData.first : 'No data'}");

      final response = await _supabase.from('datatransmission').insert(transformedData);

      print("✅ Successfully sent ${data.length} records to Supabase");
      print("📊 Response: $response");
    } on PostgrestException catch (e) {
      print("❌ PostgrestException: ${e.message}");
      print("❌ Details: ${e.details}");
      print("❌ Hint: ${e.hint}");
      print("❌ Code: ${e.code}");

      // Show user-friendly error message
      String errorMessage = "Database error";
      if (e.code == "23503") {
        errorMessage = "Invalid vehicle ID. Please check your vehicle settings.";
      } else if (e.code == "42501") {
        errorMessage = "Permission denied. Please check your login.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $errorMessage'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
      );

      // Add data back to buffer for retry
      _imuBuffer.addAll(data);
    } catch (e) {
      print("❌ General error sending to Supabase: $e");
      print("Error type: ${e.runtimeType}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Add data back to buffer for retry
      _imuBuffer.addAll(data);
    }
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
        final apiKey = Config.openRouteServiceApiKey;
        if (apiKey.isEmpty) return;

        print('🔍 Autocomplete search: $query');

        final response = await http.get(
          Uri.parse(
            'https://api.openrouteservice.org/geocode/autocomplete?'
            'api_key=$apiKey&'
            'text=${Uri.encodeComponent(query)}&'
            'size=8&' // Get up to 8 suggestions
            'layers=venue,address,street,locality,region,country&'
            'focus.point.lon=77.636558&' // Focus around your location
            'focus.point.lat=13.024097&'
            'boundary.circle.lon=77.636558&'
            'boundary.circle.lat=13.024097&'
            'boundary.circle.radius=50',
          ), // 50km radius for autocomplete
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final suggestions = <Map<String, dynamic>>[];

          if (data['features'] != null) {
            for (var feature in data['features']) {
              suggestions.add({
                'name': feature['properties']['name'] ?? '',
                'label': feature['properties']['label'] ?? '',
                'coordinates': feature['geometry']['coordinates'],
                'confidence': feature['properties']['confidence'] ?? 0.0,
                'layer': feature['properties']['layer'] ?? '',
              });
            }
          }

          setState(() {
            _autocompleteSuggestions = suggestions;
            _showAutocomplete = suggestions.isNotEmpty;
            _isFromFieldActive = isFromField;
          });

          print('📍 Found ${suggestions.length} autocomplete suggestions');
        }
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
      // For demo purposes, we'll use a simple geocoding approach
      // In a real app, you'd use a proper geocoding service
      LatLng? location = await _geocodeLocation(query);

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

  Future<LatLng?> _geocodeLocation(String query) async {
    print('🔍 Geocoding: $query');

    try {
      final apiKey = Config.openRouteServiceApiKey;
      if (apiKey.isEmpty) {
        _showSnackBar('❌ API key not configured', Colors.red);
        print('❌ OpenRouteService API key is empty');
        return null;
      }

      print('🌐 Making geocoding request...');

      // Improved geocoding with more specific parameters
      final response = await http.get(
        Uri.parse(
          'https://api.openrouteservice.org/geocode/search?'
          'api_key=$apiKey&'
          'text=${Uri.encodeComponent(query)}&'
          'size=5&' // Get top 5 results instead of 1
          'layers=venue,address,street,locality,region,country&' // Specific layers
          'focus.point.lon=77.636558&' // Focus around Bangalore (your location)
          'focus.point.lat=13.024097&'
          'boundary.circle.lon=77.636558&' // Search within 100km of Bangalore
          'boundary.circle.lat=13.024097&'
          'boundary.circle.radius=100',
        ),
      );

      print('📡 Geocoding response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 Geocoding found ${data['features']?.length ?? 0} results');

        if (data['features'] != null && data['features'].isNotEmpty) {
          // Show all results for debugging
          for (int i = 0; i < data['features'].length; i++) {
            final feature = data['features'][i];
            final coords = feature['geometry']['coordinates'];
            final name = feature['properties']['name'];
            final label = feature['properties']['label'];
            final confidence = feature['properties']['confidence'];
            print('Result $i: $name ($label) - Confidence: $confidence - Coords: [${coords[1]}, ${coords[0]}]');
          }

          // Take the first (highest confidence) result
          final feature = data['features'][0];
          final coordinates = feature['geometry']['coordinates'];
          final placeName = feature['properties']['name'];
          final placeLabel = feature['properties']['label'];
          final confidence = feature['properties']['confidence'];

          // OpenRouteService returns [longitude, latitude]
          final location = LatLng(coordinates[1], coordinates[0]);

          print('✅ Selected: $placeName ($placeLabel) - Confidence: $confidence');
          print('✅ Location: $location');

          // Show user what was found
          _showSnackBar('✅ Found: $placeName', Colors.green);

          return location;
        } else {
          print('❌ No results found for: $query');
          _showSnackBar('❌ No results found for "$query"', Colors.red);
        }
      } else {
        print('❌ Geocoding API error: ${response.statusCode} - ${response.body}');
        _showSnackBar('❌ Geocoding failed: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      _showSnackBar('❌ Network error: ${e.toString()}', Colors.red);
    }
    return null;
  }

  Future<void> _calculateRoute() async {
    if (_fromLocation == null || _toLocation == null) return;

    setState(() => _isLoading = true);

    try {
      final apiKey = Config.openRouteServiceApiKey;
      if (apiKey.isEmpty) {
        _showSnackBar('OpenRouteService API key not configured', Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      print('🗺️ Calculating route...');
      print('📍 From: ${_fromLocation!.latitude}, ${_fromLocation!.longitude}');
      print('📍 To: ${_toLocation!.latitude}, ${_toLocation!.longitude}');

      final url =
          '${Config.openRouteServiceBaseUrl}/v2/directions/driving-car?'
          'api_key=$apiKey&'
          'start=${_fromLocation!.longitude},${_fromLocation!.latitude}&'
          'end=${_toLocation!.longitude},${_toLocation!.latitude}';

      print('🌐 Route API URL: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Route response status: ${response.statusCode}');
      print('📡 Route response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final route = data['features'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final summary = route['properties']['summary'];

          setState(() {
            _routePoints = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
            _totalDistance = summary['distance'] / 1000; // Convert to km
            _estimatedTime = _formatDuration(summary['duration']);
          });

          _updateMarkers();
          _fitMapToRoute();

          print('✅ Route calculated successfully: ${_routePoints.length} points');
          _showSnackBar('Route calculated: ${_totalDistance.toStringAsFixed(1)} km', Colors.green);
        } else {
          print('❌ No route features in response');
          _showSnackBar('No route found between locations', Colors.red);
        }
      } else {
        print('❌ Route API error: ${response.statusCode}');
        print('❌ Error details: ${response.body}');

        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error']['message'] ?? 'Unknown error';
          _showSnackBar('Route error: $errorMessage', Colors.red);
        } catch (e) {
          _showSnackBar('Failed to calculate route (${response.statusCode})', Colors.red);
        }
      }
    } catch (e) {
      print('❌ Route calculation error: $e');
      _showSnackBar('Error calculating route: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(double seconds) {
    int hours = (seconds / 3600).floor();
    int minutes = ((seconds % 3600) / 60).floor();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
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

    double minLat = _routePoints.map((p) => p.latitude).reduce(min);
    double maxLat = _routePoints.map((p) => p.latitude).reduce(max);
    double minLng = _routePoints.map((p) => p.longitude).reduce(min);
    double maxLng = _routePoints.map((p) => p.longitude).reduce(max);

    LatLngBounds bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

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
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _uploadTimer?.cancel();
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
        child: Column(
          children: [
            // Header with navigation inputs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2d2d44),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // App bar
                  Row(
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back, color: Colors.white)),
                      const Expanded(
                        child: Text(
                          'Navigation',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: _isTrackingLocation ? stopLiveTracking : startLiveTracking,
                        icon: Icon(
                          _isTrackingLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: _isTrackingLocation ? Colors.green : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // From field
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _fromController,
                      focusNode: _fromFocusNode,
                      decoration: const InputDecoration(
                        hintText: "From",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(FontAwesomeIcons.locationCrosshairs, color: Color(0xFF8E44AD), size: 16),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) => _searchAutocomplete(value, true),
                      onSubmitted: (value) => _searchAndSetLocation(value, true),
                      onTap: () {
                        setState(() {
                          _isFromFieldActive = true;
                          if (_fromController.text.isNotEmpty) {
                            _searchAutocomplete(_fromController.text, true);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // To field
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _toController,
                      focusNode: _toFocusNode,
                      decoration: const InputDecoration(
                        hintText: "Where to? (e.g., London, Paris, Tokyo)",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(FontAwesomeIcons.locationDot, color: Colors.white54, size: 16),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) => _searchAutocomplete(value, false),
                      onSubmitted: (value) => _searchAndSetLocation(value, false),
                      onTap: () {
                        setState(() {
                          _isFromFieldActive = false;
                          if (_toController.text.isNotEmpty) {
                            _searchAutocomplete(_toController.text, false);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Autocomplete suggestions
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

                          // Set different icons based on layer type
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

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    // Debug: Check what locations we have
                                    print('From location: $_fromLocation');
                                    print('To location: $_toLocation');
                                    print('From text: ${_fromController.text}');
                                    print('To text: ${_toController.text}');

                                    // If "To" field has text but no location, try geocoding it first
                                    if (_toController.text.isNotEmpty && _toLocation == null) {
                                      _showSnackBar('Searching for destination...', Colors.blue);
                                      await _searchAndSetLocation(_toController.text, false);
                                    }

                                    // Check again after potential geocoding
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

                  // Route info
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
            ),

            // Map
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLatLng,
                  initialZoom: Config.defaultZoom,
                  minZoom: Config.minZoom,
                  maxZoom: Config.maxZoom,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  // Map tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vehnicate.app',
                    maxZoom: Config.maxZoom,
                  ),

                  // Route polyline
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

                  // Markers
                  MarkerLayer(markers: _markers),
                ],
              ),
            ),

            // Bottom controls
            Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
