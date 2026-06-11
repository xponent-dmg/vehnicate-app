import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/vehicle_model.dart';
import 'package:vehnway/services/supabase/vehicle_document_service.dart';

class UploadDocumentSheet extends StatefulWidget {
  final Vehicle vehicle;
  final String documentType;
  final String typeName;
  final String? existingDocumentId;
  final String? oldFilePath;
  final VoidCallback onUploadSuccess;

  const UploadDocumentSheet({
    super.key,
    required this.vehicle,
    required this.documentType,
    required this.typeName,
    this.existingDocumentId,
    this.oldFilePath,
    required this.onUploadSuccess,
  });

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  final VehicleDocumentService _docService = VehicleDocumentService();
  File? _selectedFile;
  String? _fileName;
  bool _isPicking = false;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        setState(() {
          _selectedFile = File(filePath);
          _fileName = path.basename(filePath);
        });
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      if (widget.existingDocumentId != null && widget.oldFilePath != null) {
        await _docService.replaceDocument(
          existingDocumentId: widget.existingDocumentId!,
          vehicleId: widget.vehicle.id,
          documentType: widget.documentType,
          oldFilePath: widget.oldFilePath!,
          newFile: _selectedFile!,
        );
      } else {
        await _docService.uploadDocument(
          vehicleId: widget.vehicle.id,
          documentType: widget.documentType,
          file: _selectedFile!,
        );
      }

      if (mounted) {
        setState(() => _isUploading = false);
        CustomSnackBar.showSuccess(
          context,
          '${widget.typeName} ${widget.existingDocumentId != null ? 'replaced' : 'uploaded'} successfully!',
        );
        widget.onUploadSuccess();
        Navigator.pop(context); // Close sheet
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        CustomSnackBar.showError(context, 'Upload failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassLiteContainer(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      backgroundColor: AppColors.darkGreyBackground,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '${widget.existingDocumentId != null ? 'Replace' : 'Upload'} ${widget.typeName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Supported formats: PDF, DOC, DOCX',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isPicking || _isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        _selectedFile != null
                            ? AppColors.buttonBlue
                            : Colors.white12,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      color:
                          _selectedFile != null
                              ? AppColors.buttonBlue
                              : Colors.white70,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Tap to browse files',
                      style: TextStyle(
                        color:
                            _selectedFile != null
                                ? Colors.white
                                : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 20),
              if (_isUploading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.buttonBlue),
                )
              else
                ElevatedButton.icon(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(
                    widget.existingDocumentId != null ? 'Replace' : 'Upload',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
