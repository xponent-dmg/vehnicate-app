import 'package:flutter/material.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/Widgets/star_refresh_indicator.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehnway/services/supabase_service.dart';
import 'package:vehnway/Widgets/form_overlay.dart';
import 'package:vehnway/models/vehicle_model.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/Widgets/vehicle_location_text.dart';

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});
  @override
  State<GaragePage> createState() => GaragePageState();
}

class GaragePageState extends State<GaragePage> {
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

  void showAddVehicleOverlay(BuildContext context) {
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
          isRequired: false,
        ),
        FormFieldConfig(
          label: 'PUC Date',
          hint: 'Select date',
          icon: Icons.calendar_today,
          controller: _pucDateController,
          type: FormFieldType.date,
          isRequired: false,
        ),
      ],
      submitButtonText: 'Add Vehicle',
      onSubmit: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        await SupabaseService().createVehicle(
          model: _vehicleModelController.text.trim(),
          registration: _registrationController.text.trim().toUpperCase(),
          insurance: _insuranceController.text.trim().toUpperCase(),
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
            child: StarRefreshIndicator(
              onRefresh: () async {
                await vehicleProvider.refresh();
              },
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
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(vehicles[index]);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    // Placeholder data
    final String image = 'assets/images/vehicle_def.png';

    return GlassLiteContainer(
      margin: const EdgeInsets.only(bottom: 20),
      height: 150,
      backgroundColor: AppColors.darkGreyBackground,
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.pushNamed(context, "/vehicle-details", arguments: vehicle);
      },
      child: Stack(
        children: [
          // Content Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Car Image Area
                Hero(
                  tag: 'vehicle_image_${vehicle.id}',
                  child: Container(
                    width: 110,
                    height: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(image),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details Column
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicle.formattedRegistration,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 13,
                              color: AppColors.buttonBlue,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: VehicleLocationText(
                                vehicleId: vehicle.id,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
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

          // "Arrow"
          Positioned(
            right: 25,
            bottom: 60,

            child: Icon(
              Icons.arrow_right_rounded,
              color: Colors.grey[500],
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
