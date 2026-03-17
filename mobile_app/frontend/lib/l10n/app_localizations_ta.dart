// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'vehnicate';

  @override
  String get vehnicateTagline => 'குழப்பத்தில் அமைதி';

  @override
  String get vehiclesCommunicate => 'வாகனங்கள்+தொடர்பு';

  @override
  String get vehnicate2025 => 'vehnicate@2025';

  @override
  String get vehnicateTab => 'vehnicate';

  @override
  String get navigationTab => 'வழிசெலுத்தல்';

  @override
  String get garageTab => 'உங்கள் கேரேஜ்';

  @override
  String get analyticsTab => 'பகுப்பாய்வு';

  @override
  String get swap => 'மாற்று';

  @override
  String get loginEmailHint => 'மின்னஞ்சல் முகவரி';

  @override
  String get loginPasswordHint => 'கடவுச்சொல்';

  @override
  String get loginButton => 'உள்நுழைய';

  @override
  String get forgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get dontHaveAccount => 'கணக்கு இல்லையா? ';

  @override
  String get signUp => 'பதிவு செய்யுங்கள்';

  @override
  String get orConnectWith => 'அல்லது இதன் மூலம் இணையுங்கள்';

  @override
  String get pleaseEnterEmail => 'உங்கள் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get pleaseEnterPassword => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get passwordMinLength =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get signupTitle => 'உங்கள் கணக்கை உருவாக்குங்கள்';

  @override
  String get signupButton => 'பதிவு செய்யுங்கள்';

  @override
  String get alreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா? ';

  @override
  String get signIn => 'உள்நுழைய';

  @override
  String get verifyEmailTitle => 'மின்னஞ்சலை சரிபார்க்கவும்';

  @override
  String get verifyEmailHeading => 'உங்கள் மின்னஞ்சல் முகவரியை சரிபார்க்கவும்';

  @override
  String verifyEmailMessage(String email) {
    return 'நாங்கள் ஒரு சரிபார்ப்பு மின்னஞ்சல் அனுப்பியுள்ளோம்:\n$email';
  }

  @override
  String get verifyEmailInstruction =>
      'உங்கள் மின்னஞ்சலை சரிபார்த்து சரிபார்ப்பு இணைப்பை கிளிக் செய்யவும்.';

  @override
  String get iHaveVerifiedEmail => 'மின்னஞ்சலை சரிபார்த்தேன்';

  @override
  String get resendVerificationEmail =>
      'சரிபார்ப்பு மின்னஞ்சலை மீண்டும் அனுப்பு';

  @override
  String resendEmailIn(int seconds) {
    return '$seconds வினாடிகளில் மீண்டும் அனுப்பு';
  }

  @override
  String get emailVerified => 'மின்னஞ்சல் சரிபார்க்கப்பட்டது!';

  @override
  String get redirectingToHome => 'முகப்பு பக்கத்திற்கு திருப்பி விடுகிறோம்...';

  @override
  String get cancelAndLogout => 'ரத்து செய்து வெளியேறு';

  @override
  String get checkingVerification => 'சரிபார்ப்பை சோதிக்கிறோம்...';

  @override
  String get emailNotVerified =>
      'மின்னஞ்சல் இன்னும் சரிபார்க்கப்படவில்லை. உங்கள் இன்பாக்ஸை சரிபார்க்கவும்.';

  @override
  String errorSendingVerificationEmail(String error) {
    return 'சரிபார்ப்பு மின்னஞ்சல் அனுப்புவதில் பிழை: $error';
  }

  @override
  String get completeProfileTitle => 'உங்கள் சுயவிவரத்தை முடிக்கவும்';

  @override
  String get tellUsMore => 'உங்களைப் பற்றி மேலும் சொல்லுங்கள்';

  @override
  String get fullNameLabel => 'முழு பெயர்';

  @override
  String get usernameLabel => 'பயனர்பெயர்';

  @override
  String get vehicleDetailsOptional => 'வாகன விவரங்கள் (விருப்பத்தேர்வு)';

  @override
  String get vehicleModelLabel => 'வாகன மாதிரி';

  @override
  String get vehicleYearLabel => 'வாகன ஆண்டு';

  @override
  String get vehicleRegistrationLabel => 'வாகன பதிவு';

  @override
  String get continueButton => 'தொடரவும்';

  @override
  String get skipForNow => 'இப்போது தவிர்க்கவும்';

  @override
  String get pleaseEnterFullName => 'உங்கள் முழு பெயரை உள்ளிடவும்';

  @override
  String get pleaseEnterUsername => 'ஒரு பயனர்பெயரை உள்ளிடவும்';

  @override
  String get usernameMinLength =>
      'பயனர்பெயர் குறைந்தது 3 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get startDrive => 'ஓட்டுதலை தொடங்கு';

  @override
  String get rpsScore => 'RPS மதிப்பெண்';

  @override
  String get driveSmoothly => 'சீராக ஓட்டுங்கள்';

  @override
  String get weekly => 'வாராந்திர';

  @override
  String get maintainConstantAcceleration =>
      '50 கி.மீ. நிலையான முடுக்கத்தை பராமரிக்கவும்';

  @override
  String reward(int points) {
    return 'வெகுமதி: $points புள்ளிகள்';
  }

  @override
  String get addVehicle => 'வாகனம் சேர்க்கவும்';

  @override
  String get addAnotherVehicle => 'மற்றொரு வாகனம் சேர்க்கவும்';

  @override
  String get tapToAddVehicle => 'உங்கள் வாகனத்தை சேர்க்க தட்டவும்';

  @override
  String get selectVehicle => 'வாகனம் தேர்ந்தெடுக்கவும்';

  @override
  String get noVehiclesAvailable => 'வாகனங்கள் எதுவும் இல்லை';

  @override
  String get vehicleAddedSuccessfully => 'வாகனம் வெற்றிகரமாக சேர்க்கப்பட்டது!';

  @override
  String failedToAddVehicle(String error) {
    return 'வாகனம் சேர்க்கத் தவறியது: $error';
  }

  @override
  String get noVehicle => 'வாகனம் இல்லை';

  @override
  String get vehicleRegistrationPlaceholder => '------';

  @override
  String get viewDetails => 'விவரங்களை காண்க';

  @override
  String get hillViewMumbai => 'ஹில் வியூ, மும்பை';

  @override
  String get distanceCovered => 'கடந்த தூரம்';

  @override
  String get rpsScoreLabel => 'RPS மதிப்பெண்';

  @override
  String get documentCenter => 'ஆவண மையம்';

  @override
  String get insurancePolicy => 'காப்பீட்டு பாலிசி';

  @override
  String get active => 'செயலில்';

  @override
  String expires(String date) {
    return 'காலாவதி: $date';
  }

  @override
  String get rcDetails => 'RC விவரங்கள்';

  @override
  String get verified => 'சரிபார்க்கப்பட்டது';

  @override
  String get pucCertificate => 'PUC சான்றிதழ்';

  @override
  String get expiringSoon => 'விரைவில் காலாவதியாகும்';

  @override
  String get notUploaded => 'பதிவேற்றவில்லை';

  @override
  String expiresOn(String date) {
    return 'காலாவதி: $date';
  }

  @override
  String get logisticsHistory => 'தளவாட & வரலாறு';

  @override
  String parkedNear(String location) {
    return '$location அருகில் நிறுத்தப்பட்டுள்ளது';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours மணி நேரத்திற்கு முன்பு';
  }

  @override
  String get serviceHistory => 'சேவை வரலாறு';

  @override
  String lastService(String service) {
    return 'கடைசி: $service (ஜன 24)';
  }

  @override
  String get totalExpenses => 'மொத்த செலவுகள்';

  @override
  String expensesAmount(String amount) {
    return 'ரூ $amount';
  }

  @override
  String get roadsideAssist => 'சாலையோர உதவி';

  @override
  String get premiumPlan => 'பிரீமியம் திட்டம்';

  @override
  String get tapToCall => 'அழைக்க தட்டவும்';

  @override
  String get deleteVehicle => 'வாகனத்தை நீக்கு';

  @override
  String get deleteVehicleConfirmation =>
      'இந்த வாகனத்தை நீக்க வேண்டுமா? இந்த செயலை மீண்டும் செய்ய முடியாது.';

  @override
  String get deleting => 'நீக்குகிறோம்...';

  @override
  String errorDeletingVehicle(String error) {
    return 'வாகனம் நீக்குவதில் பிழை: $error';
  }

  @override
  String get unknownCar => 'தெரியாத கார்';

  @override
  String get kmUnit => 'கி.மீ';

  @override
  String get hoursUnit => 'ம';

  @override
  String get minutesUnit => 'நி';

  @override
  String get logOut => 'வெளியேறு';

  @override
  String get personalInformation => 'தனிப்பட்ட தகவல்';

  @override
  String get edit => 'திருத்து';

  @override
  String get emailLabel => 'மின்னஞ்சல்';

  @override
  String get mailNotGiven => 'மின்னஞ்சல் வழங்கப்படவில்லை';

  @override
  String get phoneLabel => 'தொலைபேசி';

  @override
  String get phoneNotGiven => 'தொலைபேசி வழங்கப்படவில்லை';

  @override
  String get addressLabel => 'முகவரி';

  @override
  String get addressNotUpdated => 'முகவரி புதுப்பிக்கப்படவில்லை';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get notification => 'அறிவிப்பு';

  @override
  String get darkMode => 'இருண்ட பயன்முறை';

  @override
  String get deleteAccount => 'கணக்கை நீக்கு';

  @override
  String get covered => 'கடந்தது';

  @override
  String get streak => 'தொடர்ச்சி';

  @override
  String get overallPerformance => 'ஒட்டுமொத்த செயல்திறன்';

  @override
  String get days => 'நாட்கள்';

  @override
  String get imuCameraTitle => 'IMU + கேமரா தரவு சேகரிப்பு';

  @override
  String get dataCollectionStatistics => 'தரவு சேகரிப்பு புள்ளிவிவரங்கள்';

  @override
  String get imuData => 'IMU தரவு';

  @override
  String get images => 'படங்கள்';

  @override
  String pendingImages(int count) {
    return 'நிலுவையில் உள்ள படங்கள்: $count';
  }

  @override
  String uploaded(int count) {
    return 'பதிவேற்றப்பட்டது: $count';
  }

  @override
  String get startCollection => 'சேகரிப்பை தொடங்கு';

  @override
  String get stopCollection => 'சேகரிப்பை நிறுத்து';

  @override
  String get stopping => 'நிறுத்துகிறோம்...';

  @override
  String get uploadNow => 'இப்போது பதிவேற்று';

  @override
  String get uploadTriggered => 'பதிவேற்றம் தொடங்கப்பட்டது';

  @override
  String get dataCollectionActive => 'தரவு சேகரிப்பு செயலில் உள்ளது';

  @override
  String get dataCollectionStopped => 'தரவு சேகரிப்பு நிறுத்தப்பட்டது';

  @override
  String get cameraNotReady => 'கேமரா தயாராக இல்லை';

  @override
  String get enterStartPosition => 'தொடக்க நிலையை உள்ளிடவும்';

  @override
  String get startX => 'தொடக்க X';

  @override
  String get startY => 'தொடக்க Y';

  @override
  String get startZ => 'தொடக்க Z';

  @override
  String get startCollectionButton => 'சேகரிப்பை தொடங்கு';

  @override
  String get pleaseEnterValidValues =>
      'X, Y மற்றும் Z க்கு சரியான எண் மதிப்புகளை உள்ளிடவும்';

  @override
  String get stopDataCollection => 'தரவு சேகரிப்பை நிறுத்தவா?';

  @override
  String get stopDataCollectionMessage =>
      'தரவு பரிமாற்றம் தற்போது செயலில் உள்ளது. திரும்பினால் பரிமாற்றம் நிறுத்தப்படும். தொடர விரும்புகிறீர்களா?';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get stopAndGoBack => 'நிறுத்தி திரும்பு';

  @override
  String initializationFailed(String error) {
    return 'தொடக்கம் தவறியது: $error';
  }

  @override
  String cameraInitializationFailed(String error) {
    return 'கேமரா தொடக்கம் தவறியது: $error';
  }

  @override
  String locationInitializationFailed(String error) {
    return 'இருப்பிட தொடக்கம் தவறியது: $error';
  }

  @override
  String get locationServicesDisabled => 'இருப்பிட சேவைகள் முடக்கப்பட்டுள்ளன';

  @override
  String get locationPermissionsDenied => 'இருப்பிட அனுமதிகள் மறுக்கப்பட்டன';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'இருப்பிட அனுமதிகள் நிரந்தரமாக மறுக்கப்பட்டன';

  @override
  String get locationServicesRequired =>
      'சேகரிப்பை தொடங்க இருப்பிட சேவைகள் தேவை.';

  @override
  String get noVehicleSelected =>
      'பிழை: வாகனம் தேர்ந்தெடுக்கப்படவில்லை. கேரேஜுக்கு சென்று வாகனத்தை தேர்ந்தெடுக்கவும்.';

  @override
  String failedToStartCollection(String error) {
    return 'சேகரிப்பை தொடங்கத் தவறியது: $error';
  }

  @override
  String get warningFailedToSaveDriveSession =>
      'எச்சரிக்கை: ஓட்டுதல் அமர்வு நேரங்களை சேமிக்கத் தவறியது';

  @override
  String get addVehicleTitle => 'வாகனம் சேர்க்கவும்';

  @override
  String get modelLabel => 'மாதிரி';

  @override
  String get modelHint => 'எ.கா., Honda City';

  @override
  String get registrationNumberLabel => 'பதிவு எண்';

  @override
  String get registrationNumberHint => 'எ.கா., KA01AB1234';

  @override
  String get insuranceNumberLabel => 'காப்பீட்டு எண்';

  @override
  String get insuranceNumberHint => 'எ.கா., INS123456789';

  @override
  String get pucDateLabel => 'PUC தேதி';

  @override
  String get selectDateHint => 'தேதியை தேர்ந்தெடுக்கவும்';

  @override
  String get addVehicleButton => 'வாகனம் சேர்க்கவும்';

  @override
  String get editProfileTitle => 'சுயவிவரத்தை திருத்து';

  @override
  String get nameLabel => 'பெயர்';

  @override
  String get nameHint => 'உங்கள் முழு பெயரை உள்ளிடவும்';

  @override
  String get usernameHint => 'உங்கள் பயனர்பெயரை உள்ளிடவும்';

  @override
  String get phoneHint => 'உங்கள் தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get addressHint => 'உங்கள் முகவரியை உள்ளிடவும்';

  @override
  String get updateProfileButton => 'சுயவிவரத்தை புதுப்பி';

  @override
  String get confirmPasswordTitle => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get passwordHint => 'உறுதிப்படுத்த கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get verifyAndDelete => 'சரிபார்த்து நீக்கு';

  @override
  String get confirm => 'உறுதிப்படுத்து';

  @override
  String get confirmLogout => 'வெளியேற்றத்தை உறுதிப்படுத்தவும்';

  @override
  String get confirmLogoutMessage =>
      'இந்த கணக்கிலிருந்து வெளியேற விரும்புகிறீர்களா?';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get confirmDeletion => 'நீக்கத்தை உறுதிப்படுத்தவும்';

  @override
  String get confirmDeletionMessage =>
      'உங்கள் கணக்கை நீக்க விரும்புகிறீர்களா? இந்த செயலை மீண்டும் செய்ய முடியாது மற்றும் உங்கள் எல்லா தரவும் இழக்கப்படும்.';

  @override
  String get delete => 'நீக்கு';

  @override
  String get resetPassword => 'கடவுச்சொல்லை மீட்டமை';

  @override
  String get resetPasswordMessage =>
      'கடவுச்சொல் மீட்டமைப்பு இணைப்பை பெற உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்.';

  @override
  String get sendLink => 'இணைப்பை அனுப்பு';

  @override
  String get passwordResetEmailSent =>
      'கடவுச்சொல் மீட்டமைப்பு மின்னஞ்சல் அனுப்பப்பட்டது! உங்கள் இன்பாக்ஸை சரிபார்க்கவும்.';

  @override
  String errorResetPassword(String error) {
    return 'பிழை: $error';
  }

  @override
  String get loggingOut => 'வெளியேறுகிறோம்...';

  @override
  String failedToLogout(String error) {
    return 'வெளியேறுவதில் தவறியது: $error';
  }

  @override
  String get accountDeletedSuccessfully => 'கணக்கு வெற்றிகரமாக நீக்கப்பட்டது';

  @override
  String get confirmingLogin => 'உள்நுழைவை உறுதிப்படுத்துகிறோம்...';

  @override
  String get cropImage => 'படத்தை வெட்டவும்';

  @override
  String get profileUpdatedSuccessfully =>
      'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!';

  @override
  String failedToUpdateProfile(String error) {
    return 'சுயவிவரத்தை புதுப்பிக்கத் தவறியது: $error';
  }

  @override
  String get profilePictureUpdatedSuccessfully =>
      'சுயவிவர படம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!';

  @override
  String failedToUpdateProfilePicture(String error) {
    return 'சுயவிவர படத்தை புதுப்பிக்கத் தவறியது: $error';
  }

  @override
  String get userNotLoggedIn => 'பயனர் உள்நுழையவில்லை';

  @override
  String get loading => 'ஏற்றுகிறோம்...';

  @override
  String get uploadingProfilePicture => 'சுயவிவர படத்தை பதிவேற்றுகிறோம்...';

  @override
  String get viewMore => 'மேலும் காண்க';

  @override
  String get showLess => 'குறைவாக காட்டு';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get userNotLoggedInError => 'பயனர் உள்நுழையவில்லை';
}
