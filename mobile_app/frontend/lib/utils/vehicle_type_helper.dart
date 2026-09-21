import 'package:flutter/material.dart';

class VehicleTypeHelper {
  static const List<String> types = [
    'sedan',
    'hatchback',
    'suv',
    'bike',
    'scooty',
    'auto',
    '6 wheeler',
    '8 wheeler',
  ];

  static String formatName(String type) {
    switch (type.toLowerCase()) {
      case 'suv':
        return 'SUV';
      case 'sedan':
        return 'Sedan';
      case 'hatchback':
        return 'Hatchback';
      case 'bike':
        return 'Bike';
      case 'scooty':
        return 'Scooty';
      case 'auto':
        return 'Auto';
      case '6 wheeler':
        return '6 Wheeler';
      case '8 wheeler':
        return '8 Wheeler';
      default:
        return type.isEmpty ? type : '${type[0].toUpperCase()}${type.substring(1)}';
    }
  }

  static IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sedan':
        return Icons.directions_car_rounded;
      case 'hatchback':
        return Icons.directions_car_filled_rounded;
      case 'suv':
        return Icons.directions_car_rounded;
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'scooty':
        return Icons.moped_rounded;
      case 'auto':
        return Icons.electric_rickshaw_rounded;
      case '6 wheeler':
      case '8 wheeler':
        return Icons.local_shipping_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }
}
