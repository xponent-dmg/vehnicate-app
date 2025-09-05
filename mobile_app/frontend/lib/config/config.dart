import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // OpenRouteService API Configuration
  // Reads from .env file: OPEN_MAPS_API_KEY
  static String get openRouteServiceApiKey => dotenv.env['OPEN_MAPS_API_KEY'] ?? '';
  
  // OpenRouteService API Base URL
  static const String openRouteServiceBaseUrl = 'https://api.openrouteservice.org';
  
  // Default map center (you can change this to your preferred location)
  static const double defaultLatitude = 37.7749;  // San Francisco coordinates
  static const double defaultLongitude = -122.4194;
  
  // Map configuration
  static const double defaultZoom = 15.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 3.0;
}
