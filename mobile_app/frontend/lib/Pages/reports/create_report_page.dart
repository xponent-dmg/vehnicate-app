import 'dart:io';

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
import 'package:vehnway/services/map_service.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';
import 'package:vehnway/Pages/reports/widgets/report_location_picker_dialog.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _service = RoadReportService();
  final _mapService = const MapService();
  final _imagePicker = ImagePicker();
  final _descriptionController = TextEditingController();

  RoadReportCategory? _selectedCategory;
  RoadReportSeverity? _selectedSeverity;
  final List<File> _selectedImages = [];

  LatLng? _issueLocation;
  double? _locationAccuracy;
  bool _isManuallyAdjusted = false;
  bool _isDetectingLocation = false;
  String? _locationError;

  bool _isSubmitting = false;
  double _submissionProgress = 0.0;

  static const int _maxImages = 3;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10 MB

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _mapService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _issueLocation = LatLng(position.latitude, position.longitude);
          _locationAccuracy = position.accuracy;
          _isManuallyAdjusted = false;
          _isDetectingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString().replaceFirst('Exception: ', '');
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      CustomSnackBar.showWarning(
        context,
        'Maximum $_maxImages photographs allowed.',
      );
      return;
    }

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (picked != null) {
        final file = File(picked.path);
        final size = await file.length();
        if (size > _maxFileSize) {
          if (mounted) {
            CustomSnackBar.showWarning(
              context,
              'Selected photo exceeds the 10MB limit.',
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            _selectedImages.add(file);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to capture/select image: $e');
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Photo Evidence',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Take Photograph',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.lightPurple,
                    ),
                    title: const Text(
                      'Choose from Gallery',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _adjustLocationOnMap() async {
    final initial =
        _issueLocation ??
        LatLng(Config.defaultLatitude, Config.defaultLongitude);
    final adjusted = await ReportLocationPickerDialog.show(context, initial);

    if (adjusted != null && mounted) {
      setState(() {
        _issueLocation = adjusted;
        _isManuallyAdjusted = true;
        _locationError = null;
      });
    }
  }

  bool get _isFormValid {
    return _selectedCategory != null &&
        _selectedImages.isNotEmpty &&
        _issueLocation != null &&
        !_isSubmitting;
  }

  Future<void> _submitReport() async {
    if (!_isFormValid) return;

    setState(() {
      _isSubmitting = true;
      _submissionProgress = 0.05;
    });

    try {
      final newReport = await _service.createRoadReport(
        category: _selectedCategory!,
        latitude: _issueLocation!.latitude,
        longitude: _issueLocation!.longitude,
        locationAccuracy: _locationAccuracy,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        imageFiles: _selectedImages,
        onProgress: (p) => setState(() => _submissionProgress = p),
      );

      if (mounted) {
        context.read<RoadReportProvider>().onReportCreated(newReport);
        CustomSnackBar.showSuccess(
          context,
          'Road issue reported successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        CustomSnackBar.showError(
          context,
          'Failed to submit report: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Safety Stopped Reminder Banner
                // _buildSafetyReminderBanner(),
                const SizedBox(height: 16),

                // Section 1: Issue Category (3 categories in a row)
                _buildCategorySection(),
                const SizedBox(height: 24),

                // Section 2: Photo Evidence and Issue Location – SIDE BY SIDE
                _buildSideBySideCards(),
                const SizedBox(height: 24),

                // Section 3: Severity (Optional segmented selector)
                _buildSeveritySection(),
                const SizedBox(height: 24),

                // Section 4: Description (Optional multiline)
                _buildDescriptionSection(),
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Submitting Overlay
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value:
                            _submissionProgress > 0
                                ? _submissionProgress
                                : null,
                        color: AppColors.primary,
                        backgroundColor: Colors.white12,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Submitting Report... ${(_submissionProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget _buildSafetyReminderBanner() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: AppColors.warning.withOpacity(0.12),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.warning.withOpacity(0.35)),
  //     ),
  //     child: const Row(
  //       children: [
  //         Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
  //         SizedBox(width: 10),
  //         Expanded(
  //           child: Text(
  //             'Drive Safely: Only report or take photographs when your vehicle is safely stopped.',
  //             style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Issue Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: RoadReportCategory.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 categories in a row
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.1, // smaller container height (~50px)
          ),
          itemBuilder: (context, index) {
            final cat = RoadReportCategory.values[index];
            final isSelected = _selectedCategory == cat;
            final isOther = cat == RoadReportCategory.other;

            return InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white10,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child:
                    isOther
                        ? Text(
                          '...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        )
                        : Text(
                          cat.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: isSelected ? 11 : 10,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSideBySideCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPhotoEvidenceCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildLocationCard()),
      ],
    );
  }

  Widget _buildPhotoEvidenceCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _selectedImages.isEmpty
                  ? Colors.white10
                  : AppColors.primary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Add Photo',
                onPressed:
                    _selectedImages.length < _maxImages
                        ? _showImageSourceSheet
                        : null,
              ),
            ],
          ),
          Text(
            '${_selectedImages.length}/$_maxImages attached',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Attached Image Previews or Add Action
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[idx],
                          width: 75,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedImages.removeAt(idx));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white38,
                      size: 26,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to add photo\n(1 to 3 photos)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _issueLocation == null
                  ? Colors.white10
                  : AppColors.primary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.lightPurple,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Adjust Location',
                onPressed: _adjustLocationOnMap,
              ),
            ],
          ),
          Text(
            _isManuallyAdjusted
                ? 'Manually Adjusted'
                : _locationAccuracy != null
                ? 'GPS ±${_locationAccuracy!.round()}m'
                : 'Current Location',
            style: TextStyle(
              color: _isManuallyAdjusted ? AppColors.warning : Colors.white54,
              fontSize: 11,
              fontWeight:
                  _isManuallyAdjusted ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Mini Map Preview or Loading
          GestureDetector(
            onTap: _adjustLocationOnMap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 90,
                color: Colors.black26,
                child:
                    _issueLocation != null
                        ? Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _issueLocation!,
                                initialZoom: 16.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: Config.cartoVoyagerUrl,
                                  userAgentPackageName: 'com.vehnicate.app',
                                ),
                              ],
                            ),
                            const Center(
                              child: Icon(
                                Icons.location_pin,
                                color: AppColors.error,
                                size: 28,
                              ),
                            ),
                          ],
                        )
                        : Center(
                          child:
                              _isDetectingLocation
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                  : Text(
                                    _locationError ?? 'Location unavailable',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Severity (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children:
              RoadReportSeverity.values.map((sev) {
                final isSelected = _selectedSeverity == sev;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSeverity = isSelected ? null : sev;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? sev.color.withOpacity(0.25)
                                  : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? sev.color : Colors.white12,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          sev.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Description (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          maxLength: 500,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'e.g., Deep pothole on right lane after turn, dangerous at night...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: AppColors.surface,
            counterStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final valid = _isFormValid;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: valid ? _submitReport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.white12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: valid ? 3 : 0,
        ),
        child: const Text(
          'Submit Road Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
