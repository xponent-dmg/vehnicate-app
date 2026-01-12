import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/services/auth_service.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/Widgets/form_overlay.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';

// Constants and Theme
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Form controllers for edit user details
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Form controllers for edit vehicle details
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
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleModelController.dispose();
    _registrationController.dispose();
    _insuranceController.dispose();
    _pucDateController.dispose();
    super.dispose();
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ProfileConstants.cardBackground,
          elevation: 5,
          title: Text("Confirm Logout", style: ProfileConstants.nameStyle),
          content: Text("Are you sure you want to logout of this account?", style: ProfileConstants.labelStyle),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => _handleLogout(context),
              child: Text("Logout", style: ProfileConstants.deleteStyle),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Color(0xFF2d2d44),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8E44AD)),
                  SizedBox(width: 20),
                  Text('Logging out...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        },
      );

      // Sign out
      await AuthService().signOut();

      // Check if widget is still mounted before using context
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to login page
        Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
      }
    } catch (e) {
      // Check if widget is still mounted before using context
      if (context.mounted) {
        // Close loading dialog if it's open
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to logout: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showEditUserDetailsOverlay(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    // Pre-fill controllers with current values
    _nameController.text = user?.name ?? '';
    _usernameController.text = user?.username ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.address ?? '';

    FormOverlay.show(
      context: context,
      title: 'Edit Profile',
      fields: [
        FormFieldConfig(label: 'Name', hint: 'Enter your full name', icon: Icons.person, controller: _nameController),
        FormFieldConfig(
          label: 'Username',
          hint: 'Enter your username',
          icon: Icons.alternate_email,
          controller: _usernameController,
        ),
        FormFieldConfig(
          label: 'Phone',
          hint: 'Enter your phone number',
          icon: Icons.phone,
          controller: _phoneController,
          isRequired: false,
        ),
        FormFieldConfig(
          label: 'Address',
          hint: 'Enter your address',
          icon: Icons.location_on,
          controller: _addressController,
          isRequired: false,
        ),
      ],
      submitButtonText: 'Update Profile',
      onSubmit: () async {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          throw Exception('User not logged in');
        }

        await SupabaseService().updateUserProfile(
          userId: firebaseUser.uid,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        );

        // Refresh user data
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).refresh();
        }
      },
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
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
              content: Text('Failed to update profile: ${error.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _showUpdateVehicleOverlay(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

    if (vehicleProvider.vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No vehicle found to update. Please add a vehicle first.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Pre-fill controllers with current vehicle values
    _vehicleModelController.text = vehicleProvider.vehicleModel ?? '';
    _registrationController.text = vehicleProvider.vehicleRegistration ?? '';
    _insuranceController.text = vehicleProvider.vehicleInsurance ?? '';
    _pucDateController.text = vehicleProvider.vehiclePUC ?? '';

    FormOverlay.show(
      context: context,
      title: 'Update Vehicle',
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
      submitButtonText: 'Update Vehicle',
      onSubmit: () async {
        final vehicleId = vehicleProvider.vehicleId;
        if (vehicleId == null) return;

        await SupabaseService().updateVehicleDetails(
          vehicleId: vehicleId,
          model: _vehicleModelController.text.trim(),
          registration: _registrationController.text.trim(),
          insurance: _insuranceController.text.trim(),
          puc: _pucDateController.text.trim().isEmpty ? null : _pucDateController.text.trim(),
        );

        // Refresh vehicle data
        if (mounted) {
          await Provider.of<VehicleProvider>(context, listen: false).refresh();
        }
      },
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle updated successfully!'),
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
              content: Text('Failed to update vehicle: ${error.toString()}'),
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
    return Scaffold(
      backgroundColor: ProfileConstants.primaryBackground,
      body: SafeArea(
        child: LiquidPullToRefresh(
          onRefresh: () async {
            await Provider.of<UserProvider>(context, listen: false).refresh();
          },
          color: ProfileConstants.primaryBackground,
          backgroundColor: ProfileConstants.accentPurple,
          showChildOpacityTransition: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 25),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildProfileSection(context),
                  _buildStatsSection(),
                  const SizedBox(height: 14),
                  _buildPersonalInfoSection(context),
                  const SizedBox(height: 30),
                  _buildSettingsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(10),
        splashColor: ProfileConstants.logoutRed.withOpacity(0.3),
        highlightColor: ProfileConstants.logoutRed.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: ProfileConstants.logoutRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Log out', style: ProfileConstants.logoutStyle),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        return Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Guest', style: ProfileConstants.nameStyle),
            const SizedBox(height: 4),
            Text('@${user?.username ?? 'Guest'}', style: ProfileConstants.usernameStyle),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: 'profile-avatar',
          child: Container(
            width: ProfileConstants.avatarSize,
            height: ProfileConstants.avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(image: AssetImage("assets/logo.png"), fit: BoxFit.cover),
              boxShadow: const [BoxShadow(color: ProfileConstants.lightPurple, blurRadius: 4, offset: Offset(0, -2))],
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: IconButton(
            onPressed: () => _showEditUserDetailsOverlay(context),
            icon: Icon(FontAwesomeIcons.penToSquare),
            color: Colors.white,
            iconSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatMetric(
                icon: FontAwesomeIcons.road,
                iconColor: Colors.blueGrey,
                value: 0,
                unit: 'km',
                label: 'Covered',
                backgroundColor: ProfileConstants.darkPurple,
              ),
              _buildStatMetric(
                icon: FontAwesomeIcons.fire,
                iconColor: Colors.deepOrangeAccent,
                value: 0,
                unit: 'days',
                label: 'Streak',
                backgroundColor: ProfileConstants.darkPurple,
              ),
              _buildProgressIndicator(context),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            height: 2,
            decoration: BoxDecoration(color: ProfileConstants.dividerColor, borderRadius: BorderRadius.circular(67)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric({
    required IconData icon,
    required int value,
    required String unit,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: ProfileConstants.metricCircleSize,
          height: ProfileConstants.metricCircleSize,
          decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
          child: Center(
            child: Icon(icon, color: (value > 0) ? iconColor : const Color.fromARGB(255, 218, 218, 218), size: 32),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: Text(
            '${value.toString()} $unit',
            textAlign: TextAlign.center,
            style: ProfileConstants.metricLabelStyle,
          ),
        ),
        SizedBox(width: 64, child: Text(label, textAlign: TextAlign.center, style: ProfileConstants.metricLabelStyle)),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final rpsScore = context.watch<UserProvider>().currentUser?.rpsScore;
    return Column(
      children: [
        Hero(
          tag: 'rps-score-indicator',
          child: CircularPercentIndicator(
            radius: 30,
            lineWidth: 8,
            percent: (rpsScore ?? 0) / 100,
            backgroundColor: ProfileConstants.darkPurple,
            progressColor: ProfileConstants.accentPurple,
            circularStrokeCap: CircularStrokeCap.round, // rounded ends
            animation: true,
            center: Text("${rpsScore ?? '--'}", style: ProfileConstants.metricValueStyle),
          ),
        ),
        SizedBox(height: 5),
        SizedBox(
          width: 70,
          child: Text("Overall Performance", style: ProfileConstants.metricLabelStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information', style: ProfileConstants.sectionTitleStyle),
              const SizedBox(height: 8),
              _buildInfoRow('Email', user?.email ?? 'mail not given', isFirst: true),
              SizedBox(height: 3),
              _buildInfoRow('Phone', user?.phone ?? 'phone not given'),
              SizedBox(height: 3),
              _buildInfoRow('Address', user?.address ?? 'Address not updated', isLast: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: ProfileConstants.sectionTitleStyle),
          const SizedBox(height: 8),
          _buildSettingRow('Notification', true, isFirst: true),
          SizedBox(height: 3),
          _buildSettingRow('Dark Mode', true),
          SizedBox(height: 3),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showUpdateVehicleOverlay(context),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: _buildInfoRow('Update Vehicle Details', '', isLast: false),
            ),
          ),
          SizedBox(height: 3),
          _buildDeleteAccountRow(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isFirst = false, bool isLast = false}) {
    return Container(
      height: ProfileConstants.cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 14, 14, 26),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
          topRight: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
          bottomLeft: Radius.circular(isLast ? ProfileConstants.cardRadius : 0),
          bottomRight: Radius.circular(isLast ? ProfileConstants.cardRadius : 0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ProfileConstants.labelStyle),
          Flexible(
            child: Text(
              value,
              style: ProfileConstants.valueStyle,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, bool isEnabled, {bool isFirst = false}) {
    return Container(
      height: ProfileConstants.cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ProfileConstants.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
          topRight: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: ProfileConstants.labelStyle), _buildToggleSwitch(isEnabled)],
      ),
    );
  }

  Widget _buildToggleSwitch(bool isEnabled) {
    return Container(
      width: 38,
      height: 20,
      decoration: BoxDecoration(color: ProfileConstants.darkPurple, borderRadius: BorderRadius.circular(20)),
      child: Align(
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isEnabled ? ProfileConstants.accentPurple : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountRow() {
    return Container(
      height: ProfileConstants.cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: ProfileConstants.cardBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ProfileConstants.cardRadius),
          bottomRight: Radius.circular(ProfileConstants.cardRadius),
        ),
      ),
      child: const Center(child: Text('Delete Account', style: ProfileConstants.deleteStyle)),
    );
  }
}
