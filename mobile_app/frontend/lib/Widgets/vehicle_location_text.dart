import 'package:flutter/material.dart';
import 'package:vehnway/services/supabase_service.dart';
import 'package:vehnway/services/geocoding_service.dart';

class VehicleLocationText extends StatefulWidget {
  final int vehicleId;
  final TextStyle? style;
  final String prefix;

  const VehicleLocationText({
    super.key,
    required this.vehicleId,
    this.style,
    this.prefix = '',
  });

  @override
  State<VehicleLocationText> createState() => _VehicleLocationTextState();
}

class _VehicleLocationTextState extends State<VehicleLocationText> {
  String _resolvedLocation = 'Loading location...';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void didUpdateWidget(VehicleLocationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleId != widget.vehicleId) {
      _loadLocation();
    }
  }

  Future<void> _loadLocation() async {
    try {
      final coords = await SupabaseService().getLastKnownLocation(widget.vehicleId);
      if (coords == null) {
        if (mounted) {
          setState(() {
            _resolvedLocation = 'Unknown Location';
          });
        }
        return;
      }
      final resolved = await GeocodingService().getReadableLocation(
        coords['latitude']!,
        coords['longitude']!,
      );
      if (mounted) {
        setState(() {
          _resolvedLocation = resolved;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedLocation = 'Unknown Location';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textToShow = widget.prefix.isNotEmpty ? '${widget.prefix}$_resolvedLocation' : _resolvedLocation;
    return Text(
      textToShow,
      style: widget.style,
      overflow: TextOverflow.ellipsis,
    );
  }
}
