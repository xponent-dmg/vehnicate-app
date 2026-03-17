import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// App name displayed in splash and title bars
  ///
  /// In en, this message translates to:
  /// **'vehnicate'**
  String get appTitle;

  /// Tagline displayed on login screen
  ///
  /// In en, this message translates to:
  /// **'calm in the chaos'**
  String get vehnicateTagline;

  /// Animated text shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'vehicles+communicate'**
  String get vehiclesCommunicate;

  /// Copyright text shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'vehnicate@2025'**
  String get vehnicate2025;

  /// Navigation tab title for main dashboard
  ///
  /// In en, this message translates to:
  /// **'vehnicate'**
  String get vehnicateTab;

  /// Navigation tab title for map screen
  ///
  /// In en, this message translates to:
  /// **'navigation'**
  String get navigationTab;

  /// Navigation tab title for garage screen
  ///
  /// In en, this message translates to:
  /// **'your garage'**
  String get garageTab;

  /// Navigation tab title for analytics screen
  ///
  /// In en, this message translates to:
  /// **'analytics'**
  String get analyticsTab;

  /// Button text to swap selected vehicle
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// Placeholder text for email input field on login screen
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailHint;

  /// Placeholder text for password input field on login screen
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// Button text to sign in to the app
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// Link text to reset password on login screen
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Text prompting user to sign up on login screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Link text to navigate to sign up screen
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Text separator for social login options
  ///
  /// In en, this message translates to:
  /// **'or connect with'**
  String get orConnectWith;

  /// Validation error message for empty email field
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Validation error message for empty password field
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Validation error message for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Title text for sign up screen
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// Button text to create new account
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signupButton;

  /// Text prompting user to sign in on sign up screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Link text to navigate to sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Title of email verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// Heading text on email verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify your email address'**
  String get verifyEmailHeading;

  /// Message explaining email verification process
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification email to:\n{email}'**
  String verifyEmailMessage(String email);

  /// Instruction text for email verification
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click on the verification link.'**
  String get verifyEmailInstruction;

  /// Button text after user verifies email
  ///
  /// In en, this message translates to:
  /// **'I have verified my email'**
  String get iHaveVerifiedEmail;

  /// Button text to resend verification email
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// Countdown text for resend email button
  ///
  /// In en, this message translates to:
  /// **'Resend Email in {seconds} s'**
  String resendEmailIn(int seconds);

  /// Success message when email is verified
  ///
  /// In en, this message translates to:
  /// **'Email Verified!'**
  String get emailVerified;

  /// Status message during redirect after verification
  ///
  /// In en, this message translates to:
  /// **'Redirecting to home...'**
  String get redirectingToHome;

  /// Button to cancel verification and logout
  ///
  /// In en, this message translates to:
  /// **'Cancel & Log Out'**
  String get cancelAndLogout;

  /// Loading message while checking email verification
  ///
  /// In en, this message translates to:
  /// **'Checking verification...'**
  String get checkingVerification;

  /// Message when email verification is not complete
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Please check your inbox.'**
  String get emailNotVerified;

  /// Error message when verification email fails to send
  ///
  /// In en, this message translates to:
  /// **'Error sending verification email: {error}'**
  String errorSendingVerificationEmail(String error);

  /// Title of user details completion screen
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfileTitle;

  /// Subtitle text on user details screen
  ///
  /// In en, this message translates to:
  /// **'Tell us more about yourself'**
  String get tellUsMore;

  /// Label for full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// Label for username input field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Section header for optional vehicle details
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details (Optional)'**
  String get vehicleDetailsOptional;

  /// Label for vehicle model input field
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get vehicleModelLabel;

  /// Label for vehicle year input field
  ///
  /// In en, this message translates to:
  /// **'Vehicle Year'**
  String get vehicleYearLabel;

  /// Label for vehicle registration input field
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration'**
  String get vehicleRegistrationLabel;

  /// Button to proceed after completing profile
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Button to skip profile completion
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Validation error for empty full name field
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// Validation error for empty username field
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseEnterUsername;

  /// Validation error for short username
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinLength;

  /// Button to start driving data collection
  ///
  /// In en, this message translates to:
  /// **'Start Drive'**
  String get startDrive;

  /// Label for RPS (Road Performance Score) metric
  ///
  /// In en, this message translates to:
  /// **'RPS Score'**
  String get rpsScore;

  /// Title of weekly challenge card
  ///
  /// In en, this message translates to:
  /// **'Drive smoothly'**
  String get driveSmoothly;

  /// Badge indicating weekly challenge
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Description of weekly driving challenge
  ///
  /// In en, this message translates to:
  /// **'Maintain constant acceleration for 50 km'**
  String get maintainConstantAcceleration;

  /// Reward text for completing challenges
  ///
  /// In en, this message translates to:
  /// **'Reward: {points} points'**
  String reward(int points);

  /// Button to add a new vehicle
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get addVehicle;

  /// Button to add additional vehicle
  ///
  /// In en, this message translates to:
  /// **'Add another vehicle'**
  String get addAnotherVehicle;

  /// Instruction text when no vehicles exist
  ///
  /// In en, this message translates to:
  /// **'Tap to add your vehicle'**
  String get tapToAddVehicle;

  /// Title of vehicle selection bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get selectVehicle;

  /// Message when no vehicles exist
  ///
  /// In en, this message translates to:
  /// **'No vehicles available'**
  String get noVehiclesAvailable;

  /// Success message after adding vehicle
  ///
  /// In en, this message translates to:
  /// **'Vehicle added successfully!'**
  String get vehicleAddedSuccessfully;

  /// Error message when vehicle addition fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add vehicle: {error}'**
  String failedToAddVehicle(String error);

  /// Placeholder text when no vehicle is selected
  ///
  /// In en, this message translates to:
  /// **'No vehicle'**
  String get noVehicle;

  /// Placeholder for missing vehicle registration
  ///
  /// In en, this message translates to:
  /// **'------'**
  String get vehicleRegistrationPlaceholder;

  /// Link text to view vehicle details
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// Example vehicle location text
  ///
  /// In en, this message translates to:
  /// **'Hill view, Mumbai'**
  String get hillViewMumbai;

  /// Label for vehicle distance metric
  ///
  /// In en, this message translates to:
  /// **'Distance Covered'**
  String get distanceCovered;

  /// Label for RPS score in vehicle details
  ///
  /// In en, this message translates to:
  /// **'RPS Score'**
  String get rpsScoreLabel;

  /// Section header for vehicle documents
  ///
  /// In en, this message translates to:
  /// **'Document Center'**
  String get documentCenter;

  /// Document type label
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy'**
  String get insurancePolicy;

  /// Status indicator for active insurance
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Expiry date format
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expires(String date);

  /// Vehicle registration certificate document type
  ///
  /// In en, this message translates to:
  /// **'RC Details'**
  String get rcDetails;

  /// Status indicator for verified document
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Pollution under control certificate document type
  ///
  /// In en, this message translates to:
  /// **'PUC Certificate'**
  String get pucCertificate;

  /// Status indicator for document expiring soon
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// Status indicator for missing document
  ///
  /// In en, this message translates to:
  /// **'Not Uploaded'**
  String get notUploaded;

  /// Expiry date format for documents
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresOn(String date);

  /// Section header for vehicle logistics and history
  ///
  /// In en, this message translates to:
  /// **'Logistics & History'**
  String get logisticsHistory;

  /// Vehicle location text
  ///
  /// In en, this message translates to:
  /// **'Parked near {location}'**
  String parkedNear(String location);

  /// Relative time format
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(int hours);

  /// Label for vehicle service history
  ///
  /// In en, this message translates to:
  /// **'Service History'**
  String get serviceHistory;

  /// Last service information
  ///
  /// In en, this message translates to:
  /// **'Last: {service} (Jan 24)'**
  String lastService(String service);

  /// Label for total vehicle expenses
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// Currency format for expenses
  ///
  /// In en, this message translates to:
  /// **'Rs {amount}'**
  String expensesAmount(String amount);

  /// Roadside assistance service label
  ///
  /// In en, this message translates to:
  /// **'Roadside Assist'**
  String get roadsideAssist;

  /// Insurance plan type label
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get premiumPlan;

  /// Button text to call roadside assistance
  ///
  /// In en, this message translates to:
  /// **'Tap to Call'**
  String get tapToCall;

  /// Button to delete vehicle
  ///
  /// In en, this message translates to:
  /// **'Delete Vehicle'**
  String get deleteVehicle;

  /// Confirmation message for vehicle deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this vehicle? This action cannot be undone.'**
  String get deleteVehicleConfirmation;

  /// Loading message while deleting vehicle
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// Error message when vehicle deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting vehicle: {error}'**
  String errorDeletingVehicle(String error);

  /// Fallback text when vehicle model is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown Car'**
  String get unknownCar;

  /// Unit abbreviation for kilometers
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// Unit abbreviation for hours
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursUnit;

  /// Unit abbreviation for minutes
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesUnit;

  /// Button to logout from account
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Section header for user personal details
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Button to edit user information
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label for user email address
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Placeholder when email is not provided
  ///
  /// In en, this message translates to:
  /// **'mail not given'**
  String get mailNotGiven;

  /// Label for user phone number
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Placeholder when phone is not provided
  ///
  /// In en, this message translates to:
  /// **'phone not given'**
  String get phoneNotGiven;

  /// Label for user address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Placeholder when address is not provided
  ///
  /// In en, this message translates to:
  /// **'Address not updated'**
  String get addressNotUpdated;

  /// Section header for app settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Setting option for notifications
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// Setting option for dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Button to delete user account
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Label for distance covered metric
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get covered;

  /// Label for user streak metric
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// Label for overall performance score
  ///
  /// In en, this message translates to:
  /// **'Overall Performance'**
  String get overallPerformance;

  /// Unit for days
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// Title of IMU and camera data collection screen
  ///
  /// In en, this message translates to:
  /// **'IMU + Camera Data Collector'**
  String get imuCameraTitle;

  /// Section header for collection statistics
  ///
  /// In en, this message translates to:
  /// **'Data Collection Statistics'**
  String get dataCollectionStatistics;

  /// Label for IMU sensor data statistics
  ///
  /// In en, this message translates to:
  /// **'IMU Data'**
  String get imuData;

  /// Label for camera images statistics
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// Count of pending images to upload
  ///
  /// In en, this message translates to:
  /// **'Pending Images: {count}'**
  String pendingImages(int count);

  /// Count of uploaded items
  ///
  /// In en, this message translates to:
  /// **'Uploaded: {count}'**
  String uploaded(int count);

  /// Button to start data collection
  ///
  /// In en, this message translates to:
  /// **'Start Collection'**
  String get startCollection;

  /// Button to stop data collection
  ///
  /// In en, this message translates to:
  /// **'Stop Collection'**
  String get stopCollection;

  /// Status message while stopping collection
  ///
  /// In en, this message translates to:
  /// **'Stopping...'**
  String get stopping;

  /// Button to trigger immediate upload
  ///
  /// In en, this message translates to:
  /// **'Upload Now'**
  String get uploadNow;

  /// Success message when upload is triggered
  ///
  /// In en, this message translates to:
  /// **'Upload triggered'**
  String get uploadTriggered;

  /// Status message when collection is active
  ///
  /// In en, this message translates to:
  /// **'Data Collection Active'**
  String get dataCollectionActive;

  /// Status message when collection is stopped
  ///
  /// In en, this message translates to:
  /// **'Data Collection Stopped'**
  String get dataCollectionStopped;

  /// Message when camera is not initialized
  ///
  /// In en, this message translates to:
  /// **'Camera not ready'**
  String get cameraNotReady;

  /// Title for start position input dialog
  ///
  /// In en, this message translates to:
  /// **'Enter Start Position'**
  String get enterStartPosition;

  /// Label for X coordinate input
  ///
  /// In en, this message translates to:
  /// **'Start X'**
  String get startX;

  /// Label for Y coordinate input
  ///
  /// In en, this message translates to:
  /// **'Start Y'**
  String get startY;

  /// Label for Z coordinate input
  ///
  /// In en, this message translates to:
  /// **'Start Z'**
  String get startZ;

  /// Button to start collection in position dialog
  ///
  /// In en, this message translates to:
  /// **'Start Collection'**
  String get startCollectionButton;

  /// Validation error for coordinate inputs
  ///
  /// In en, this message translates to:
  /// **'Please enter valid numeric values for X, Y, and Z'**
  String get pleaseEnterValidValues;

  /// Confirmation dialog title when stopping collection
  ///
  /// In en, this message translates to:
  /// **'Stop Data Collection?'**
  String get stopDataCollection;

  /// Confirmation message for stopping data collection
  ///
  /// In en, this message translates to:
  /// **'Data transmission is currently active. Going back will stop transmission. Do you want to continue?'**
  String get stopDataCollectionMessage;

  /// Button to cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button to stop collection and navigate back
  ///
  /// In en, this message translates to:
  /// **'Stop & Go Back'**
  String get stopAndGoBack;

  /// Error message when initialization fails
  ///
  /// In en, this message translates to:
  /// **'Initialization failed: {error}'**
  String initializationFailed(String error);

  /// Error message when camera initialization fails
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed: {error}'**
  String cameraInitializationFailed(String error);

  /// Error message when location initialization fails
  ///
  /// In en, this message translates to:
  /// **'Location initialization failed: {error}'**
  String locationInitializationFailed(String error);

  /// Error message when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// Error message when location permissions are denied
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPermissionsDenied;

  /// Error message when location permissions are permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionsPermanentlyDenied;

  /// Message explaining location requirement
  ///
  /// In en, this message translates to:
  /// **'Location services are required to start collection.'**
  String get locationServicesRequired;

  /// Error message when no vehicle is selected for collection
  ///
  /// In en, this message translates to:
  /// **'Error: No vehicle selected. Please go to Garage and select a vehicle.'**
  String get noVehicleSelected;

  /// Error message when collection start fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start collection: {error}'**
  String failedToStartCollection(String error);

  /// Warning message when drive session save fails
  ///
  /// In en, this message translates to:
  /// **'Warning: Failed to save drive session times'**
  String get warningFailedToSaveDriveSession;

  /// Title of add vehicle dialog
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get addVehicleTitle;

  /// Label for vehicle model input
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// Hint text for vehicle model input
  ///
  /// In en, this message translates to:
  /// **'e.g., Honda City'**
  String get modelHint;

  /// Label for vehicle registration number input
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get registrationNumberLabel;

  /// Hint text for registration number input
  ///
  /// In en, this message translates to:
  /// **'e.g., KA01AB1234'**
  String get registrationNumberHint;

  /// Label for insurance number input
  ///
  /// In en, this message translates to:
  /// **'Insurance Number'**
  String get insuranceNumberLabel;

  /// Hint text for insurance number input
  ///
  /// In en, this message translates to:
  /// **'e.g., INS123456789'**
  String get insuranceNumberHint;

  /// Label for PUC certificate date input
  ///
  /// In en, this message translates to:
  /// **'PUC Date'**
  String get pucDateLabel;

  /// Hint text for date selection
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDateHint;

  /// Button to add vehicle in dialog
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get addVehicleButton;

  /// Title of edit profile dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// Label for name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Hint text for name input
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get nameHint;

  /// Hint text for username input
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// Hint text for phone input
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneHint;

  /// Hint text for address input
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get addressHint;

  /// Button to save profile changes
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfileButton;

  /// Title of password confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordTitle;

  /// Hint text for password confirmation
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get passwordHint;

  /// Button to verify password and delete account
  ///
  /// In en, this message translates to:
  /// **'Verify & Delete'**
  String get verifyAndDelete;

  /// Default confirmation button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Title of logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// Message in logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout of this account?'**
  String get confirmLogoutMessage;

  /// Logout action button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Title of account deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// Message in account deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.'**
  String get confirmDeletionMessage;

  /// Delete action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title of password reset dialog
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Message in password reset dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to receive a password reset link.'**
  String get resetPasswordMessage;

  /// Button to send password reset link
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendLink;

  /// Success message after password reset email
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get passwordResetEmailSent;

  /// Error message for password reset failure
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorResetPassword(String error);

  /// Loading message during logout
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// Error message when logout fails
  ///
  /// In en, this message translates to:
  /// **'Failed to logout: {error}'**
  String failedToLogout(String error);

  /// Success message after account deletion
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// Loading message during re-authentication
  ///
  /// In en, this message translates to:
  /// **'Confirming login...'**
  String get confirmingLogin;

  /// Title of image cropping screen
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// Success message after profile update
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// Error message when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(String error);

  /// Success message after profile picture update
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdatedSuccessfully;

  /// Error message when profile picture update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile picture: {error}'**
  String failedToUpdateProfilePicture(String error);

  /// Error message when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// Generic loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Loading message during profile picture upload
  ///
  /// In en, this message translates to:
  /// **'Uploading profile picture...'**
  String get uploadingProfilePicture;

  /// Button to expand long snackbar message
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// Button to collapse expanded snackbar message
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// Email label in forgot password dialog
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Error message for unauthenticated user action
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedInError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
