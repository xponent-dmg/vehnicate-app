import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vehnicate_frontend/services/auth_service.dart';
import 'package:vehnicate_frontend/Pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Constants and Theme
class ProfileConstants {
  // Colors
  static const Color primaryBackground = Color(0xFF01010D);
  static const Color cardBackground = Color(0xFF0E0E1A);
  static const Color accentPurple = Color(0xFF765FD1);
  static const Color lightPurple = Color(0xFF9217BB);
  static const Color darkPurple = Color(0xFF403862);
  static const Color logoutRed = Color(0xFFF24E1E);
  static const Color deleteRed = Color(0xA5FF0000);
  static const Color dividerColor = Color(0x33B0A4AD);

  // Text Styles
  static const TextStyle nameStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle usernameStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle valueStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle logoutStyle = TextStyle(
    color: logoutRed,
    fontSize: 10,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle deleteStyle = TextStyle(
    color: deleteRed,
    fontSize: 15,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle metricValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle metricLabelStyle = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  // Dimensions
  static const double cardHeight = 50.0;
  static const double cardRadius = 8.0;
  static const double avatarSize = 87.0;
  static const double metricCircleSize = 60.0;
  static const double horizontalPadding = 28.0;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>{
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final details = await getUserdetails();
      setState(() {
        userDetails = details;
      });
      print("Loaded user details: $userDetails");
    } catch (e) {
      print("Error loading user details: $e");
    }
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
        Navigator.of(
          context,
        ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileConstants.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 25),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                _buildProfileSection(),
                _buildStatsSection(),
                const SizedBox(height: 14),
                _buildPersonalInfoSection(),
                const SizedBox(height: 30),
                _buildSettingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(context) {
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

  Widget _buildLogoutButton(context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: ProfileConstants.logoutRed),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('Log out', style: ProfileConstants.logoutStyle),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        _buildAvatar(),
        const SizedBox(height: 16),
        Text("${userDetails?['name']??'Guest'}", style: ProfileConstants.nameStyle),
        const SizedBox(height: 4),
        Text('@${userDetails?['username']??'Guest'}', style: ProfileConstants.usernameStyle),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: ProfileConstants.avatarSize,
          height: ProfileConstants.avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(image: AssetImage("assets/logo.png"), fit: BoxFit.cover),
            boxShadow: const [BoxShadow(color: ProfileConstants.lightPurple, blurRadius: 4, offset: Offset(0, -2))],
          ),
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: IconButton(
            onPressed: () {},
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
                value: '30',
                unit: 'km',
                label: 'Covered',
                backgroundColor: ProfileConstants.darkPurple,
              ),
              _buildStatMetric(
                icon: FontAwesomeIcons.fire,
                value: '7',
                unit: 'days',
                label: 'Streak',
                backgroundColor: ProfileConstants.darkPurple,
              ),
              _buildProgressIndicator(),
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
    required String value,
    required String unit,
    required String label,
    required Color backgroundColor,
  }) {
    return Column(
      children: [
        Container(
          width: ProfileConstants.metricCircleSize,
          height: ProfileConstants.metricCircleSize,
          decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
          child: Center(child: Icon(icon, color: Colors.white, size: 32)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: Text('$value $unit', textAlign: TextAlign.center, style: ProfileConstants.metricLabelStyle),
        ),
        SizedBox(width: 64, child: Text(label, textAlign: TextAlign.center, style: ProfileConstants.metricLabelStyle)),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 30,
          lineWidth: 8,
          percent: 0.8,
          backgroundColor: ProfileConstants.darkPurple,
          // arcBackgroundColor: ProfileConstants.darkPurple,
          // arcType: ArcType.FULL_REVERSED,
          progressColor: ProfileConstants.accentPurple,
          circularStrokeCap: CircularStrokeCap.round, // rounded ends
          animation: true,
          center: Text("${userDetails?['rpsscore']??'50'}", style: ProfileConstants.metricValueStyle),
        ),
        SizedBox(height: 5),
        SizedBox(
          width: 65,
          child: Text("Overall Performance", style: ProfileConstants.metricLabelStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: ProfileConstants.sectionTitleStyle),
          const SizedBox(height: 8),
          _buildInfoRow('Email', '${userDetails?['email']??'mail not given'}', isFirst: true),
          SizedBox(height: 3),
          _buildInfoRow('Phone', '${userDetails?['phone']??'phone not given'}'),
          SizedBox(height: 3),
          _buildInfoRow('Address', '${userDetails?['address']??'Address not updated'}', isLast: true),
        ],
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
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/editdetails"),
            child: _buildInfoRow('Update Details', '', isLast: false),
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
Future<Map<String, dynamic>?> getUserdetails() async {
  try {
    // Get current Firebase user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    print("Firebase User ID: ${firebaseUser?.uid}");

    if (firebaseUser == null) {
      print("No Firebase user found");
      return null;
    }

    // Query Supabase using Firebase UID
    final username = await Supabase.instance.client
        .from('userdetails')
        .select()
        .eq('firebaseuid', firebaseUser.uid)
        .single();
    
    print("Supabase response: $username");
    return username;
  } catch (e) {
    print("Error getting username: $e");
    return null;
  }
}