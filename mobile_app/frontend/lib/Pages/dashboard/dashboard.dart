import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:opsin/Widgets/glass_lite_container.dart';
import 'package:opsin/Widgets/star_refresh_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:opsin/Providers/user_provider.dart';
import 'package:opsin/Providers/vehicle_provider.dart';
import 'package:opsin/Widgets/form_overlay.dart';
import 'package:opsin/core/constants/app_gradients.dart';

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
                  children: [
                    _rpsScoreCard(context),
                    const SizedBox(width: 16),
                    _selectedCarCard(context),
                  ],
                ),
                const SizedBox(height: 16),
                _weeklyChallenge(context),
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
          backgroundColor: const Color(0xFF2d2d44),
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
            backgroundColor: const Color(0xFF2d2d44),
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
              color: const Color(0xFF3d3d54),
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
      backgroundColor: const Color(0xFF2d2d44),
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
    backgroundColor: const Color(0xFF2d2d44),
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, "/map-webview"),
          onLongPress: () => Navigator.pushNamed(context, "/map"),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF3d3d54),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map, color: Colors.white70, size: 20),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
  );
}

Widget _rpsScoreCard(BuildContext context) {
  return Expanded(
    child: Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isLoading = userProvider.isLoading;
        final rpsScore = userProvider.currentUser?.rpsScore;

        return GlassLiteContainer(
          hasBorder: false,
          backgroundColor: const Color(0xFF2d2d44),
          padding: const EdgeInsets.all(20),
          child: CircularPercentIndicator(
            radius: 60,
            lineWidth: 10,
            percent: isLoading ? 0 : (rpsScore ?? 0) / 100,
            backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
            progressColor: Theme.of(context).primaryColor,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // shimmer only the score number while loading
                if (isLoading)
                  Shimmer.fromColors(
                    baseColor: ShimmerConstants.shimmerBase,
                    highlightColor: ShimmerConstants.shimmerHighlight,
                    child: Container(
                      width: 44,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ShimmerConstants.shimmerBase,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                else
                  Text(
                    rpsScore?.toString() ?? '- -',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor.withAlpha(51),
                  ),
                  child: const Text(
                    'RPS Score',
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _weeklyChallenge(BuildContext context) {
  return GlassLiteContainer(
    hasBorder: false,
    backgroundColor: const Color(0xFF2d2d44),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Drive smoothly',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1,
                ),
              ),
              child: Text(
                'Weekly',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Maintain constant acceleration for 50 km',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reward: 500 points',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '50%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF3d3d54),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.5 * 0.5,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
