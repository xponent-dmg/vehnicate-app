import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Pages/onboarding/permissions_page.dart';
import 'package:vehnway/Providers/user_provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/Widgets/star_refresh_indicator.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/Pages/dashboard/widgets/start_card.dart';
import 'package:vehnway/Pages/dashboard/widgets/selected_car_card.dart';
import 'package:vehnway/Pages/dashboard/widgets/last_drive_stats_card.dart';
import 'package:vehnway/utils/vehicle_type_helper.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Form controllers for add vehicle
  final _vehicleModelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _pucDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _registrationController.dispose();
    _insuranceController.dispose();
    _pucDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StarRefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              Provider.of<UserProvider>(context, listen: false).refresh(),
              Provider.of<VehicleProvider>(context, listen: false).refresh(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StartCard(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: PermissionsWidget(compact: true)),
                    const SizedBox(width: 16),
                    SelectedCarCard(
                      onSwap: () => _showVehicleSelectionSheet(context),
                      onAddVehicle: () => _showAddVehicleOverlay(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const LastDriveStatsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Add vehicle overlay ────────────────────────────────────────────────────

  void _showAddVehicleOverlay(BuildContext context) {
    String selectedType = 'sedan';
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    // Reuse these controllers if they are not disposed
    final vehicleNameController = TextEditingController();
    final registrationController = TextEditingController();
    final mileageController = TextEditingController();

    // Cleanup on close
    void cleanup() {
      vehicleNameController.dispose();
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
                              const Text(
                                'Add Vehicle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isSubmitting)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    cleanup();
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Name
                          _buildCustomTextField(
                            context,
                            'Name',
                            'My Car',
                            Icons.edit,
                            vehicleNameController,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          // Type Dropdown
                          const Text(
                            'Vehicle Type *',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70,
                              ),
                              elevation: 4,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items:
                                  VehicleTypeHelper.types
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Row(
                                            children: [
                                              Icon(
                                                VehicleTypeHelper.getIcon(type),
                                                size: 18,
                                                color: Colors.white70,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                VehicleTypeHelper.formatName(
                                                  type,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                              selectedItemBuilder: (context) {
                                return VehicleTypeHelper.types
                                    .map(
                                      (type) => Row(
                                        children: [
                                          Icon(
                                            VehicleTypeHelper.getIcon(type),
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              VehicleTypeHelper.formatName(
                                                type,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList();
                              },
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => selectedType = val);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Registration
                          _buildCustomTextField(
                            context,
                            'Registration Number',
                            'KA01AB1234',
                            Icons.confirmation_number,
                            registrationController,
                          ),
                          const SizedBox(height: 16),
                          // Average Mileage
                          _buildCustomTextField(
                            context,
                            'Average Mileage',
                            '15',
                            Icons.speed,
                            mileageController,
                            suffixText:
                                selectedType == 'EV' ? 'km/kWh' : 'km/L',
                            isNumber: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isSubmitting
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate())
                                          return;
                                        setState(() => isSubmitting = true);
                                        try {
                                          String finalName =
                                              vehicleNameController.text.trim();
                                          if (finalName.isEmpty)
                                            finalName = 'Untitled';

                                          await Provider.of<VehicleProvider>(
                                            context,
                                            listen: false,
                                          ).addVehicle(
                                            name: finalName,
                                            model: 'Unknown Model',
                                            registration:
                                                registrationController.text
                                                    .trim()
                                                    .toUpperCase(),
                                            vehicleType: selectedType,
                                            averageMileage: double.tryParse(
                                              mileageController.text.trim(),
                                            ),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Vehicle added successfully!',
                                                ),
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                            );
                                          }
                                          cleanup();
                                        } catch (e) {
                                          if (context.mounted)
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                        } finally {
                                          if (context.mounted)
                                            setState(
                                              () => isSubmitting = false,
                                            );
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  isSubmitting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Add Vehicle',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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

  Widget _buildCustomTextField(
    BuildContext context,
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    String? suffixText,
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType:
              isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator:
              (value) =>
                  isRequired && (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
        ),
      ],
    );
  }

  // ─── Vehicle selection bottom sheet ────────────────────────────────────────

  void _showVehicleSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassLiteContainer(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Consumer<VehicleProvider>(
            builder: (context, vehicleProvider, child) {
              final vehicles = vehicleProvider.vehicles;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0, left: 8.0),
                    child: Text(
                      'Select Vehicle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (vehicles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No vehicles available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      children:
                          vehicles.map((vehicle) {
                            final isSelected =
                                vehicle.id ==
                                vehicleProvider.selectedVehicle?.id;
                            return InkWell(
                              onTap: () {
                                vehicleProvider.selectVehicle(vehicle);
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_car,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicle.model,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            vehicle.formattedRegistration,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
