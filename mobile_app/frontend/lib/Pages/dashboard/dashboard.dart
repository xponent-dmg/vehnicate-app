import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/Widgets/reveal_text.dart';
import 'package:vehnicate_frontend/Widgets/typewriter_text.dart';
import 'package:vehnicate_frontend/Widgets/form_overlay.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Key _greetingKey = UniqueKey();

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
      backgroundColor: ProfileConstants.primaryBackground,
      body: SafeArea(
        child: LiquidPullToRefresh(
          onRefresh: () async {
            await Future.wait([
              Provider.of<UserProvider>(context, listen: false).refresh(),
              Provider.of<VehicleProvider>(context, listen: false).refresh(),
            ]);
            if (mounted) {
              setState(() {
                _greetingKey = UniqueKey();
              });
            }
          },
          color: ProfileConstants.primaryBackground,
          backgroundColor: Color(0xFF8E44AD),
          showChildOpacityTransition: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                        if (!userProvider.isLoading && userProvider.currentUser != null) {
                        final firstName = userProvider.currentUser?.name?.split(' ').first ?? '';
                        return TypewriterText(
                          "Hey $firstName, welcome to vehnicate",
                          key: _greetingKey,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 24),
                  // Start Card
                  _startCard(context),
                  SizedBox(height: 24),
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
                  SizedBox(height: 24),
                  // Weekly Challenge
                  Container(
                    decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Drive smoothly',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF8E44AD).withAlpha(51),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFF8E44AD), width: 1),
                              ),
                              child: Text(
                                'Weekly',
                                style: TextStyle(color: Color(0xFF8E44AD), fontWeight: FontWeight.w500, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Maintain constant acceleration for 50 km',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reward: 500 points', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              '50%',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(color: Color(0xFF3d3d54), borderRadius: BorderRadius.circular(3)),
                          child: Stack(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5 * 0.5, // 50% of available width
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Color(0xFF8E44AD),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
          puc: _pucDateController.text.trim().isEmpty ? null : _pucDateController.text.trim(),
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
              backgroundColor: Color(0xFF8E44AD),
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

  Widget _selectedCarCard(BuildContext context) {
    return Expanded(
      child: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          final hasVehicle = vehicleProvider.vehicleId != null;

          return Container(
            height: 160,
            decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
            padding: EdgeInsets.all(17),
            child:
                hasVehicle
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicleProvider.vehicleModel ?? 'No vehicle',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  vehicleProvider.vehicleRegistration ?? '------',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                            Spacer(),
                            Column(
                              children: [
                                Icon(Icons.swap_horiz_rounded, color: Colors.white),
                                Text('0 km', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Color(0xFF3d3d54), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Icon(Icons.directions_car, color: Colors.white70, size: 30)),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAddVehicleOverlay(context),
                            borderRadius: BorderRadius.circular(10),
                            splashColor: Color(0xFF8E44AD).withOpacity(0.4),
                            highlightColor: Color(0xFF8E44AD).withOpacity(0.2),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFF8E44AD).withAlpha(51),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFF8E44AD), width: 1),
                              ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Add Vehicle',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                        SizedBox(height: 16),
                        Text('Tap to add your vehicle', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        SizedBox(height: 8),
                        // GestureDetector(
                        //   onTap: () => _showAddVehicleOverlay(context),
                        //   child: Container(
                        //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        //     decoration: BoxDecoration(
                        //       color: Color(0xFF8E44AD),
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     child: Text(
                        //       'Add Now',
                        //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
          );
        },
      ),
    );
  }
}

Widget _header(context) {
  return Container(
    height: 90,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title section
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF8E44AD).withAlpha(51),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF8E44AD), width: 1),
              ),
              child: Row(
                children: [
                    ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      "assets/vehnicate_logo_padded.png",
                      height: 32,
                      width: 32,
                    ),
                    ),
                    SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('vehnicate', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      RevealText(
                        'calm in the chaos',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                        duration: Duration(milliseconds: 2000),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Actions section
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            customBorder: CircleBorder(),
            splashColor: Color(0xFF8E44AD).withOpacity(0.4),
            highlightColor: Color(0xFF8E44AD).withOpacity(0.2),
            child: Hero(
              tag: 'profile-avatar',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF8E44AD),
                child: Transform.translate(offset: const Offset(0, 1.2), child: Image.asset("assets/logo.png")),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
// Widget _textField({required String hintText, required IconData icon, required Color color}) {
//   return Container(
//     decoration: BoxDecoration(color: ProfileConstants.primaryBackground, borderRadius: BorderRadius.circular(12)),
//     child: TextField(
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//         prefixIcon: Icon(icon, color: color, size: 17),
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       ),
//       style: TextStyle(color: Colors.white),
//     ),
//   );
// }

Widget _startCard(BuildContext context) {
  return Container(
    decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, "/imu");
                },
                borderRadius: BorderRadius.circular(25),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: Color(0xFF8E44AD), borderRadius: BorderRadius.circular(25)),
                  child: Text(
                    'Start Drive',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xFF8E44AD), shape: BoxShape.circle),
              child: Icon(Icons.home, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, "/map");
                },
                customBorder: CircleBorder(),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Color(0xFF3d3d54), shape: BoxShape.circle),
                  child: Icon(Icons.map, color: Colors.white70, size: 20),
                ),
              ),
            ),
            SizedBox(width: 8),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.pushNamed(context, "/camera");
            //   },
            //   child: Container(
            //     padding: EdgeInsets.all(8),
            //     decoration: BoxDecoration(color: Color(0xFF3d3d54), shape: BoxShape.circle),
            //     child: Icon(Icons.camera_alt, color: Colors.white70, size: 20),
            //   ),
            // ),
          ],
        ),
        // SizedBox(height: 20),
        // _textField(hintText: "Current location", icon: FontAwesomeIcons.locationCrosshairs, color: Color(0xFF8E44AD)),

        // SizedBox(height: 12),
        // _textField(hintText: 'Where to?', icon: FontAwesomeIcons.locationDot, color: Colors.white54),
      ],
    ),
  );
}

Widget _rpsScoreCard(BuildContext context) {
  final rpsScore = context.watch<UserProvider>().currentUser?.rpsScore;
  return Expanded(
    child: Container(
      height: 160,
      decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.all(20),
      child: CircularPercentIndicator(
        radius: 60,
        lineWidth: 10,
        percent: (rpsScore ?? 0) / 100,
        backgroundColor: ProfileConstants.darkPurple,
        progressColor: Color(0xFF8E44AD),
        circularStrokeCap: CircularStrokeCap.round, // rounded ends
        animation: true,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rpsScore?.toString() ?? '- -',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.5, vertical: 2.5),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF8E44AD)),
                borderRadius: BorderRadius.circular(10),
                color: Color(0xFF8E44AD).withAlpha(51),
              ),
              child: Text('RPS Score', style: TextStyle(color: Colors.white70, fontSize: 8)),
            ),
          ],
        ),
      ),
    ),
  );
}
