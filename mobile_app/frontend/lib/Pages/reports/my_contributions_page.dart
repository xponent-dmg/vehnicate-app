import 'package:flutter/material.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/page_transitions.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';
import 'package:vehnway/Pages/reports/all_contributions_page.dart';
import 'package:vehnway/Pages/reports/report_details_page.dart';

class MyContributionsPage extends StatefulWidget {
  const MyContributionsPage({super.key});

  @override
  State<MyContributionsPage> createState() => _MyContributionsPageState();
}

class _MyContributionsPageState extends State<MyContributionsPage> {
  final _service = RoadReportService();

  UserContributionStats? _stats;
  bool _isLoadingStats = true;

  ContributionActivityType? _selectedActivityFilter;
  List<ContributionActivity> _recentActivities = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadStats(),
      _loadRecentActivities(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await _service.getUserContributionStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    setState(() => _isLoadingRecent = true);
    final activities = await _service.getUserContributionActivities(
      activityFilter: _selectedActivityFilter,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      limit: 5,
      offset: 0,
    );

    if (mounted) {
      setState(() {
        _recentActivities = activities;
        _isLoadingRecent = false;
      });
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
          'My Contributions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section A: Statistics Cards (Clean typography, no icons)
              _buildStatisticsCards(),
              const SizedBox(height: 20),

              // Section B: Activity Type Filter (All, Reported, Verified)
              _buildActivityTypeFilter(),
              const SizedBox(height: 24),

              // Section C: Recent Records (Last 7 Days) with View All
              _buildRecentRecordsHeader(),
              const SizedBox(height: 12),
              _buildRecentRecordsList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        // Issues Reported Card (Clean typography, no icons)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingStats
                    ? const SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                      )
                    : Text(
                        '${_stats?.reportedCount ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 4),
                const Text(
                  'Issues Reported',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Issues Verified Card (Clean typography, no icons)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingStats
                    ? const SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                      )
                    : Text(
                        '${_stats?.verifiedCount ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 4),
                const Text(
                  'Issues Verified',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTypeFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentTab(label: 'All Activity', value: null),
          _buildSegmentTab(label: 'Reported', value: ContributionActivityType.reported),
          _buildSegmentTab(label: 'Verified', value: ContributionActivityType.verified),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required ContributionActivityType? value,
  }) {
    final isSelected = _selectedActivityFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectedActivityFilter != value) {
            setState(() => _selectedActivityFilter = value);
            _loadRecentActivities();
          }
        },
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecordsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Activity (Last 7 Days)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              PageTransitions.slideFromRight(
                AllContributionsPage(
                  initialActivityFilter: _selectedActivityFilter,
                ),
              ),
            );
          },
          child: const Row(
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.lightPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: AppColors.lightPurple, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecordsList() {
    if (_isLoadingRecent) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_recentActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: const [
            Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.white30),
            SizedBox(height: 8),
            Text(
              'No activity in the last 7 days',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentActivities.map((act) => _buildActivityItem(act)).toList(),
    );
  }

  Widget _buildActivityItem(ContributionActivity act) {
    final isReported = act.activityType == ContributionActivityType.reported;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isReported ? AppColors.primary.withOpacity(0.18) : AppColors.accent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            act.category.icon,
            color: isReported ? AppColors.lightPurple : AppColors.accent,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                act.category.label,
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
                act.activityType.label,
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
                act.formattedDate,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: act.reportStatus.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  act.reportStatus.label,
                  style: TextStyle(
                    color: act.reportStatus.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          final rep = await _service.getReportById(act.reportId);
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
}
