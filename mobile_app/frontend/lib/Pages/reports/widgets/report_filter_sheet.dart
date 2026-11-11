import 'package:flutter/material.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/road_report_model.dart';

class ReportFilterSheet extends StatefulWidget {
  final RoadReportCategory? initialCategory;
  final RoadReportStatus? initialStatus;
  final double initialRadiusMeters;
  final Function(RoadReportCategory? category, RoadReportStatus? status, double radiusMeters) onApply;

  const ReportFilterSheet({
    super.key,
    required this.initialCategory,
    required this.initialStatus,
    required this.initialRadiusMeters,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required RoadReportCategory? initialCategory,
    required RoadReportStatus? initialStatus,
    required double initialRadiusMeters,
    required Function(RoadReportCategory? category, RoadReportStatus? status, double radiusMeters) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportFilterSheet(
        initialCategory: initialCategory,
        initialStatus: initialStatus,
        initialRadiusMeters: initialRadiusMeters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late RoadReportCategory? _selectedCategory;
  late RoadReportStatus? _selectedStatus;
  late double _selectedRadiusMeters;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedStatus = widget.initialStatus;
    _selectedRadiusMeters = widget.initialRadiusMeters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedStatus = null;
                    _selectedRadiusMeters = 2000.0;
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.divider),

          // Radius filter
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Radius',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_selectedRadiusMeters / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppColors.lightPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _selectedRadiusMeters,
            min: 500,
            max: 10000,
            divisions: 19,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surface,
            onChanged: (val) {
              setState(() => _selectedRadiusMeters = val);
            },
          ),
          const SizedBox(height: 12),

          // Category filter
          const Text(
            'Issue Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'All Categories',
                isSelected: _selectedCategory == null,
                onSelected: () => setState(() => _selectedCategory = null),
              ),
              ...RoadReportCategory.values.map(
                (cat) => _buildFilterChip(
                  label: cat.label,
                  icon: cat.icon,
                  isSelected: _selectedCategory == cat,
                  onSelected: () => setState(() => _selectedCategory = cat),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status filter
          const Text(
            'Report Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'All Statuses',
                isSelected: _selectedStatus == null,
                onSelected: () => setState(() => _selectedStatus = null),
              ),
              ...RoadReportStatus.values
                  .where((s) => s != RoadReportStatus.archived)
                  .map(
                    (st) => _buildFilterChip(
                      label: st.label,
                      color: st.color,
                      isSelected: _selectedStatus == st,
                      onSelected: () => setState(() => _selectedStatus = st),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCategory, _selectedStatus, _selectedRadiusMeters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : Colors.white70,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

