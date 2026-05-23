import 'package:flutter/material.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_dialogs.dart';
import 'package:vehnway/models/vehicle_model.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class VehicleDetailsPage extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Placeholder image if not available (ideally this should come from vehicle model)

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Dark premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Vehicle Image
            Hero(
              tag: 'vehicle_image_${vehicle.id}',
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/vehicle_def.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Vehicle Title & Subtitles
            const SizedBox(height: 20),
            Text(
              vehicle.model,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "2023 | ${vehicle.registration}",
              style: TextStyle(
                color: AppColors.buttonBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Stats Row
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.speed,
                    label: "Distance Covered",
                    value: "24,500 km",
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.electric_bolt,
                    label: "RPS Score",
                    value: "85",
                    isHighlighted: true,
                  ),
                ),
              ],
            ),

            // Document Center
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
                  isUploaded: false,
                  icon: Icons.security,
                  hasEdit: true,
                ),
                _buildDocumentCard(
                  context: context,
                  title: "RC Details",
                  isUploaded: false,
                  icon: Icons.article,
                  hasEdit: true,
                ),
                _buildDocumentCard(
                  context: context,
                  title: "PUC Certificate",
                  isUploaded: false,
                  icon: Icons.cloud_queue,
                ),
                _buildCallActionCard(context),
              ],
            ),

            // Logistics & History
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
            // Map Placeholder
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
                        Icon(
                          Icons.location_on,
                          color: AppColors.buttonBlue,
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Parked near Hill View, Mumbai",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          "2 hours ago",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const SizedBox(height: 30),

            // Delete Vehicle Button
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
                      Navigator.pop(context); // Close dialog
                      CustomLoadingDialog.show(context, message: "Deleting...");

                      await Provider.of<VehicleProvider>(
                        context,
                        listen: false,
                      ).deleteVehicle(vehicle.id);

                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Go back to previous screen
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error deleting vehicle: $e")),
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
                  style: TextStyle(
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
    required bool isUploaded,
    required IconData icon,
    bool hasEdit = false,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Document upload is yet to be implemented"),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUploaded ? "Done" : "Pending",
                      style: const TextStyle(
                        color: Colors.grey,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Feature not implemented yet"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
}
