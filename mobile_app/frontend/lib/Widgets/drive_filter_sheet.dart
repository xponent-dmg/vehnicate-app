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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Duration (mins)",
                        style: _FilterSheetConstants.subtitleStyle,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAdjustmentButton(
                            icon: Icons.remove,
                            onPressed: () {
                              setState(() {
                                final newStart = (_tempDuration.start - 1).clamp(0, _tempDuration.end).toDouble();
                                _tempDuration = RangeValues(newStart, _tempDuration.end);
                              });
                            },
                          ),
                          _PrecisionTextField(
                            value: _tempDuration.start.toInt(),
                            onChanged: (val) {
                              setState(() {
                                final newStart = val.toDouble().clamp(0, _tempDuration.end).toDouble();
                                _tempDuration = RangeValues(newStart, _tempDuration.end);
                              });
                            },
                            min: 0,
                            max: 600,
                          ),
                          _buildAdjustmentButton(
                            icon: Icons.add,
                            onPressed: () {
                              setState(() {
                                final newStart = (_tempDuration.start + 1).clamp(0, _tempDuration.end).toDouble();
                                _tempDuration = RangeValues(newStart, _tempDuration.end);
                              });
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text("to", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ),
                          _buildAdjustmentButton(
                            icon: Icons.remove,
                            onPressed: () {
                              setState(() {
                                final newEnd = (_tempDuration.end - 1).clamp(_tempDuration.start, 600).toDouble();
                                _tempDuration = RangeValues(_tempDuration.start, newEnd);
                              });
                            },
                          ),
                          _PrecisionTextField(
                            value: _tempDuration.end.toInt(),
                            onChanged: (val) {
                              setState(() {
                                final newEnd = val.toDouble().clamp(_tempDuration.start, 600).toDouble();
                                _tempDuration = RangeValues(_tempDuration.start, newEnd);
                              });
                            },
                            min: 0,
                            max: 600,
                          ),
                          _buildAdjustmentButton(
                            icon: Icons.add,
                            onPressed: () {
                              setState(() {
                                final newEnd = (_tempDuration.end + 1).clamp(_tempDuration.start, 600).toDouble();
                                _tempDuration = RangeValues(_tempDuration.start, newEnd);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Distance (km)",
                        style: _FilterSheetConstants.subtitleStyle,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAdjustmentButton(
                            icon: Icons.remove,
                            onPressed: () {
                              setState(() {
                                final newStart = (_tempDistance.start - 1).clamp(0, _tempDistance.end).toDouble();
                                _tempDistance = RangeValues(newStart, _tempDistance.end);
                              });
                            },
                          ),
                          _PrecisionTextField(
                            value: _tempDistance.start.toInt(),
                            onChanged: (val) {
                              setState(() {
                                final newStart = val.toDouble().clamp(0, _tempDistance.end).toDouble();
                                _tempDistance = RangeValues(newStart, _tempDistance.end);
                              });
                            },
                            min: 0,
                            max: 2000,
                          ),
                          _buildAdjustmentButton(
                            icon: Icons.add,
                            onPressed: () {
                              setState(() {
                                final newStart = (_tempDistance.start + 1).clamp(0, _tempDistance.end).toDouble();
                                _tempDistance = RangeValues(newStart, _tempDistance.end);
                              });
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text("to", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ),
                          _buildAdjustmentButton(
                            icon: Icons.remove,
                            onPressed: () {
                              setState(() {
                                final newEnd = (_tempDistance.end - 1).clamp(_tempDistance.start, 2000).toDouble();
                                _tempDistance = RangeValues(_tempDistance.start, newEnd);
                              });
                            },
                          ),
                          _PrecisionTextField(
                            value: _tempDistance.end.toInt(),
                            onChanged: (val) {
                              setState(() {
                                final newEnd = val.toDouble().clamp(_tempDistance.start, 2000).toDouble();
                                _tempDistance = RangeValues(_tempDistance.start, newEnd);
                              });
                            },
                            min: 0,
                            max: 2000,
                          ),
                          _buildAdjustmentButton(
                            icon: Icons.add,
                            onPressed: () {
                              setState(() {
                                final newEnd = (_tempDistance.end + 1).clamp(_tempDistance.start, 2000).toDouble();
                                _tempDistance = RangeValues(_tempDistance.start, newEnd);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
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
                            if (time != null) {
                              setState(() => _tempStartTime = time);
                            }
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
                            if (time != null) {
                              setState(() => _tempEndTime = time);
                            }
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

  Widget _buildAdjustmentButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _PrecisionTextField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const _PrecisionTextField({
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  State<_PrecisionTextField> createState() => _PrecisionTextFieldState();
}

class _PrecisionTextFieldState extends State<_PrecisionTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _PrecisionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitValue();
    }
  }

  void _submitValue() {
    final val = int.tryParse(_controller.text);
    if (val != null) {
      final clamped = val.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toString();
    } else {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            isDense: true,
          ),
          onSubmitted: (_) => _submitValue(),
        ),
      ),
    );
  }
}
