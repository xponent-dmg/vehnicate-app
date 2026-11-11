import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vehnway/Pages/profile/constants/profile_constants.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/feedback_model.dart';
import 'package:vehnway/services/supabase/feedback_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _feedbackService = FeedbackService();

  FeedbackCategory _selectedCategory = FeedbackCategory.bugReport;
  final List<File> _attachments = [];
  bool _isSubmitting = false;
  bool _isPicking = false;

  static const int _maxAttachments = 3;
  static const int _minDescriptionLength = 10;
  static const int _maxDescriptionLength = 2000;
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getPlaceholder(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.bugReport:
        return 'Please describe the bug encountered, what you expected to happen, and steps to reproduce...';
      case FeedbackCategory.featureRequest:
        return 'Describe the feature or improvement you would like to see and how it would enhance your experience...';
      case FeedbackCategory.general:
        return 'Share your general comments, suggestions, or thoughts about Vehnicate...';
    }
  }

  Future<void> _pickImages() async {
    if (_attachments.length >= _maxAttachments) {
      CustomSnackBar.showWarning(
        context,
        'You can attach a maximum of $_maxAttachments screenshots.',
      );
      return;
    }

    setState(() => _isPicking = true);
    try {
      final remainingSlots = _maxAttachments - _attachments.length;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> validFiles = [];
        for (final platformFile in result.files) {
          if (validFiles.length >= remainingSlots) break;
          if (platformFile.path == null) continue;

          final file = File(platformFile.path!);
          final size = await file.length();
          if (size > _maxFileSizeBytes) {
            if (mounted) {
              CustomSnackBar.showWarning(
                context,
                '${platformFile.name} exceeds the 10MB limit and was skipped.',
              );
            }
            continue;
          }
          validFiles.add(file);
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _attachments.addAll(validFiles);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to pick images: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final description = _descriptionController.text.trim();
    if (description.length < _minDescriptionLength) {
      CustomSnackBar.showWarning(
        context,
        'Please provide at least $_minDescriptionLength characters in your description.',
      );
      return;
    }

    if (description.length > _maxDescriptionLength) {
      CustomSnackBar.showWarning(
        context,
        'Description cannot exceed $_maxDescriptionLength characters.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _feedbackService.submitFeedback(
        category: _selectedCategory,
        description: description,
        attachments: _attachments,
      );

      if (!mounted) return;

      if (result.isSubmitted) {
        // Feedback record saved successfully!
        if (result.emailDispatched) {
          CustomSnackBar.showSuccess(
            context,
            'Thank you! Your feedback has been submitted successfully.',
          );
        } else {
          CustomSnackBar.showSuccess(
            context,
            'Feedback received! (Notification delivery is processing).',
          );
        }

        // Clear form on successful submission
        setState(() {
          _descriptionController.clear();
          _attachments.clear();
          _selectedCategory = FeedbackCategory.bugReport;
        });

        // Delay briefly and navigate back
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // Retain the entered data so the user does not lose their feedback
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Submission failed: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(gradient: ProfileConstants.gradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProfileConstants.horizontalPadding,
                    vertical: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategorySection(),
                        const SizedBox(height: 24),
                        _buildDescriptionSection(),
                        const SizedBox(height: 24),
                        _buildAttachmentSection(),
                        const SizedBox(height: 20),
                        _buildMetadataNotice(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Send Feedback',
            style: ProfileConstants.nameStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feedback Category',
          style: ProfileConstants.sectionTitleStyle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCategoryChip(
              category: FeedbackCategory.bugReport,
              icon: FontAwesomeIcons.bug,
              label: 'Bug Report',
            ),
            const SizedBox(width: 8),
            _buildCategoryChip(
              category: FeedbackCategory.featureRequest,
              icon: FontAwesomeIcons.lightbulb,
              label: 'Feature',
            ),
            const SizedBox(width: 8),
            _buildCategoryChip(
              category: FeedbackCategory.general,
              icon: FontAwesomeIcons.commentDots,
              label: 'General',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required FeedbackCategory category,
    required dynamic icon,
    required String label,
  }) {
    final isSelected = _selectedCategory == category;
    final primaryColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withAlpha(50)
                : ProfileConstants.cardBackground,
            borderRadius: BorderRadius.circular(ProfileConstants.cardRadius),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon is FaIconData)
                FaIcon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.white60,
                )
              else
                Icon(
                  icon as IconData,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              const SizedBox(height: 8),
              Text(
                label,
                style: ProfileConstants.labelStyle.copyWith(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Description',
              style: ProfileConstants.sectionTitleStyle,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _descriptionController,
              builder: (context, value, child) {
                final length = value.text.length;
                return Text(
                  '$length / $_maxDescriptionLength',
                  style: TextStyle(
                    color: length > _maxDescriptionLength
                        ? AppColors.error
                        : Colors.white54,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: ProfileConstants.cardBackground,
            borderRadius: BorderRadius.circular(ProfileConstants.cardRadius),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextField(
            controller: _descriptionController,
            maxLines: 6,
            maxLength: _maxDescriptionLength,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Manrope',
            ),
            decoration: InputDecoration(
              hintText: _getPlaceholder(_selectedCategory),
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontFamily: 'Manrope',
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Screenshots (Optional)',
              style: ProfileConstants.sectionTitleStyle,
            ),
            Text(
              '${_attachments.length} / $_maxAttachments',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _attachments.length < _maxAttachments
                ? _attachments.length + 1
                : _attachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index < _attachments.length) {
                return _buildAttachmentPreview(index);
              }
              return _buildAddAttachmentButton();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton() {
    return GestureDetector(
      onTap: _isPicking ? null : _pickImages,
      child: Container(
        width: 85,
        height: 95,
        decoration: BoxDecoration(
          color: ProfileConstants.cardBackground,
          borderRadius: BorderRadius.circular(ProfileConstants.cardRadius),
          border: Border.all(
            color: Colors.white24,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: _isPicking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white70,
                      size: 26,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Add Photo',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(int index) {
    final file = _attachments[index];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 85,
          height: 95,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ProfileConstants.cardRadius),
            border: Border.all(color: Colors.white30),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeAttachment(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 19, 36),
        borderRadius: BorderRadius.circular(ProfileConstants.cardRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Colors.white54, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Technical diagnostic metadata (App version, OS version, and device model) is automatically attached to help resolve issues faster.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: primaryColor.withAlpha(120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProfileConstants.cardRadius),
          ),
          elevation: 4,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
      ),
    );
  }
}

