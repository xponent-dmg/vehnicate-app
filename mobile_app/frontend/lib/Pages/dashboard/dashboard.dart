import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehnway/Pages/onboarding/permissions_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/Widgets/star_refresh_indicator.dart';
import 'package:provider/provider.dart';

import 'package:vehnway/Providers/user_provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/form_overlay.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

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
                _startCard(context),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: const PermissionsWidget(compact: true),
                    ),
                    const SizedBox(width: 16),
                    _selectedCarCard(context),
                  ],
                ),
                const SizedBox(height: 16),
                // _weeklyChallenge(context),
                // const SizedBox(height: 16),
                _lastDriveStatsCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Add vehicle overlay ────────────────────────────────────────────────────

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
        await Provider.of<VehicleProvider>(context, listen: false).addVehicle(
          model: _vehicleModelController.text.trim(),
          registration: _registrationController.text.trim(),
          insurance: _insuranceController.text.trim(),
          puc:
              _pucDateController.text.trim().isEmpty
                  ? null
                  : _pucDateController.text.trim(),
        );

        _vehicleModelController.clear();
        _registrationController.clear();
        _insuranceController.clear();
        _pucDateController.clear();
      },
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vehicle added successfully!'),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
                    child: const Text(
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

  // ─── Selected car card ──────────────────────────────────────────────────────

  Widget _selectedCarCard(BuildContext context) {
    return Expanded(
      child: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          // shimmer while loading
          if (vehicleProvider.isLoading) {
            return const _CarCardShimmer();
          }

          final hasVehicle = vehicleProvider.vehicleId != null;

          return GlassLiteContainer(
            hasBorder: false,
            height: 160,
            backgroundColor: AppColors.background,
            padding: const EdgeInsets.all(17),
            child:
                hasVehicle
                    // ── vehicle exists ──────────────────────────────────
                    ? _VehicleInfoContent(
                      model: vehicleProvider.vehicleModel ?? 'No vehicle',
                      registration:
                          vehicleProvider
                              .selectedVehicle
                              ?.formattedRegistration ??
                          '------',
                      onSwap: () => _showVehicleSelectionSheet(context),
                    )
                    // ── no vehicle yet ──────────────────────────────────
                    : _NoVehicleContent(
                      onAddVehicle: () => _showAddVehicleOverlay(context),
                    ),
          );
        },
      ),
    );
  }
}

// ─── Car card sub-widgets ─────────────────────────────────────────────────────

/// Content shown when a vehicle IS selected.
class _VehicleInfoContent extends StatelessWidget {
  const _VehicleInfoContent({
    required this.model,
    required this.registration,
    required this.onSwap,
  });

  final String model;
  final String registration;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    registration,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSwap,
              child: const Column(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  Text(
                    'Swap',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Image.asset("assets/images/vehicle_def.png")),
          ),
        ),
      ],
    );
  }
}

/// Content shown when NO vehicle has been added yet.
class _NoVehicleContent extends StatelessWidget {
  const _NoVehicleContent({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onAddVehicle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Add Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to add your vehicle',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Shimmer skeleton ─────────────────────────────────────────────────────────

/// Skeleton for the selected-car card shown while VehicleProvider is loading.
class _CarCardShimmer extends StatelessWidget {
  const _CarCardShimmer();

  @override
  Widget build(BuildContext context) {
    return GlassLiteContainer(
      hasBorder: false,
      height: 160,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(17),
      child: Shimmer.fromColors(
        baseColor: ShimmerConstants.shimmerBase,
        highlightColor: ShimmerConstants.shimmerHighlight,
        direction: ShimmerDirection.ttb,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // mirrors Row(text column + swap icon)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // model name — fontSize:16 bold ≈ 18px
                      Container(
                        height: 18,
                        width: 100,
                        decoration: BoxDecoration(
                          color: ShimmerConstants.shimmerBase,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // registration — fontSize:11 ≈ 13px
                      Container(
                        height: 13,
                        width: 70,
                        decoration: BoxDecoration(
                          color: ShimmerConstants.shimmerBase,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
                // swap icon + label placeholder
                const Column(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: Colors.white),
                    Text(
                      'Swap',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // vehicle image placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ShimmerConstants.shimmerBase,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top-level card widgets ───────────────────────────────────────────────────

Widget _startCard(BuildContext context) {
  return GlassLiteContainer(
    hasBorder: false,
    backgroundColor: AppColors.background,
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            final vehicleProvider =
                Provider.of<VehicleProvider>(context, listen: false);
            if (vehicleProvider.vehicleId == null) {
              CustomSnackBar.showWarning(
                context,
                "Please select or add a vehicle before starting your drive.",
              );
              return;
            }
            Navigator.pushNamed(
              context,
              "/loading",
              arguments: {
                "duration": const Duration(seconds: 3),
                "onComplete": () {
                  Navigator.pushReplacementNamed(context, "/imu");
                },
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'Start Drive',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const Spacer(),

        GestureDetector(
          onTap: () => Navigator.pushNamed(context, "/map-webview"),
          onLongPress: () => Navigator.pushNamed(context, "/map"),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map, color: Colors.white70, size: 24),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
  );
}

Widget _lastDriveStatsCard(BuildContext context) {
  final vehicleProvider = Provider.of<VehicleProvider>(context);
  final latestDrive = vehicleProvider.latestDrive;

  if (vehicleProvider.isLoading) {
    return GlassLiteContainer(
      hasBorder: false,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }

  if (latestDrive == null) {
    return GlassLiteContainer(
      hasBorder: false,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            "No drives recorded yet. Start a drive to see your stats!",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  final liquidEllar = latestDrive.liquidEllar;
  final frozenEllar = latestDrive.frozenEllar;
  final roadDefects = latestDrive.roadDefects;
  final distance = latestDrive.distance;
  final duration = latestDrive.duration;
  
  final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(latestDrive.startTime.toLocal());
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final formattedDuration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

  return GlassLiteContainer(
    hasBorder: false,
    backgroundColor: AppColors.background,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Last Drive Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                formattedDuration,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          formattedDate,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _newStatItem(
                context, 
                "Liq Ellar", 
                liquidEllar.toString(), 
                Icons.water_drop,
                const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _newStatItem(
                context, 
                "Frozen Ellar", 
                frozenEllar.toString(), 
                Icons.ac_unit,
                const Color(0xFFFFB0B0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _newStatItem(
                context, 
                "Defects", 
                roadDefects.toString(), 
                Icons.warning_amber_rounded,
                const Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _newStatItem(
                context, 
                "Distance", 
                "${distance.toStringAsFixed(1)} km", 
                Icons.directions_run_rounded,
                const Color(0xFF34D399),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _newStatItem(
  BuildContext context, 
  String label, 
  String value, 
  IconData icon,
  Color iconColor,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

