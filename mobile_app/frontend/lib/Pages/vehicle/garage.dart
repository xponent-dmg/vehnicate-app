import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';

class GaragePage extends StatelessWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Assuming VehicleProvider is defined and has a refresh method
            // and that this widget is within a Provider scope.
            // If not, you might need to adjust how VehicleProvider is accessed.
            await Provider.of<VehicleProvider>(context, listen: false).refresh();
          },
          color: Colors.purple,
          backgroundColor: Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header with welcome text
                Text(
                  'Welcome to your Garage,',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 35),

                // Statistics Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_buildStatCard('647', 'Miles Travelled'), _buildStatCard('753', 'Credits Earned')],
                ),
                const SizedBox(height: 30),

                // Vehicle Documentation Section
                Text('Vehicle Docs', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                _buildDocumentTile(context, 'Registration Certificate', Icons.description),
                _buildDocumentTile(context, 'Vehicle Insurance', Icons.car_repair),
                _buildDocumentTile(context, 'PUC', Icons.eco),
                _buildDocumentTile(context, 'Driving License', Icons.card_membership),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          Navigator.pushNamed(context, '/document-upload', arguments: {'documentType': title});
        },
      ),
    );
  }
}
