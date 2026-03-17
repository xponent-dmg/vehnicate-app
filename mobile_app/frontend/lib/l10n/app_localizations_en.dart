// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'vehnicate';

  @override
  String get vehnicateTagline => 'calm in the chaos';

  @override
  String get vehiclesCommunicate => 'vehicles+communicate';

  @override
  String get vehnicate2025 => 'vehnicate@2025';

  @override
  String get vehnicateTab => 'vehnicate';

  @override
  String get navigationTab => 'navigation';

  @override
  String get garageTab => 'your garage';

  @override
  String get analyticsTab => 'analytics';

  @override
  String get swap => 'Swap';

  @override
  String get loginEmailHint => 'Email address';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get orConnectWith => 'or connect with';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get signupButton => 'Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signIn => 'Sign in';

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String get verifyEmailHeading => 'Verify your email address';

  @override
  String verifyEmailMessage(String email) {
    return 'We have sent a verification email to:\n$email';
  }

  @override
  String get verifyEmailInstruction =>
      'Please check your email and click on the verification link.';

  @override
  String get iHaveVerifiedEmail => 'I have verified my email';

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String resendEmailIn(int seconds) {
    return 'Resend Email in $seconds s';
  }

  @override
  String get emailVerified => 'Email Verified!';

  @override
  String get redirectingToHome => 'Redirecting to home...';

  @override
  String get cancelAndLogout => 'Cancel & Log Out';

  @override
  String get checkingVerification => 'Checking verification...';

  @override
  String get emailNotVerified =>
      'Email not verified yet. Please check your inbox.';

  @override
  String errorSendingVerificationEmail(String error) {
    return 'Error sending verification email: $error';
  }

  @override
  String get completeProfileTitle => 'Complete Your Profile';

  @override
  String get tellUsMore => 'Tell us more about yourself';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get usernameLabel => 'Username';

  @override
  String get vehicleDetailsOptional => 'Vehicle Details (Optional)';

  @override
  String get vehicleModelLabel => 'Vehicle Model';

  @override
  String get vehicleYearLabel => 'Vehicle Year';

  @override
  String get vehicleRegistrationLabel => 'Vehicle Registration';

  @override
  String get continueButton => 'Continue';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get pleaseEnterFullName => 'Please enter your full name';

  @override
  String get pleaseEnterUsername => 'Please enter a username';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String get startDrive => 'Start Drive';

  @override
  String get rpsScore => 'RPS Score';

  @override
  String get driveSmoothly => 'Drive smoothly';

  @override
  String get weekly => 'Weekly';

  @override
  String get maintainConstantAcceleration =>
      'Maintain constant acceleration for 50 km';

  @override
  String reward(int points) {
    return 'Reward: $points points';
  }

  @override
  String get addVehicle => 'Add Vehicle';

  @override
  String get addAnotherVehicle => 'Add another vehicle';

  @override
  String get tapToAddVehicle => 'Tap to add your vehicle';

  @override
  String get selectVehicle => 'Select Vehicle';

  @override
  String get noVehiclesAvailable => 'No vehicles available';

  @override
  String get vehicleAddedSuccessfully => 'Vehicle added successfully!';

  @override
  String failedToAddVehicle(String error) {
    return 'Failed to add vehicle: $error';
  }

  @override
  String get noVehicle => 'No vehicle';

  @override
  String get vehicleRegistrationPlaceholder => '------';

  @override
  String get viewDetails => 'View details';

  @override
  String get hillViewMumbai => 'Hill view, Mumbai';

  @override
  String get distanceCovered => 'Distance Covered';

  @override
  String get rpsScoreLabel => 'RPS Score';

  @override
  String get documentCenter => 'Document Center';

  @override
  String get insurancePolicy => 'Insurance Policy';

  @override
  String get active => 'Active';

  @override
  String expires(String date) {
    return 'Expires: $date';
  }

  @override
  String get rcDetails => 'RC Details';

  @override
  String get verified => 'Verified';

  @override
  String get pucCertificate => 'PUC Certificate';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String get notUploaded => 'Not Uploaded';

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get logisticsHistory => 'Logistics & History';

  @override
  String parkedNear(String location) {
    return 'Parked near $location';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String get serviceHistory => 'Service History';

  @override
  String lastService(String service) {
    return 'Last: $service (Jan 24)';
  }

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String expensesAmount(String amount) {
    return 'Rs $amount';
  }

  @override
  String get roadsideAssist => 'Roadside Assist';

  @override
  String get premiumPlan => 'Premium Plan';

  @override
  String get tapToCall => 'Tap to Call';

  @override
  String get deleteVehicle => 'Delete Vehicle';

  @override
  String get deleteVehicleConfirmation =>
      'Are you sure you want to delete this vehicle? This action cannot be undone.';

  @override
  String get deleting => 'Deleting...';

  @override
  String errorDeletingVehicle(String error) {
    return 'Error deleting vehicle: $error';
  }

  @override
  String get unknownCar => 'Unknown Car';

  @override
  String get kmUnit => 'km';

  @override
  String get hoursUnit => 'h';

  @override
  String get minutesUnit => 'm';

  @override
  String get logOut => 'Log out';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get edit => 'Edit';

  @override
  String get emailLabel => 'Email';

  @override
  String get mailNotGiven => 'mail not given';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phoneNotGiven => 'phone not given';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressNotUpdated => 'Address not updated';

  @override
  String get settings => 'Settings';

  @override
  String get notification => 'Notification';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get covered => 'Covered';

  @override
  String get streak => 'Streak';

  @override
  String get overallPerformance => 'Overall Performance';

  @override
  String get days => 'days';

  @override
  String get imuCameraTitle => 'IMU + Camera Data Collector';

  @override
  String get dataCollectionStatistics => 'Data Collection Statistics';

  @override
  String get imuData => 'IMU Data';

  @override
  String get images => 'Images';

  @override
  String pendingImages(int count) {
    return 'Pending Images: $count';
  }

  @override
  String uploaded(int count) {
    return 'Uploaded: $count';
  }

  @override
  String get startCollection => 'Start Collection';

  @override
  String get stopCollection => 'Stop Collection';

  @override
  String get stopping => 'Stopping...';

  @override
  String get uploadNow => 'Upload Now';

  @override
  String get uploadTriggered => 'Upload triggered';

  @override
  String get dataCollectionActive => 'Data Collection Active';

  @override
  String get dataCollectionStopped => 'Data Collection Stopped';

  @override
  String get cameraNotReady => 'Camera not ready';

  @override
  String get enterStartPosition => 'Enter Start Position';

  @override
  String get startX => 'Start X';

  @override
  String get startY => 'Start Y';

  @override
  String get startZ => 'Start Z';

  @override
  String get startCollectionButton => 'Start Collection';

  @override
  String get pleaseEnterValidValues =>
      'Please enter valid numeric values for X, Y, and Z';

  @override
  String get stopDataCollection => 'Stop Data Collection?';

  @override
  String get stopDataCollectionMessage =>
      'Data transmission is currently active. Going back will stop transmission. Do you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get stopAndGoBack => 'Stop & Go Back';

  @override
  String initializationFailed(String error) {
    return 'Initialization failed: $error';
  }

  @override
  String cameraInitializationFailed(String error) {
    return 'Camera initialization failed: $error';
  }

  @override
  String locationInitializationFailed(String error) {
    return 'Location initialization failed: $error';
  }

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get locationPermissionsDenied => 'Location permissions are denied';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'Location permissions are permanently denied';

  @override
  String get locationServicesRequired =>
      'Location services are required to start collection.';

  @override
  String get noVehicleSelected =>
      'Error: No vehicle selected. Please go to Garage and select a vehicle.';

  @override
  String failedToStartCollection(String error) {
    return 'Failed to start collection: $error';
  }

  @override
  String get warningFailedToSaveDriveSession =>
      'Warning: Failed to save drive session times';

  @override
  String get addVehicleTitle => 'Add Vehicle';

  @override
  String get modelLabel => 'Model';

  @override
  String get modelHint => 'e.g., Honda City';

  @override
  String get registrationNumberLabel => 'Registration Number';

  @override
  String get registrationNumberHint => 'e.g., KA01AB1234';

  @override
  String get insuranceNumberLabel => 'Insurance Number';

  @override
  String get insuranceNumberHint => 'e.g., INS123456789';

  @override
  String get pucDateLabel => 'PUC Date';

  @override
  String get selectDateHint => 'Select date';

  @override
  String get addVehicleButton => 'Add Vehicle';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'Enter your full name';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get phoneHint => 'Enter your phone number';

  @override
  String get addressHint => 'Enter your address';

  @override
  String get updateProfileButton => 'Update Profile';

  @override
  String get confirmPasswordTitle => 'Confirm Password';

  @override
  String get passwordHint => 'Enter your password to confirm';

  @override
  String get verifyAndDelete => 'Verify & Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get confirmLogoutMessage =>
      'Are you sure you want to logout of this account?';

  @override
  String get logout => 'Logout';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String get confirmDeletionMessage =>
      'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.';

  @override
  String get delete => 'Delete';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordMessage =>
      'Enter your email address to receive a password reset link.';

  @override
  String get sendLink => 'Send Link';

  @override
  String get passwordResetEmailSent =>
      'Password reset email sent! Check your inbox.';

  @override
  String errorResetPassword(String error) {
    return 'Error: $error';
  }

  @override
  String get loggingOut => 'Logging out...';

  @override
  String failedToLogout(String error) {
    return 'Failed to logout: $error';
  }

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get confirmingLogin => 'Confirming login...';

  @override
  String get cropImage => 'Crop Image';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String failedToUpdateProfile(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get profilePictureUpdatedSuccessfully =>
      'Profile picture updated successfully!';

  @override
  String failedToUpdateProfilePicture(String error) {
    return 'Failed to update profile picture: $error';
  }

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get loading => 'Loading...';

  @override
  String get uploadingProfilePicture => 'Uploading profile picture...';

  @override
  String get viewMore => 'View More';

  @override
  String get showLess => 'Show Less';

  @override
  String get email => 'Email';

  @override
  String get userNotLoggedInError => 'User not logged in';
}
