import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';
// ignore: unused_import
import 'package:vehnicate_frontend/services/supabase_service.dart';

class DocumentUploadPage extends StatefulWidget {
  final String documentType; // e.g., Registration Certificate, Vehicle Insurance, PUC, Driving License

  const DocumentUploadPage({super.key, required this.documentType});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  File? _selectedFile;
  String? _fileName;
  bool _isPicking = false;

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'heic'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() {
          _selectedFile = File(path);
          _fileName = result.files.single.name;
        });
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    // TODO: Review and adjust later. Supabase upload stub intentionally commented out.
    /*
    try {
      await SupabaseService().initialize();
      final client = Supabase.instance.client;
      final pathInBucket = 'vehicle_docs/${widget.documentType.toLowerCase().replaceAll(' ', '_')}/$_fileName';
      final bucket = client.storage.from('vehicle-documents');
      await bucket.upload(pathInBucket, _selectedFile!);

      // Optionally, store metadata in a table
      await client.from('vehicle_documents').insert({
        'document_type': widget.documentType,
        'file_name': _fileName,
        'path': pathInBucket,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploaded successfully')), 
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
    */

    // Temporary behavior while upload is commented out
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Picked file, upload stub commented out.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileConstants.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Upload ${widget.documentType}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Select a document file to upload', style: ProfileConstants.sectionTitleStyle),
              const SizedBox(height: 8),
              const Text('Supported: PDF, JPG, PNG, HEIC', style: ProfileConstants.labelStyle),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF2d2d44), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFF3d3d54), shape: BoxShape.circle),
                          child: const Icon(Icons.insert_drive_file, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fileName ?? 'No file selected',
                            style: ProfileConstants.valueStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isPicking ? null : _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose File'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _selectedFile == null ? null : _uploadFile,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Upload'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
