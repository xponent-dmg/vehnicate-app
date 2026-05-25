import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehnway/utils/app_logger.dart';
import 'package:vehnway/services/cache_service.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  // In-memory cache of active futures to prevent duplicate concurrent calls for the same coordinates.
  // This ensures that during widget rebuilds or simultaneous requests, the network API is only called once.
  final Map<String, Future<String>> _pendingRequests = {};

  /// Resolves the readable location for a given latitude and longitude.
  /// First checks the Hive metadata cache. On a cache miss, checks if there is already
  /// an ongoing network request for the rounded coordinates, otherwise makes the API call.
  Future<String> getReadableLocation(double latitude, double longitude) async {
    // Round latitude and longitude to 3 decimal places.
    // As per requirement: "only lookup coordinates upto 3 decimal points, everything related to reverse geocoding should be done with 3 decimal precision".
    // 3 decimal places provide a resolution of approximately 110 meters.
    // This is perfect for vehicle location tracking because:
    // 1. It filters out minor GPS satellite drift or sensor noise when a vehicle is parked.
    // 2. It aggressively increases Hive cache hits, preventing redundant, expensive geocoding API calls.
    // 3. It groups nearby location requests together to conserve user API limits and device battery.
    final double roundedLat = double.parse(latitude.toStringAsFixed(3));
    final double roundedLng = double.parse(longitude.toStringAsFixed(3));
    final String cacheKey = 'geo_${roundedLat.toStringAsFixed(3)}_${roundedLng.toStringAsFixed(3)}';

    // 1. Check cache first
    try {
      final box = Hive.box(CacheService.boxMetadata);
      final String? cachedLoc = box.get(cacheKey) as String?;
      if (cachedLoc != null && cachedLoc.isNotEmpty) {
        return cachedLoc;
      }
    } catch (e, stack) {
      AppLogger.warning('Error reading from Hive cache for key $cacheKey', e, stack);
    }

    // 2. Check/deduplicate active network requests
    final pending = _pendingRequests[cacheKey];
    if (pending != null) {
      AppLogger.info('Deduplicating geocoding API request for cache key: $cacheKey');
      return pending;
    }

    // 3. Initiate the request and track its Future
    final Future<String> requestFuture = _fetchFromApi(roundedLat, roundedLng, cacheKey);
    _pendingRequests[cacheKey] = requestFuture;

    try {
      final resolvedLocation = await requestFuture;
      return resolvedLocation;
    } finally {
      // Remove from pending list once completed
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<String> _fetchFromApi(double latitude, double longitude, String cacheKey) async {
    try {
      // Accessing via dotenv.env prevents AssertionErrors when key isn't hot-reloaded yet or is asynchronously loaded.
      final apiKey = dotenv.env['BIGDATACLOUD_API_KEY'] ?? '';
      
      final Uri uri;
      if (apiKey.isNotEmpty) {
        uri = Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode'
            '?latitude=$latitude&longitude=$longitude&localityLanguage=en&key=$apiKey');
      } else {
        uri = Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client'
            '?latitude=$latitude&longitude=$longitude&localityLanguage=en');
      }

      AppLogger.info('Calling BigDataCloud Reverse Geocoding API: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw HttpException('BigDataCloud API returned HTTP status ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;

      final String? locality = data['locality'] as String?;
      final String? city = data['city'] as String?;
      final String? state = data['principalSubdivision'] as String?;

      String resolved = 'Unknown Location';

      if (locality != null && locality.isNotEmpty && city != null && city.isNotEmpty) {
        if (locality.trim().toLowerCase() == city.trim().toLowerCase()) {
          resolved = city;
        } else {
          resolved = '$locality, $city';
        }
      } else if (city != null && city.isNotEmpty) {
        if (state != null && state.isNotEmpty) {
          resolved = '$city, $state';
        } else {
          resolved = city;
        }
      } else if (state != null && state.isNotEmpty) {
        resolved = state;
      }

      // Save valid locations to cache
      if (resolved != 'Unknown Location') {
        try {
          final box = Hive.box(CacheService.boxMetadata);
          await box.put(cacheKey, resolved);
          AppLogger.info('Cached geocoding result for $cacheKey: $resolved');
        } catch (e, stack) {
          AppLogger.warning('Failed to save to Hive cache', e, stack);
        }
      }

      return resolved;
    } on SocketException catch (e, stack) {
      AppLogger.warning('No internet connection during reverse geocoding', e, stack);
      return 'Unknown Location'; // Soft fallback
    } on TimeoutException catch (e, stack) {
      AppLogger.warning('Reverse geocoding request timed out', e, stack);
      return 'Unknown Location';
    } catch (e, stack) {
      AppLogger.error('Failed to reverse geocode coordinate ($latitude, $longitude)', e, stack);
      return 'Unknown Location';
    }
  }
}
