import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Widgets/glass_lite_container.dart';
import 'package:vehnicate_frontend/models/vehicle_model.dart';

class VehicleDetailsPage extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Placeholder image if not available (ideally this should come from vehicle model)
    const String vehicleImage =
        "https://images.unsplash.com/photo-1558981806-ec527fa84f3d?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=hunter";

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Dark premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
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
                    image: NetworkImage(vehicleImage),
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
                color: const Color(0xFF5B60F8),
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
              childAspectRatio: 1.2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildDocumentCard(
                  title: "Insurance Policy",
                  status: "Active",
                  statusColor: Colors.green,
                  subtitle: "Expires: 14 Nov 2024",
                  icon: Icons.security,
                  hasEdit: true,
                ),
                _buildDocumentCard(
                  title: "RC Details",
                  status: "Verified",
                  statusColor: Colors.grey,
                  subtitle: vehicle.registration,
                  icon: Icons.article,
                  hasEdit: true,
                ),
                _buildDocumentCard(
                  title: "PUC Certificate",
                  status: "Expiring Soon",
                  statusColor: Colors.orange,
                  subtitle:
                      vehicle.puc != null
                          ? "Expires: ${vehicle.puc}"
                          : "Not Uploaded",
                  icon: Icons.cloud_queue,
                ),
                _buildCallActionCard(),
              ],
            ),

            // Logistics & History
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Logistics & History",
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
              backgroundColor: const Color(0xFF1B1D25),
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF5B60F8),
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Parked near Orchard Avenue, Mumbai",
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
            _buildListTile(
              icon: Icons.build_circle_outlined,
              title: "Service History",
              trailing: "Last: Oil Change (Jan 24)",
            ),
            const SizedBox(height: 10),
            _buildListTile(
              icon: Icons.wallet,
              title: "Total Expenses",
              trailing: "Rs 31,200",
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
              ? const Color(0xFF5B60F8).withOpacity(0.2)
              : const Color(0xFF1B1D25),
      borderColor:
          isHighlighted
              ? const Color(0xFF5B60F8)
              : Colors.white.withOpacity(0.1),
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
    required String title,
    required String status,
    required Color statusColor,
    required String subtitle,
    required IconData icon,
    bool hasEdit = false,
  }) {
    return GlassLiteContainer(
      backgroundColor: const Color(0xFF1B1D25),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Container(
                //   padding: const EdgeInsets.all(6),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF2A2D35),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Icon(icon, color: const Color(0xFF5B60F8), size: 16),
                // ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12, // Adjusted font size
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1, // Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasEdit)
                  Icon(Icons.edit, color: Colors.grey[600], size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   title,
                //   style: GoogleFonts.outfit(
                //     color: Colors.white,
                //     fontSize: 12, // Adjusted font size
                //     fontWeight: FontWeight.w600,
                //   ),
                //   maxLines: 1, // Prevent overflow
                //   overflow: TextOverflow.ellipsis,
                // ),
                // const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      // Prevent overflow
                      child: Text(
                        status,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionCard() {
    return GlassLiteContainer(
      backgroundColor: const Color(0xFF1B1D25),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.two_wheeler, color: Colors.grey[500], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
            GlassLiteContainer(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              // decoration: BoxDecoration(
              //   color: const Color(0xFF5B60F8),
              //   borderRadius: BorderRadius.circular(12),
              // ),
              backgroundColor: const Color(0xFF5B60F8),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
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
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String trailing,
  }) {
    return GlassLiteContainer(
      height: 60,
      backgroundColor: const Color(0xFF1B1D25).withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5B60F8), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              trailing,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[500], size: 16),
          ],
        ),
      ),
    );
  }
}
