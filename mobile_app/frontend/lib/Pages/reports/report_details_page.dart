import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/road_report_provider.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/config/config.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';

class ReportDetailsPage extends StatefulWidget {
  final RoadReport report;

  const ReportDetailsPage({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final _service = RoadReportService();
  final _imagePicker = ImagePicker();
  final _commentController = TextEditingController();

  late RoadReport _report;
  final List<String> _signedImageUrls = [];
  bool _isLoadingImages = false;

  VerificationVerdict? _selectedVerdict;
  File? _evidencePhoto;
  bool _isSubmittingVerification = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _selectedVerdict = widget.report.userVerdict;
    _loadSignedImages();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSignedImages() async {
    if (_report.mediaStoragePaths.isEmpty) return;

    setState(() => _isLoadingImages = true);
    final List<String> urls = [];
    for (final path in _report.mediaStoragePaths) {
      final url = await _service.getSignedImageUrl(path);
      if (url != null) urls.add(url);
    }

    if (mounted) {
      setState(() {
        _signedImageUrls.clear();
        _signedImageUrls.addAll(urls);
        _isLoadingImages = false;
      });
    }
  }

  Future<void> _pickVerificationPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 80,
      );

      if (picked != null && mounted) {
        setState(() => _evidencePhoto = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to pick photo: $e');
      }
    }
  }

  void _showEvidencePhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Supporting Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVerificationPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.lightPurple),
                title: const Text('Select from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVerificationPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (_selectedVerdict == null) {
      CustomSnackBar.showWarning(context, 'Please select a verification verdict.');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_report.userId == currentUserId) {
      CustomSnackBar.showWarning(context, 'You cannot verify your own report.');
      return;
    }

    setState(() => _isSubmittingVerification = true);

    try {
      await _service.submitVerification(
        reportId: _report.id,
        verdict: _selectedVerdict!,
        description: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        evidencePhoto: _evidencePhoto,
      );

      if (mounted) {
        context.read<RoadReportProvider>().onVerificationSubmitted(_report.id);
        CustomSnackBar.showSuccess(context, 'Verification recorded successfully!');
        // Refresh local details
        final updated = await _service.getReportById(_report.id);
        if (updated != null && mounted) {
          setState(() {
            _report = updated;
            _selectedVerdict = updated.userVerdict;
            _evidencePhoto = null;
            _isSubmittingVerification = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingVerification = false);
        CustomSnackBar.showError(
          context,
          'Verification failed: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnReport = _report.isOwnReport || _report.userId == currentUserId;
    final isArchived = _report.status == RoadReportStatus.archived;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _report.category.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _buildStatusChip(_report.status)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photographic Evidence Carousel
            _buildPhotoGallery(),
            const SizedBox(height: 20),

            // Key metadata row (distance, timestamp, severity)
            _buildMetadataRow(),
            const SizedBox(height: 20),

            // Description card (if available)
            if (_report.description != null && _report.description!.isNotEmpty) ...[
              _buildDescriptionCard(),
              const SizedBox(height: 20),
            ],

            // Mini Map with Pin
            _buildMiniMap(),
            const SizedBox(height: 24),

            // Community Verification Summary
            _buildCommunityVerificationSummary(),
            const SizedBox(height: 24),

            // Verification Section
            if (isOwnReport)
              _buildOwnReportBanner()
            else if (isArchived)
              _buildArchivedBanner()
            else
              _buildVerificationCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RoadReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    if (_isLoadingImages) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_signedImageUrls.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_report.category.icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 8),
            const Text(
              'No photo preview available',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 240,
        color: Colors.black38,
        child: PageView.builder(
          itemCount: _signedImageUrls.length,
          itemBuilder: (context, idx) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _signedImageUrls[idx],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(_report.category.icon, size: 48, color: AppColors.primary),
                  ),
                ),
                if (_signedImageUrls.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${idx + 1} / ${_signedImageUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Distance
          Column(
            children: [
              const Icon(Icons.near_me_rounded, color: AppColors.lightPurple, size: 20),
              const SizedBox(height: 4),
              Text(
                _report.distanceMeters != null ? _report.formattedDistance : 'Nearby',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Distance', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Container(width: 1, height: 32, color: Colors.white12),

          // Date
          Column(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 20),
              const SizedBox(height: 4),
              Text(
                _report.formattedDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Reported', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Container(width: 1, height: 32, color: Colors.white12),

          // Severity
          Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _report.severity?.color ?? Colors.white38,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                _report.severity?.label ?? 'None',
                style: TextStyle(
                  color: _report.severity?.color ?? Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Severity', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reporter Description',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _report.description!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    final latLng = LatLng(_report.latitude, _report.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location on Map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: latLng,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: Config.cartoVoyagerUrl,
                      userAgentPackageName: 'com.vehnicate.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latLng,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: _report.status.color,
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityVerificationSummary() {
    final present = _report.verificationCounts['present'] ?? 0;
    final repaired = _report.verificationCounts['repaired'] ?? 0;
    final incorrect = _report.verificationCounts['incorrect'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Verifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_report.totalVerifications} total',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVerdictTally(
                label: 'Still Present',
                count: present,
                color: AppColors.severityHigh,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _buildVerdictTally(
                label: 'Repaired',
                count: repaired,
                color: AppColors.success,
                icon: Icons.build_circle_outlined,
              ),
              const SizedBox(width: 8),
              _buildVerdictTally(
                label: 'Incorrect',
                count: incorrect,
                color: AppColors.error,
                icon: Icons.highlight_off_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictTally({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnReportBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You reported this issue. Verification must be performed by other community members.',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.archive_outlined, color: Colors.white54, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This road report has been archived and is no longer eligible for verification.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGreyBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verify this Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_report.userVerdict != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Previously Verified',
                    style: TextStyle(color: AppColors.lightPurple, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Based on your actual observation, what is the status of this road issue?',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // 3 Mutually exclusive actions
          ...VerificationVerdict.values.map((verdict) {
            final isSelected = _selectedVerdict == verdict;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedVerdict = verdict),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? verdict.color.withOpacity(0.18) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? verdict.color : Colors.white10,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? verdict.color : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Icon(verdict.icon, color: verdict.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          verdict.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),

          // Optional comment
          TextField(
            controller: _commentController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add an observation note (optional)...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Optional evidence photo
          if (_evidencePhoto != null)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_evidencePhoto!, width: 56, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Supporting photo attached',
                    style: TextStyle(color: AppColors.lightPurple, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                  onPressed: () => setState(() => _evidencePhoto = null),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _showEvidencePhotoSourceSheet,
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: const Text('Attach Evidence Photo (Optional)', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          const SizedBox(height: 16),

          // Submit verification button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmittingVerification ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmittingVerification
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _report.userVerdict != null ? 'Update Verification' : 'Submit Verification',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
