import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehnway/Providers/user_provider.dart';
import 'package:vehnway/Widgets/avatar.dart';
import 'package:vehnway/services/auth_service.dart';
import 'package:vehnway/Widgets/form_overlay.dart';
import 'package:vehnway/Widgets/custom_dialogs.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/Pages/profile/constants/profile_constants.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/services/supabase/supabase_user_service.dart';

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
      builder: (BuildContext dialogContext) {
        return CustomConfirmationDialog(
          title: "Confirm Logout",
          content: "Are you sure you want to logout of this account?",
          confirmText: "Logout",
          confirmTextColor: ProfileConstants.deleteRed,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            _handleLogout();
          },
          titleStyle: ProfileConstants.nameStyle,
          contentStyle: ProfileConstants.labelStyle,
          backgroundColor: ProfileConstants.cardBackground,
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const CustomLoadingDialog(
            message: 'Logging out...',
            backgroundColor: AppColors.background,
          );
        },
      );

      // Sign out
      await AuthService().signOut();

      // Check if widget is still mounted before using context
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to login page
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil("/login", (route) => false);
      }
    } catch (e) {
      // Check if widget is still mounted before using context
      if (mounted) {
        // Close loading dialog if it's open
        Navigator.of(context).pop();

        // Show error message
        CustomSnackBar.showError(context, 'Failed to logout: $e');
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CustomConfirmationDialog(
          title: "Confirm deletion",
          content:
              "Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.",
          confirmText: "Delete",
          confirmTextColor: ProfileConstants.deleteRed,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            _handleDeleteAccount();
          },
          contentStyle: ProfileConstants.labelStyle,
          backgroundColor: ProfileConstants.cardBackground,
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final isPasswordUser = firebaseUser.providerData.any(
      (userInfo) => userInfo.providerId == 'password',
    );

    if (isPasswordUser) {
      final passwordController = TextEditingController();
      FormOverlay.show(
        context: context,
        title: 'Confirm Password',
        fields: [
          FormFieldConfig(
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock,
            controller: passwordController,
            isPassword: true,
          ),
        ],
        submitButtonText: 'Verify & Delete',
        onSubmit: () async {
          await AuthService().reauthenticateWithPassword(
            passwordController.text,
          );
          final user = userProvider.currentUser;
          if (user != null) {
            await SupabaseUserService().deleteUser();
            await AuthService().deleteAccount();
          }
        },
        onSuccess: () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil("/login", (route) => false);
            CustomSnackBar.showSuccess(context, 'Account deleted successfully');
          }
        },
        onError: (error) {
          if (mounted) {
            String errorMessage = error.toString();
            if (errorMessage.startsWith('Exception: ')) {
              errorMessage = errorMessage.substring(11);
            }
            CustomSnackBar.showError(context, errorMessage);
          }
        },
      );
    } else {
      try {
        // Show loading dialog for Google Auth
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const CustomLoadingDialog(
              message: 'Confirming login...',
              backgroundColor: AppColors.background,
            );
          },
        );

        await AuthService().reauthenticateWithGoogle();

        final user = userProvider.currentUser;

        if (user != null) {
          // 1. Delete from Supabase
          await SupabaseUserService().deleteUser();

          // 2. Delete from Firebase and Sign out
          await AuthService().deleteAccount();
        }

        if (mounted) {
          // Close loading dialog
          Navigator.of(context).pop();

          // Navigate to login page
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil("/login", (route) => false);

          CustomSnackBar.showSuccess(context, 'Account deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          // Close loading dialog if open
          Navigator.of(context).pop();

          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }

          CustomSnackBar.showError(context, errorMessage);
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    File? croppedFileToDelete;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);

        // Crop Image
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: AppColors.background,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
              rotateButtonsHidden: true,
              rotateClockwiseButtonHidden: true,
            ),
          ],
        );

        if (croppedFile == null) return; // User cancelled cropping

        final File finalFile = File(croppedFile.path);
        croppedFileToDelete = finalFile;

        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.currentUser;

        if (user == null) {
          CustomSnackBar.showError(context, 'User not logged in');
          return;
        }

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const CustomLoadingDialog(
              message: 'Uploading profile picture...',
              backgroundColor: AppColors.background,
            );
          },
        );

        final imageUrl = await SupabaseUserService().uploadProfilePicture(
          finalFile,
          user.firebaseUid,
        );

        await SupabaseUserService().updateUserProfile(
          fullName: user.name,
          username: user.username,
          profilePictureUrl: imageUrl,
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
        await userProvider.refresh();
        if (mounted) {
          CustomSnackBar.showSuccess(
            context,
            'Profile picture updated successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if open
        Navigator.of(context).maybePop();
        CustomSnackBar.showError(
          context,
          'Failed to update profile picture: $e',
        );
      }
    } finally {
      // Clean up the temporary cropped file
      if (croppedFileToDelete != null) {
        try {
          if (await croppedFileToDelete.exists()) {
            await croppedFileToDelete.delete();
          }
        } catch (e) {
          debugPrint('Failed to clean up temporary file: $e');
        }
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
        FormFieldConfig(
          label: 'Name',
          hint: 'Enter your full name',
          icon: Icons.person,
          controller: _nameController,
        ),
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

        await SupabaseUserService().updateUserProfile(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone:
              _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
          address:
              _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
        );

        // Refresh user data
        await userProvider.refresh();
      },
      onSuccess: () {
        if (mounted) {
          CustomSnackBar.showSuccess(context, 'Profile updated successfully!');
        }
      },
      onError: (error) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            'Failed to update profile: ${error.toString()}',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(gradient: ProfileConstants.gradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Provider.of<UserProvider>(context, listen: false).refresh();
            },
            color: ProfileConstants.accentPurple,
            backgroundColor: ProfileConstants.cardBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 25),
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
            Text(
              '@${user?.username ?? 'Guest'}',
              style: ProfileConstants.usernameStyle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        final profilePic = user?.profilePictureUrl;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Hero(
              tag: 'profile-avatar',
              child: Avatar(
                imageUrl: profilePic,
                size: ProfileConstants.avatarSize,
              ),
            ),
            Positioned(
              bottom: -10,
              right: -10,
              child: IconButton(
                onPressed: _pickAndUploadImage,
                icon: const Icon(FontAwesomeIcons.penToSquare),
                color: Colors.white,
                iconSize: 18,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;
          final liquid = user?.liquidEllar ?? 0;
          final frozen = user?.frozenEllar ?? 0;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatMetric(
                    icon: FontAwesomeIcons.road,
                    iconColor: Colors.blueGrey,
                    value: (user?.distance ?? 0).toInt(),
                    unit: 'km',
                    label: 'Covered',
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withAlpha(70),
                  ),
                  _buildStatMetric(
                    icon: FontAwesomeIcons.droplet,
                    iconColor: Colors.cyan,
                    value: liquid,
                    unit: '',
                    label: 'Liquid Ellar',
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withAlpha(70),
                  ),
                  _buildStatMetric(
                    icon: FontAwesomeIcons.snowflake,
                    iconColor: Colors.lightBlueAccent,
                    value: frozen,
                    unit: '',
                    label: 'Frozen Ellar',
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withAlpha(70),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: ProfileConstants.dividerColor,
                  borderRadius: BorderRadius.circular(67),
                ),
              ),
            ],
          );
        },
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
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color:
                  (value > 0)
                      ? iconColor
                      : const Color.fromARGB(255, 218, 218, 218),
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: Text(
            unit.isEmpty ? value.toString() : '${value.toString()} $unit',
            textAlign: TextAlign.center,
            style: ProfileConstants.metricLabelStyle,
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ProfileConstants.metricLabelStyle,
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Information',
                    style: ProfileConstants.sectionTitleStyle,
                  ),
                  TextButton(
                    onPressed: () => _showEditUserDetailsOverlay(context),
                    child: Text(
                      'Edit',
                      style: ProfileConstants.labelStyle.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Email',
                user?.email ?? 'not provided',
                isFirst: true,
              ),
              SizedBox(height: 3),
              _buildInfoRow('Phone', user?.phone ?? 'not provided'),
              SizedBox(height: 3),
              _buildInfoRow(
                'Address',
                user?.address ?? 'not provided',
                isLast: true,
              ),
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
          _buildSettingRow('Notification', false, isFirst: true),
          SizedBox(height: 3),
          _buildSettingRow('Dark Mode', true),
          SizedBox(height: 3),
          // GestureDetector(
          //   onTap: () => _showUpdateVehicleOverlay(context),
          //   child: _buildInfoRow('Update Vehicle Details', '', isLast: false),
          // ),
          // SizedBox(height: 3),
          _buildDeleteAccountRow(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      height: ProfileConstants.cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 14, 14, 26),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
          topRight: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
          bottomLeft: Radius.circular(isLast ? ProfileConstants.cardRadius : 0),
          bottomRight: Radius.circular(
            isLast ? ProfileConstants.cardRadius : 0,
          ),
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

  Widget _buildSettingRow(
    String label,
    bool isEnabled, {
    bool isFirst = false,
  }) {
    return GestureDetector(
      onTap: () {
        CustomSnackBar.showInfo(context, 'Feature not yet implemented');
      },
      child: Container(
        height: ProfileConstants.cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: ProfileConstants.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
            topRight: Radius.circular(
              isFirst ? ProfileConstants.cardRadius : 0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ProfileConstants.labelStyle),
            _buildToggleSwitch(isEnabled),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(bool isEnabled) {
    return Container(
      width: 38,
      height: 20,
      decoration: BoxDecoration(
        color:
            isEnabled
                ? Theme.of(context).primaryColor.withAlpha(70)
                : Colors.grey.withAlpha(70),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isEnabled ? Theme.of(context).primaryColor : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountRow() {
    return GestureDetector(
      onTap: () => _showDeleteAccountDialog(context),
      child: Container(
        height: ProfileConstants.cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ProfileConstants.cardBackground,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(ProfileConstants.cardRadius),
            bottomRight: Radius.circular(ProfileConstants.cardRadius),
          ),
        ),
        child: const Center(
          child: Text('Delete Account', style: ProfileConstants.deleteStyle),
        ),
      ),
    );
  }
}
