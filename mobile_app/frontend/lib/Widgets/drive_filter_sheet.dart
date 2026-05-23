import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

// Use local constants for the filter sheet to maintain modularity
class _FilterSheetConstants {
  static const titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

class DriveFilterSheet extends StatefulWidget {
  final int? initialVehicleId;
  final DateTime? initialDate;
  final RangeValues initialDuration;
  final RangeValues initialDistance;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final Function({
    int? vehicleId,
    DateTime? date,
    RangeValues? duration,
    RangeValues? distance,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  })
  onApply;

  const DriveFilterSheet({
    super.key,
    this.initialVehicleId,
    this.initialDate,
    required this.initialDuration,
    required this.initialDistance,
    this.initialStartTime,
    this.initialEndTime,
    required this.onApply,
  });

  @override
  State<DriveFilterSheet> createState() => _DriveFilterSheetState();
}

class _DriveFilterSheetState extends State<DriveFilterSheet> {
  int? _tempVehicleId;
  DateTime? _tempDate;
  late RangeValues _tempDuration;
  late RangeValues _tempDistance;
  TimeOfDay? _tempStartTime;
  TimeOfDay? _tempEndTime;

  @override
  void initState() {
    super.initState();
    _tempVehicleId = widget.initialVehicleId;
    _tempDate = widget.initialDate;
    _tempDuration = widget.initialDuration;
    _tempDistance = widget.initialDistance;
    _tempStartTime = widget.initialStartTime;
    _tempEndTime = widget.initialEndTime;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(
      context,
      listen: false,
    );
    final vehicles = vehicleProvider.vehicles;

    return GlassLiteContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      backgroundColor: AppColors.darkBackground,
      hasBorder: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: _FilterSheetConstants.titleStyle,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _tempVehicleId = null;
                            _tempDate = null;
                            _tempDuration = const RangeValues(0, 600);
                            _tempDistance = const RangeValues(0, 2000);
                            _tempStartTime = null;
                            _tempEndTime = null;
                          });
                        },
                        child: Text(
                          "Reset",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Select Vehicle",
                    style: _FilterSheetConstants.subtitleStyle,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        vehicles.map((vehicle) {
                          final isSelected = _tempVehicleId == vehicle.id;
                          return FilterChip(
                            label: Text(vehicle.model),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _tempVehicleId = selected ? vehicle.id : null;
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            checkmarkColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.white70,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Date",
                      style: _FilterSheetConstants.subtitleStyle,
                    ),
                    subtitle: Text(
                      _tempDate != null
                          ? DateFormat('dd MMM yyyy').format(_tempDate!)
                          : "Any date",
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.date_range,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _tempDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _tempDate = date);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  // Duration Range
                  Text(
                    "Duration (mins): ${_tempDuration.start.toInt()} - ${_tempDuration.end.toInt()}",
                    style: _FilterSheetConstants.subtitleStyle,
                  ),
                  RangeSlider(
                    values: _tempDuration,
                    min: 0,
                    max: 600,
                    divisions: 600,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (RangeValues values) {
                      setState(() => _tempDuration = values);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  // Distance Range
                  Text(
                    "Distance (km): ${_tempDistance.start.toInt()} - ${_tempDistance.end.toInt()}",
                    style: _FilterSheetConstants.subtitleStyle,
                  ),
                  RangeSlider(
                    values: _tempDistance,
                    min: 0,
                    max: 2000,
                    divisions: 200,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (RangeValues values) {
                      setState(() => _tempDistance = values);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  // Time filter
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "From Time",
                            style: _FilterSheetConstants.subtitleStyle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _tempStartTime != null
                                ? _tempStartTime!.format(context)
                                : "Any",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _tempStartTime ?? TimeOfDay.now(),
                            );
                            if (time != null)
                              setState(() => _tempStartTime = time);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "To Time",
                            style: _FilterSheetConstants.subtitleStyle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _tempEndTime != null
                                ? _tempEndTime!.format(context)
                                : "Any",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _tempEndTime ?? TimeOfDay.now(),
                            );
                            if (time != null)
                              setState(() => _tempEndTime = time);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onApply(
                  vehicleId: _tempVehicleId,
                  date: _tempDate,
                  duration: _tempDuration,
                  distance: _tempDistance,
                  startTime: _tempStartTime,
                  endTime: _tempEndTime,
                );
                Navigator.pop(context);
              },
              child: const Text(
                "Apply Filters",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
