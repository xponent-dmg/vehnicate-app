import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Widgets/glass_lite_container.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/Widgets/form_overlay.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              Provider.of<UserProvider>(context, listen: false).refresh(),
              Provider.of<VehicleProvider>(context, listen: false).refresh(),
            ]);
          },
          color: Theme.of(context).primaryColor,
          backgroundColor: ProfileConstants.cardBackground,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start Card
                _startCard(context),
                SizedBox(height: 16),
                // Score and Car Info
                Row(
                  children: [
                    // Circular Score
                    _rpsScoreCard(context),
                    SizedBox(width: 16),
                    // Car Info
                    _selectedCarCard(context),
                  ],
                ),
                SizedBox(height: 16),

                // Weekly Challenge
                _weeklyChallenge(context),
              ],
            ),
          ),
        ),
      ),
    );
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

        // Refresh vehicle data
        if (mounted) {
          await Provider.of<VehicleProvider>(context, listen: false).refresh();
        }

        // Clear form
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
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
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(12),
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
                                    Icon(
                                      Icons.directions_car,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicle.model,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            vehicle.registration,
                                            style: TextStyle(
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

  Widget _selectedCarCard(BuildContext context) {
    return Expanded(
      child: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          final hasVehicle = vehicleProvider.vehicleId != null;

          return GlassLiteContainer(
            hasBorder: false,
            height: 160,
            backgroundColor: const Color(0xFF2d2d44),
            padding: const EdgeInsets.all(17),
            child:
                hasVehicle
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicleProvider.vehicleModel ??
                                        'No vehicle',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    vehicleProvider.vehicleRegistration ??
                                        '------',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showVehicleSelectionSheet(context),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.swap_horiz_rounded,
                                    color: Colors.white,
                                  ),
                                  const Text(
                                    'Swap',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
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
                            child: Center(
                              child: Image.asset(
                                "assets/images/vehicle_def.png",
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _showAddVehicleOverlay(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha(51),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 1,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                      // size: 16, // Assuming a small icon size
                                    ),
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
                    ),
          );
        },
      ),
    );
  }
}

Widget _startCard(BuildContext context) {
  return GlassLiteContainer(
    hasBorder: false,
    backgroundColor: const Color(0xFF2d2d44),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/imu");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
              onTap: () {
                Navigator.pushNamed(context, "/map");
              },
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
      ],
    ),
  );
}

Widget _rpsScoreCard(BuildContext context) {
  final rpsScore = context.watch<UserProvider>().currentUser?.rpsScore;
  return Expanded(
    child: GlassLiteContainer(
      hasBorder: false,
      // height: 170,
      backgroundColor: const Color(0xFF2d2d44),
      padding: const EdgeInsets.all(20),
      child: CircularPercentIndicator(
        radius: 60,
        lineWidth: 10,
        percent: (rpsScore ?? 0) / 100,
        backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
        progressColor: Theme.of(context).primaryColor,
        circularStrokeCap: CircularStrokeCap.round, // rounded ends
        animation: true,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rpsScore?.toString() ?? '- -',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
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
            GestureDetector(
              // onLongPress: () {
              //   CustomSnackBar.showInfo(
              //     context,
              //     'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of "de Finibus Bonorum et Malorum" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, "Lorem ipsum dolor sit amet..", comes from a line in section 1.10.32.',
              //   );
              // },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                width:
                    MediaQuery.of(context).size.width *
                    0.5 *
                    0.5, // 50% of available width
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
