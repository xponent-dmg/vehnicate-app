import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/services/auth_service.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/Widgets/form_overlay.dart';
import 'package:vehnicate_frontend/Widgets/custom_dialogs.dart';
import 'package:vehnicate_frontend/Widgets/custom_snackbar.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';
import 'package:vehnicate_frontend/utils/extensions.dart';

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
          title: context.loc.confirmLogout,
          content: context.loc.confirmLogoutMessage,
          confirmText: context.loc.logout,
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
          return CustomLoadingDialog(
            message: context.loc.loggingOut,
            backgroundColor: const Color(0xFF2d2d44),
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
        CustomSnackBar.showError(
          context,
          context.loc.failedToLogout(e.toString()),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CustomConfirmationDialog(
          title: context.loc.confirmDeletion,
          content: context.loc.confirmDeletionMessage,
          confirmText: context.loc.delete,
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
        title: context.loc.confirmPasswordTitle,
        fields: [
          FormFieldConfig(
            label: context.loc.passwordHint,
            hint: context.loc.passwordHint,
            icon: Icons.lock,
            controller: passwordController,
            obscureText: true,
          ),
        ],
        submitButtonText: context.loc.verifyAndDelete,
        onSubmit: () async {
          await AuthService().reauthenticateWithPassword(
            passwordController.text,
          );
          final user = userProvider.currentUser;
          if (user != null) {
            await SupabaseService().deleteUser(user.firebaseUid);
            await AuthService().deleteAccount();
          }
        },
        onSuccess: () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil("/login", (route) => false);
            CustomSnackBar.showSuccess(
              context,
              context.loc.accountDeletedSuccessfully,
            );
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
            return CustomLoadingDialog(
              message: context.loc.confirmingLogin,
              backgroundColor: const Color(0xFF2d2d44),
            );
          },
        );

        await AuthService().reauthenticateWithGoogle();

        final user = userProvider.currentUser;

        if (user != null) {
          // 1. Delete from Supabase
          await SupabaseService().deleteUser(user.firebaseUid);

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
      title: context.loc.editProfileTitle,
      fields: [
        FormFieldConfig(
          label: context.loc.nameLabel,
          hint: context.loc.nameHint,
          icon: Icons.person,
          controller: _nameController,
        ),
        FormFieldConfig(
          label: context.loc.usernameLabel,
          hint: context.loc.usernameHint,
          icon: Icons.alternate_email,
          controller: _usernameController,
        ),
        FormFieldConfig(
          label: context.loc.phoneLabel,
          hint: context.loc.phoneHint,
          icon: Icons.phone,
          controller: _phoneController,
          isRequired: false,
        ),
        FormFieldConfig(
          label: context.loc.addressLabel,
          hint: context.loc.addressHint,
          icon: Icons.location_on,
          controller: _addressController,
          isRequired: false,
        ),
      ],
      submitButtonText: context.loc.updateProfileButton,
      onSubmit: () async {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          throw Exception('User not logged in');
        }

        await SupabaseService().updateUserProfile(
          userId: firebaseUser.uid,
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
          CustomSnackBar.showSuccess(
            context,
            context.loc.profileUpdatedSuccessfully,
          );
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
                  // _buildStatsSection(),
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
        child: Text(context.loc.logOut, style: ProfileConstants.logoutStyle),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        return Column(
          children: [
            // _buildAvatar(),
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
                  Text(
                    context.loc.personalInformation,
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
                context.loc.emailLabel,
                user?.email ?? context.loc.mailNotGiven,
                isFirst: true,
              ),
              SizedBox(height: 3),
              _buildInfoRow(
                context.loc.phoneLabel,
                user?.phone ?? context.loc.phoneNotGiven,
              ),
              SizedBox(height: 3),
              _buildInfoRow(
                context.loc.addressLabel,
                user?.address ?? context.loc.addressNotUpdated,
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
          Text(context.loc.settings, style: ProfileConstants.sectionTitleStyle),
          const SizedBox(height: 8),
          _buildSettingRow('Notification', true, isFirst: true),
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
    return Container(
      height: ProfileConstants.cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: ProfileConstants.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
          topRight: Radius.circular(isFirst ? ProfileConstants.cardRadius : 0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ProfileConstants.labelStyle),
          _buildToggleSwitch(isEnabled),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(bool isEnabled) {
    return Container(
      width: 38,
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(70),
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
