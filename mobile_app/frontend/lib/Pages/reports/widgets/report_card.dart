import 'package:flutter/material.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';

class ReportCard extends StatefulWidget {
  final RoadReport report;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  String? _signedImageUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(ReportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.report.mediaStoragePaths != oldWidget.report.mediaStoragePaths) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.report.mediaStoragePaths.isEmpty) return;
    final path = widget.report.mediaStoragePaths.first;
    if (_signedImageUrl != null) return;

    if (mounted) setState(() => _isLoadingImage = true);
    final url = await RoadReportService().getSignedImageUrl(path);
    if (mounted) {
      setState(() {
        _signedImageUrl = url;
        _isLoadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkGreyBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail or Icon Container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.surface,
                  child: _signedImageUrl != null
                      ? Image.network(
                          _signedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackIcon(report),
                        )
                      : _isLoadingImage
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : _buildFallbackIcon(report),
                ),
              ),
              const SizedBox(width: 14),

              // Report info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.category.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(report.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (report.distanceMeters != null) ...[
                          const Icon(
                            Icons.near_me_outlined,
                            size: 14,
                            color: AppColors.lightPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.formattedDistance,
                            style: const TextStyle(
                              color: AppColors.lightPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.formattedDate,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (report.severity != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: report.severity!.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${report.severity!.label} Severity',
                              style: TextStyle(
                                color: report.severity!.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (report.totalVerifications > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.how_to_reg_rounded,
                                size: 13,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${report.totalVerifications} verified',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(RoadReport report) {
    return Center(
      child: Icon(
        report.category.icon,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }

  Widget _buildStatusBadge(RoadReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: status.color.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

