import 'package:flutter/material.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/Widgets/star_refresh_indicator.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/models/vehicle_model.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/Widgets/vehicle_location_text.dart';
import 'package:vehnway/services/supabase/supabase_vehicle_service.dart';

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
    String selectedType = 'Non-EV';
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    // Reuse these controllers if they are not disposed
    final vehicleModelController = TextEditingController();
    final registrationController = TextEditingController();
    final mileageController = TextEditingController();
    
    // Cleanup on close
    void cleanup() {
      vehicleModelController.dispose();
      registrationController.dispose();
      mileageController.dispose();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: Dialog(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: GlassLiteContainer(
                  backgroundColor: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(20),
                  hasBorder: true,
                  hasShadow: true,
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              if (!isSubmitting)
                                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () {
                                  cleanup();
                                  Navigator.pop(context);
                                }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Type Dropdown
                          const Text('Vehicle Type *', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.electric_car, color: Theme.of(context).primaryColor, size: 20),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: ['Non-EV', 'EV'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedType = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Model
                          _buildCustomTextField(context, 'Model', 'e.g., Honda City', Icons.car_rental, vehicleModelController),
                          const SizedBox(height: 16),
                          // Registration
                          _buildCustomTextField(context, 'Registration Number', 'e.g., KA01AB1234', Icons.confirmation_number, registrationController),
                          const SizedBox(height: 16),
                          // Average Mileage
                          _buildCustomTextField(context, 'Average Mileage', 'e.g., 15', Icons.speed, mileageController, 
                           suffixText: selectedType == 'EV' ? 'km/kWh' : 'km/L', isNumber: true),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : () async {
                                if (!formKey.currentState!.validate()) return;
                                setState(() => isSubmitting = true);
                                try {
                                  await SupabaseVehicleService().createVehicle(
                                    model: vehicleModelController.text.trim(),
                                    registration: registrationController.text.trim().toUpperCase(),
                                    vehicleType: selectedType,
                                    averageMileage: double.tryParse(mileageController.text.trim()),
                                  );
                                  if (context.mounted) {
                                    await Provider.of<VehicleProvider>(context, listen: false).refresh();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vehicle added successfully!'), backgroundColor: Theme.of(context).primaryColor));
                                  }
                                  cleanup();
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                                } finally {
                                  if (context.mounted) setState(() => isSubmitting = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSubmitting ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomTextField(BuildContext context, String label, String hint, IconData icon, TextEditingController controller, {String? suffixText, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label *', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            suffixText: suffixText,
            suffixStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
        ),
      ],
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

    if (vehicles.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bottomNavigationOffset = MediaQuery.of(context).padding.bottom + 104.0;
          final visibleHeight =
              (constraints.maxHeight - bottomNavigationOffset).clamp(
                0.0,
                constraints.maxHeight,
              );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: [
              SizedBox(
                height: visibleHeight,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white54,
                        size: 42,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Add your first car',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your garage will appear here once you add a vehicle.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

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
