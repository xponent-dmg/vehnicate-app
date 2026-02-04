import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/Widgets/form_overlay.dart';
import 'package:vehnicate_frontend/models/vehicle_model.dart';

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final _vehicleModelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _pucDateController = TextEditingController();

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _registrationController.dispose();
    _insuranceController.dispose();
    _pucDateController.dispose();
    super.dispose();
  }

  void _showAddVehicleOverlay(BuildContext context) {
    FormOverlay.show(
      context: context,
      title: 'Add Vehicle',
      fields: [
        FormFieldConfig(
          label: 'Model',
          hint: 'e.g., Honda City',
          icon: Icons.car_rental,
          controller: _vehicleModelController,
        ),
        FormFieldConfig(
          label: 'Registration Number',
          hint: 'e.g., KA01AB1234',
          icon: Icons.confirmation_number,
          controller: _registrationController,
        ),
        FormFieldConfig(
          label: 'Insurance Number',
          hint: 'e.g., INS123456789',
          icon: Icons.shield,
          controller: _insuranceController,
        ),
        FormFieldConfig(
          label: 'PUC Date',
          hint: 'Select date',
          icon: Icons.calendar_today,
          controller: _pucDateController,
          type: FormFieldType.date,
        ),
      ],
      submitButtonText: 'Add Vehicle',
      onSubmit: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        await SupabaseService().createVehicle(
          firebaseUid: user.uid,
          model: _vehicleModelController.text.trim(),
          registration: _registrationController.text.trim(),
          insurance: _insuranceController.text.trim(),
          puc:
              _pucDateController.text.trim().isEmpty
                  ? null
                  : _pucDateController.text.trim(),
        );

        if (mounted) {
          await Provider.of<VehicleProvider>(context, listen: false).refresh();
        }

        _vehicleModelController.clear();
        _registrationController.clear();
        _insuranceController.clear();
        _pucDateController.clear();
      },
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle added successfully!'),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add vehicle: ${error.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await vehicleProvider.refresh();
              },
              color: Colors.purple,
              backgroundColor: const Color(0xFF1E1E1E),
              child: _buildVehicleList(vehicleProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleList(VehicleProvider vehicleProvider) {
    final vehicles = vehicleProvider.vehicles;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      itemCount: vehicles.length + 1,
      itemBuilder: (context, index) {
        if (index == vehicles.length) {
          return _buildAddVehicleTile();
        }
        return _buildVehicleCard(vehicles[index]);
      },
    );
  }

  Widget _buildAddVehicleTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddVehicleOverlay(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(40),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: const Color(0xFF5B60F8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add another vehicle',
                    style: TextStyle(
                      color: const Color(0xFF5B60F8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    // Placeholder data

    final String location = "Hill view, Mumbai"; // Placeholder
    final String image =
        "https://images.unsplash.com/photo-1503376763036-066120622c74?auto=format&fit=crop&w=300&q=80"; // Placeholder

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D25), // Card background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Content Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Car Image Area
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1B1D25),
                          child: Center(
                            child: Icon(
                              Icons.directions_car_filled,
                              size: 40,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details Column
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicle.registration,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: const Color(0xFF5B60F8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // "View details" text at bottom right
          Positioned(
            bottom: 12,
            right: 16,
            child: Row(
              children: [
                Text(
                  'View details',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
                Icon(Icons.arrow_right, color: Colors.grey[500], size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
