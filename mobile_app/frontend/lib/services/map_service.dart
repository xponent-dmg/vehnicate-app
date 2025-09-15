import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:vehnicate_frontend/config/config.dart';
import 'package:flutter_map/flutter_map.dart';

class MapRouteResult {
  final List<LatLng> points;
  final double totalDistanceKm;
  final double durationSeconds;

  const MapRouteResult({required this.points, required this.totalDistanceKm, required this.durationSeconds});

  String get formattedDuration {
    return MapService.formatDuration(durationSeconds);
  }
}

class MapService {
  const MapService();

  // Location & permissions
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Stream<Position> positionStream({LocationAccuracy accuracy = LocationAccuracy.high, int distanceFilter = 1}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter),
    );
  }

  // Autocomplete suggestions from OpenRouteService
  Future<List<Map<String, dynamic>>> fetchAutocompleteSuggestions(
    String query, {
    double focusLat = 13.024097,
    double focusLon = 77.636558,
    double boundaryRadiusKm = 50,
  }) async {
    final apiKey = Config.openRouteServiceApiKey;
    if (apiKey.isEmpty) return [];

    final uri = Uri.parse(
      'https://api.openrouteservice.org/geocode/autocomplete?'
      'api_key=$apiKey&'
      'text=${Uri.encodeComponent(query)}&'
      'size=8&'
      'layers=venue,address,street,locality,region,country&'
      'focus.point.lon=$focusLon&'
      'focus.point.lat=$focusLat&'
      'boundary.circle.lon=$focusLon&'
      'boundary.circle.lat=$focusLat&'
      'boundary.circle.radius=$boundaryRadiusKm',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

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
    return suggestions;
  }

  // Geocode a text query
  Future<LatLng?> geocodeLocation(String query) async {
    final apiKey = Config.openRouteServiceApiKey;
    if (apiKey.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      'https://api.openrouteservice.org/geocode/search?'
      'api_key=$apiKey&'
      'text=${Uri.encodeComponent(query)}&'
      'size=5&'
      'layers=venue,address,street,locality,region,country&'
      'focus.point.lon=77.636558&'
      'focus.point.lat=13.024097&'
      'boundary.circle.lon=77.636558&'
      'boundary.circle.lat=13.024097&'
      'boundary.circle.radius=100',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['features'] == null || data['features'].isEmpty) return null;
    final feature = data['features'][0];
    final coordinates = feature['geometry']['coordinates'];
    return LatLng(coordinates[1], coordinates[0]);
  }

  // Calculate route via ORS
  Future<MapRouteResult> calculateRoute(LatLng from, LatLng to) async {
    final apiKey = Config.openRouteServiceApiKey;
    if (apiKey.isEmpty) {
      throw Exception('OpenRouteService API key not configured');
    }

    final url =
        '${Config.openRouteServiceBaseUrl}/v2/directions/driving-car?'
        'api_key=$apiKey&'
        'start=${from.longitude},${from.latitude}&'
        'end=${to.longitude},${to.latitude}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Route API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['features'] == null || data['features'].isEmpty) {
      throw Exception('No route found');
    }

    final route = data['features'][0];
    final coordinates = route['geometry']['coordinates'] as List;
    final summary = route['properties']['summary'];

    final points = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
    final totalDistanceKm = (summary['distance'] as num).toDouble() / 1000.0;
    final durationSeconds = (summary['duration'] as num).toDouble();

    return MapRouteResult(points: points, totalDistanceKm: totalDistanceKm, durationSeconds: durationSeconds);
  }

  // Bounds for a set of points
  LatLngBounds boundsForRoute(List<LatLng> points) {
    final minLat = points.map((p) => p.latitude).reduce(min);
    final maxLat = points.map((p) => p.latitude).reduce(max);
    final minLng = points.map((p) => p.longitude).reduce(min);
    final maxLng = points.map((p) => p.longitude).reduce(max);
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  static String formatDuration(double seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
