import 'package:flutter/material.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/page_transitions.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';
import 'package:vehnway/Pages/reports/report_details_page.dart';

class AllContributionsPage extends StatefulWidget {
  final ContributionActivityType? initialActivityFilter;
  final RoadReportCategory? initialCategoryFilter;

  const AllContributionsPage({
    super.key,
    this.initialActivityFilter,
    this.initialCategoryFilter,
  });

  @override
  State<AllContributionsPage> createState() => _AllContributionsPageState();
}

class _AllContributionsPageState extends State<AllContributionsPage> {
  final _service = RoadReportService();
  final ScrollController _scrollController = ScrollController();

  late ContributionActivityType? _activityFilter;
  late RoadReportCategory? _categoryFilter;
  String _dateFilter = 'all'; // 'all', '7d', '30d'

  final List<ContributionActivity> _activities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _activityFilter = widget.initialActivityFilter;
    _categoryFilter = widget.initialCategoryFilter;
    _loadActivities(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadActivities(refresh: false);
    }
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    if (_dateFilter == '7d') return now.subtract(const Duration(days: 7));
    if (_dateFilter == '30d') return now.subtract(const Duration(days: 30));
    return null;
  }

  Future<void> _loadActivities({required bool refresh}) async {
    if (_isLoading) return;
    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    try {
      final newItems = await _service.getUserContributionActivities(
        activityFilter: _activityFilter,
        categoryFilter: _categoryFilter,
        startDate: _getStartDate(),
        limit: _pageSize,
        offset: _offset,
      );

      setState(() {
        if (refresh) {
          _activities.clear();
        }
        _activities.addAll(newItems);
        _offset += newItems.length;
        if (newItems.length < _pageSize) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Contributions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter bars
          _buildFilterBar(),

          // Activity List
          Expanded(
            child: _activities.isEmpty && !_isLoading
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _loadActivities(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _activities.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx == _activities.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        }
                        return _buildActivityTile(_activities[idx]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Type filter (All, Reported, Verified)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSegmentButton(label: 'All', value: null),
                _buildSegmentButton(label: 'Reported', value: ContributionActivityType.reported),
                _buildSegmentButton(label: 'Verified', value: ContributionActivityType.verified),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Date and Category chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip(label: 'All Time', value: 'all'),
                const SizedBox(width: 8),
                _buildDateChip(label: 'Last 7 Days', value: '7d'),
                const SizedBox(width: 8),
                _buildDateChip(label: 'Last 30 Days', value: '30d'),
                const SizedBox(width: 10),

                // Category Dropdown Filter Chip
                PopupMenuButton<RoadReportCategory?>(
                  initialValue: _categoryFilter,
                  color: AppColors.surface,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  tooltip: 'Filter by Category',
                  onSelected: (cat) {
                    setState(() => _categoryFilter = cat);
                    _loadActivities(refresh: true);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<RoadReportCategory?>(
                      value: null,
                      child: Text('All Categories', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    ...RoadReportCategory.values.map(
                      (c) => PopupMenuItem<RoadReportCategory?>(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(c.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _categoryFilter != null
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _categoryFilter != null ? AppColors.primary : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categoryFilter == null ? 'Category: All' : _categoryFilter!.label,
                          style: TextStyle(
                            color: _categoryFilter != null ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: _categoryFilter != null ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                      ],
                    ),
                  ),
                ),

                if (_categoryFilter != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => _categoryFilter = null);
                      _loadActivities(refresh: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 12, color: Colors.white70),
                          SizedBox(width: 2),
                          Text(
                            'Clear',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required ContributionActivityType? value,
  }) {
    final isSelected = _activityFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_activityFilter != value) {
            setState(() => _activityFilter = value);
            _loadActivities(refresh: true);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip({required String label, required String value}) {
    final isSelected = _dateFilter == value;

    return InkWell(
      onTap: () {
        if (_dateFilter != value) {
          setState(() => _dateFilter = value);
          _loadActivities(refresh: true);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPurple.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.lightPurple : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(ContributionActivity activity) {
    final isReported = activity.activityType == ContributionActivityType.reported;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkGreyBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isReported ? AppColors.primary.withOpacity(0.18) : AppColors.accent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            activity.category.icon,
            color: isReported ? AppColors.lightPurple : AppColors.accent,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                activity.category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isReported ? AppColors.primary.withOpacity(0.2) : AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activity.activityType.label,
                style: TextStyle(
                  color: isReported ? AppColors.lightPurple : AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                activity.formattedDate,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activity.reportStatus.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activity.reportStatus.label,
                  style: TextStyle(
                    color: activity.reportStatus.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          final rep = await _service.getReportById(activity.reportId);
          if (rep != null && mounted) {
            Navigator.push(
              context,
              PageTransitions.fadeSlideUp(ReportDetailsPage(report: rep)),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_rounded, size: 56, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'No contributions match the filters',
            style: TextStyle(color: Colors.white60, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

