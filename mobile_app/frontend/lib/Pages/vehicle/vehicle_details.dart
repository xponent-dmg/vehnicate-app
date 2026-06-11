import 'package:flutter/material.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_dialogs.dart';
import 'package:vehnway/models/vehicle_model.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/Widgets/vehicle_location_text.dart';
import 'package:vehnway/services/supabase/vehicle_document_service.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vehnway/Pages/vehicle/widgets/upload_document_sheet.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  final VehicleDocumentService _docService = VehicleDocumentService();
  bool _isLoadingDocs = true;
  Map<String, List<Map<String, dynamic>>> _documents = {};

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final docs = await _docService.getDocumentsGroupedByType(
        widget.vehicle.id,
      );
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDocs = false;
        });
        CustomSnackBar.showError(context, 'Error loading documents: $e');
      }
    }
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return "Not seen yet";
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return "Just now";
    }

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return "$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago";
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return "$hours ${hours == 1 ? 'hour' : 'hours'} ago";
    } else {
      final days = difference.inDays;
      return "$days ${days == 1 ? 'day' : 'days'} ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'vehicle_image_${widget.vehicle.id}',
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/vehicle_def.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.vehicle.model,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "2023  |  ${widget.vehicle.formattedRegistration}",
              style: const TextStyle(
                color: AppColors.buttonBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.speed,
                    label: "Distance Covered",
                    value:
                        "${widget.vehicle.distance?.toStringAsFixed(1) ?? '0'} km",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Document Center",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (_isLoadingDocs)
              const Center(
                child: CircularProgressIndicator(color: AppColors.buttonBlue),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildDocumentCard(
                    context: context,
                    title: "Insurance Policy",
                    dbType: 'insurance',
                    icon: Icons.security,
                    hasEdit: true,
                  ),
                  _buildDocumentCard(
                    context: context,
                    title: "RC Details",
                    dbType: 'registration',
                    icon: Icons.article,
                    hasEdit: true,
                  ),
                  _buildDocumentCard(
                    context: context,
                    title: "PUC Certificate",
                    dbType: 'puc',
                    icon: Icons.cloud_queue,
                    hasEdit: true,
                  ),
                  _buildCallActionCard(context),
                ],
              ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Last seen",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 15),
            GlassLiteContainer(
              height: 150,
              width: double.infinity,
              backgroundColor: AppColors.darkGreyBackground,
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.buttonBlue,
                          size: 30,
                        ),
                        const SizedBox(height: 10),
                        VehicleLocationText(
                          vehicleId: widget.vehicle.id,
                          prefix: 'Parked near ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Consumer<VehicleProvider>(
                          builder: (context, provider, child) {
                            return Text(
                              _formatRelativeTime(provider.lastSeenTime),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                CustomConfirmationDialog.show(
                  context,
                  title: "Delete Vehicle",
                  content:
                      "Are you sure you want to delete this vehicle? This action cannot be undone.",
                  confirmText: "Delete",
                  confirmTextColor: Colors.red,
                  onConfirm: () async {
                    try {
                      Navigator.pop(context);
                      CustomLoadingDialog.show(context, message: "Deleting...");

                      await Provider.of<VehicleProvider>(
                        context,
                        listen: false,
                      ).deleteVehicle(widget.vehicle.id);

                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        CustomSnackBar.showError(
                          context,
                          "Error deleting vehicle: $e",
                        );
                      }
                    }
                  },
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    "Delete Vehicle",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return GlassLiteContainer(
      height: 100,
      backgroundColor:
          isHighlighted
              ? AppColors.buttonBlue.withOpacity(0.2)
              : AppColors.darkGreyBackground,
      borderColor:
          isHighlighted ? AppColors.buttonBlue : Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[400], size: 18),
                const SizedBox(width: 8),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required String title,
    required String dbType,
    required IconData icon,
    bool hasEdit = false,
  }) {
    final docs = _documents[dbType];
    final isUploaded = docs != null && docs.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        if (isUploaded) {
          _showDocumentOptionsSheet(context, title, dbType, docs.first);
        } else {
          _showUploadOptionsSheet(context, title, dbType);
        }
      },
      child: GlassLiteContainer(
        backgroundColor: AppColors.darkGreyBackground,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasEdit)
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isUploaded
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isUploaded
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isUploaded ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUploaded ? "Done" : "Pending",
                      style: TextStyle(
                        color: isUploaded ? Colors.green : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildCallActionCard(BuildContext context) {
    return GlassLiteContainer(
      backgroundColor: AppColors.darkGreyBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.two_wheeler, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Roadside Assist",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Premium Plan",
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                CustomSnackBar.showInfo(context, "Feature not implemented yet");
              },
              child: GlassLiteContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: AppColors.buttonBlue,
                borderRadius: BorderRadius.circular(12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "Tap to Call",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadOptionsSheet(
    BuildContext context,
    String title,
    String dbType, {
    String? existingDocumentId,
    String? oldFilePath,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return UploadDocumentSheet(
          vehicle: widget.vehicle,
          documentType: dbType,
          typeName: title,
          existingDocumentId: existingDocumentId,
          oldFilePath: oldFilePath,
          onUploadSuccess: () {
            _fetchDocuments();
          },
        );
      },
    );
  }

  void _showDocumentOptionsSheet(
    BuildContext context,
    String title,
    String dbType,
    Map<String, dynamic> doc,
  ) {
    final filePath = doc['file_path'] as String;
    final documentId = doc['document_id'] as String;
    final mimeType = (doc['mime_type'] ?? '') as String;
    final originalFileName = (doc['file_name'] ?? '') as String;

    final publicUrl = Supabase.instance.client.storage
        .from('vehicle-documents')
        .getPublicUrl(filePath);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassLiteContainer(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          backgroundColor: AppColors.darkGreyBackground,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                originalFileName,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _viewDocument(title, publicUrl, mimeType);
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  _showUploadOptionsSheet(
                    context,
                    title,
                    dbType,
                    existingDocumentId: documentId,
                    oldFilePath: filePath,
                  );
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('Replace / Edit File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteDocument(title, documentId, filePath);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text(
                  'Delete Document',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewDocument(String title, String url, String mimeType) {
    if (mimeType.startsWith('image/')) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.black54,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.buttonBlue,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          color: AppColors.darkGreyBackground,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.red,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Error loading image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF13151A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a PDF/Non-Image document. Would you like to view it inside a web browser?',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openPdfInWebView(title, url);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _openPdfInWebView(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PdfWebViewPage(title: title, url: url),
      ),
    );
  }

  void _confirmDeleteDocument(
    String title,
    String documentId,
    String filePath,
  ) {
    CustomConfirmationDialog.show(
      context,
      title: "Delete Document",
      content:
          "Are you sure you want to delete your $title? This action cannot be undone.",
      confirmText: "Delete",
      confirmTextColor: Colors.red,
      onConfirm: () async {
        try {
          Navigator.pop(context);
          CustomLoadingDialog.show(context, message: "Deleting $title...");

          await _docService.deleteDocument(documentId, filePath);

          if (mounted) {
            Navigator.pop(context);
            CustomSnackBar.showSuccess(context, '$title deleted successfully!');
            _fetchDocuments();
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            CustomSnackBar.showError(context, 'Failed to delete $title: $e');
          }
        }
      },
    );
  }
}

class _PdfWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const _PdfWebViewPage({required this.title, required this.url});

  @override
  State<_PdfWebViewPage> createState() => _PdfWebViewPageState();
}

class _PdfWebViewPageState extends State<_PdfWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final googleDocsViewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFF0F1115))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(googleDocsViewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.buttonBlue),
            ),
        ],
      ),
    );
  }
}

