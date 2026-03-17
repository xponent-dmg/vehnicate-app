// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'vehnicate';

  @override
  String get vehnicateTagline => 'अराजकता में शांति';

  @override
  String get vehiclesCommunicate => 'वाहन+संवाद';

  @override
  String get vehnicate2025 => 'vehnicate@2025';

  @override
  String get vehnicateTab => 'vehnicate';

  @override
  String get navigationTab => 'नेविगेशन';

  @override
  String get garageTab => 'आपका गैराज';

  @override
  String get analyticsTab => 'विश्लेषण';

  @override
  String get swap => 'बदलें';

  @override
  String get loginEmailHint => 'ईमेल पता';

  @override
  String get loginPasswordHint => 'पासवर्ड';

  @override
  String get loginButton => 'साइन इन करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get dontHaveAccount => 'खाता नहीं है? ';

  @override
  String get signUp => 'साइन अप करें';

  @override
  String get orConnectWith => 'या इससे जुड़ें';

  @override
  String get pleaseEnterEmail => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get pleaseEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get signupTitle => 'अपना खाता बनाएं';

  @override
  String get signupButton => 'साइन अप करें';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? ';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get verifyEmailTitle => 'ईमेल सत्यापित करें';

  @override
  String get verifyEmailHeading => 'अपना ईमेल पता सत्यापित करें';

  @override
  String verifyEmailMessage(String email) {
    return 'हमने एक सत्यापन ईमेल भेजा है:\n$email';
  }

  @override
  String get verifyEmailInstruction =>
      'कृपया अपना ईमेल जांचें और सत्यापन लिंक पर क्लिक करें।';

  @override
  String get iHaveVerifiedEmail => 'मैंने अपना ईमेल सत्यापित कर लिया है';

  @override
  String get resendVerificationEmail => 'सत्यापन ईमेल पुनः भेजें';

  @override
  String resendEmailIn(int seconds) {
    return '$seconds सेकंड में पुनः भेजें';
  }

  @override
  String get emailVerified => 'ईमेल सत्यापित हो गया!';

  @override
  String get redirectingToHome => 'होम पर पुनः निर्देशित किया जा रहा है...';

  @override
  String get cancelAndLogout => 'रद्द करें और लॉग आउट करें';

  @override
  String get checkingVerification => 'सत्यापन जांचा जा रहा है...';

  @override
  String get emailNotVerified =>
      'ईमेल अभी तक सत्यापित नहीं हुआ। कृपया अपना इनबॉक्स जांचें।';

  @override
  String errorSendingVerificationEmail(String error) {
    return 'सत्यापन ईमेल भेजने में त्रुटि: $error';
  }

  @override
  String get completeProfileTitle => 'अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get tellUsMore => 'हमें अपने बारे में और बताएं';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get usernameLabel => 'उपयोगकर्ता नाम';

  @override
  String get vehicleDetailsOptional => 'वाहन विवरण (वैकल्पिक)';

  @override
  String get vehicleModelLabel => 'वाहन मॉडल';

  @override
  String get vehicleYearLabel => 'वाहन वर्ष';

  @override
  String get vehicleRegistrationLabel => 'वाहन पंजीकरण';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get skipForNow => 'अभी के लिए छोड़ें';

  @override
  String get pleaseEnterFullName => 'कृपया अपना पूरा नाम दर्ज करें';

  @override
  String get pleaseEnterUsername => 'कृपया एक उपयोगकर्ता नाम दर्ज करें';

  @override
  String get usernameMinLength =>
      'उपयोगकर्ता नाम कम से कम 3 अक्षरों का होना चाहिए';

  @override
  String get startDrive => 'ड्राइव शुरू करें';

  @override
  String get rpsScore => 'RPS स्कोर';

  @override
  String get driveSmoothly => 'सुचारू रूप से चलाएं';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get maintainConstantAcceleration =>
      '50 किमी के लिए निरंतर त्वरण बनाए रखें';

  @override
  String reward(int points) {
    return 'पुरस्कार: $points अंक';
  }

  @override
  String get addVehicle => 'वाहन जोड़ें';

  @override
  String get addAnotherVehicle => 'एक और वाहन जोड़ें';

  @override
  String get tapToAddVehicle => 'अपना वाहन जोड़ने के लिए टैप करें';

  @override
  String get selectVehicle => 'वाहन चुनें';

  @override
  String get noVehiclesAvailable => 'कोई वाहन उपलब्ध नहीं है';

  @override
  String get vehicleAddedSuccessfully => 'वाहन सफलतापूर्वक जोड़ा गया!';

  @override
  String failedToAddVehicle(String error) {
    return 'वाहन जोड़ने में विफल: $error';
  }

  @override
  String get noVehicle => 'कोई वाहन नहीं';

  @override
  String get vehicleRegistrationPlaceholder => '------';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get hillViewMumbai => 'हिल व्यू, मुंबई';

  @override
  String get distanceCovered => 'तय की गई दूरी';

  @override
  String get rpsScoreLabel => 'RPS स्कोर';

  @override
  String get documentCenter => 'दस्तावेज़ केंद्र';

  @override
  String get insurancePolicy => 'बीमा पॉलिसी';

  @override
  String get active => 'सक्रिय';

  @override
  String expires(String date) {
    return 'समाप्त: $date';
  }

  @override
  String get rcDetails => 'RC विवरण';

  @override
  String get verified => 'सत्यापित';

  @override
  String get pucCertificate => 'PUC प्रमाणपत्र';

  @override
  String get expiringSoon => 'जल्द समाप्त होगा';

  @override
  String get notUploaded => 'अपलोड नहीं किया गया';

  @override
  String expiresOn(String date) {
    return 'समाप्त: $date';
  }

  @override
  String get logisticsHistory => 'लॉजिस्टिक्स और इतिहास';

  @override
  String parkedNear(String location) {
    return '$location के पास पार्क किया गया';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String get serviceHistory => 'सर्विस इतिहास';

  @override
  String lastService(String service) {
    return 'अंतिम: $service (जन 24)';
  }

  @override
  String get totalExpenses => 'कुल खर्च';

  @override
  String expensesAmount(String amount) {
    return '₹$amount';
  }

  @override
  String get roadsideAssist => 'रोडसाइड सहायता';

  @override
  String get premiumPlan => 'प्रीमियम प्लान';

  @override
  String get tapToCall => 'कॉल करने के लिए टैप करें';

  @override
  String get deleteVehicle => 'वाहन हटाएं';

  @override
  String get deleteVehicleConfirmation =>
      'क्या आप इस वाहन को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get deleting => 'हटाया जा रहा है...';

  @override
  String errorDeletingVehicle(String error) {
    return 'वाहन हटाने में त्रुटि: $error';
  }

  @override
  String get unknownCar => 'अज्ञात कार';

  @override
  String get kmUnit => 'किमी';

  @override
  String get hoursUnit => 'घ';

  @override
  String get minutesUnit => 'मि';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get edit => 'संपादित करें';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get mailNotGiven => 'ईमेल नहीं दिया गया';

  @override
  String get phoneLabel => 'फ़ोन';

  @override
  String get phoneNotGiven => 'फ़ोन नहीं दिया गया';

  @override
  String get addressLabel => 'पता';

  @override
  String get addressNotUpdated => 'पता अपडेट नहीं किया गया';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get notification => 'सूचना';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get covered => 'तय किया';

  @override
  String get streak => 'स्ट्रीक';

  @override
  String get overallPerformance => 'समग्र प्रदर्शन';

  @override
  String get days => 'दिन';

  @override
  String get imuCameraTitle => 'IMU + कैमरा डेटा संग्रहकर्ता';

  @override
  String get dataCollectionStatistics => 'डेटा संग्रह सांख्यिकी';

  @override
  String get imuData => 'IMU डेटा';

  @override
  String get images => 'छवियां';

  @override
  String pendingImages(int count) {
    return 'लंबित छवियां: $count';
  }

  @override
  String uploaded(int count) {
    return 'अपलोड किया गया: $count';
  }

  @override
  String get startCollection => 'संग्रह शुरू करें';

  @override
  String get stopCollection => 'संग्रह रोकें';

  @override
  String get stopping => 'रोका जा रहा है...';

  @override
  String get uploadNow => 'अभी अपलोड करें';

  @override
  String get uploadTriggered => 'अपलोड शुरू किया गया';

  @override
  String get dataCollectionActive => 'डेटा संग्रह सक्रिय है';

  @override
  String get dataCollectionStopped => 'डेटा संग्रह रोका गया';

  @override
  String get cameraNotReady => 'कैमरा तैयार नहीं है';

  @override
  String get enterStartPosition => 'प्रारंभ स्थिति दर्ज करें';

  @override
  String get startX => 'प्रारंभ X';

  @override
  String get startY => 'प्रारंभ Y';

  @override
  String get startZ => 'प्रारंभ Z';

  @override
  String get startCollectionButton => 'संग्रह शुरू करें';

  @override
  String get pleaseEnterValidValues =>
      'कृपया X, Y और Z के लिए मान्य संख्यात्मक मान दर्ज करें';

  @override
  String get stopDataCollection => 'डेटा संग्रह रोकें?';

  @override
  String get stopDataCollectionMessage =>
      'डेटा ट्रांसमिशन वर्तमान में सक्रिय है। वापस जाने पर ट्रांसमिशन रुक जाएगा। क्या आप जारी रखना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get stopAndGoBack => 'रोकें और वापस जाएं';

  @override
  String initializationFailed(String error) {
    return 'प्रारंभीकरण विफल: $error';
  }

  @override
  String cameraInitializationFailed(String error) {
    return 'कैमरा प्रारंभीकरण विफल: $error';
  }

  @override
  String locationInitializationFailed(String error) {
    return 'स्थान प्रारंभीकरण विफल: $error';
  }

  @override
  String get locationServicesDisabled => 'स्थान सेवाएं अक्षम हैं';

  @override
  String get locationPermissionsDenied => 'स्थान अनुमतियां अस्वीकार की गई हैं';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'स्थान अनुमतियां स्थायी रूप से अस्वीकार की गई हैं';

  @override
  String get locationServicesRequired =>
      'संग्रह शुरू करने के लिए स्थान सेवाएं आवश्यक हैं।';

  @override
  String get noVehicleSelected =>
      'त्रुटि: कोई वाहन नहीं चुना गया। कृपया गैराज में जाएं और वाहन चुनें।';

  @override
  String failedToStartCollection(String error) {
    return 'संग्रह शुरू करने में विफल: $error';
  }

  @override
  String get warningFailedToSaveDriveSession =>
      'चेतावनी: ड्राइव सत्र समय सहेजने में विफल';

  @override
  String get addVehicleTitle => 'वाहन जोड़ें';

  @override
  String get modelLabel => 'मॉडल';

  @override
  String get modelHint => 'जैसे, Honda City';

  @override
  String get registrationNumberLabel => 'पंजीकरण नंबर';

  @override
  String get registrationNumberHint => 'जैसे, KA01AB1234';

  @override
  String get insuranceNumberLabel => 'बीमा नंबर';

  @override
  String get insuranceNumberHint => 'जैसे, INS123456789';

  @override
  String get pucDateLabel => 'PUC तारीख';

  @override
  String get selectDateHint => 'तारीख चुनें';

  @override
  String get addVehicleButton => 'वाहन जोड़ें';

  @override
  String get editProfileTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get nameLabel => 'नाम';

  @override
  String get nameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get usernameHint => 'अपना उपयोगकर्ता नाम दर्ज करें';

  @override
  String get phoneHint => 'अपना फ़ोन नंबर दर्ज करें';

  @override
  String get addressHint => 'अपना पता दर्ज करें';

  @override
  String get updateProfileButton => 'प्रोफ़ाइल अपडेट करें';

  @override
  String get confirmPasswordTitle => 'पासवर्ड की पुष्टि करें';

  @override
  String get passwordHint => 'पुष्टि के लिए अपना पासवर्ड दर्ज करें';

  @override
  String get verifyAndDelete => 'सत्यापित करें और हटाएं';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get confirmLogout => 'लॉगआउट की पुष्टि करें';

  @override
  String get confirmLogoutMessage =>
      'क्या आप इस खाते से लॉगआउट करना चाहते हैं?';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get confirmDeletion => 'हटाने की पुष्टि करें';

  @override
  String get confirmDeletionMessage =>
      'क्या आप अपना खाता हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती और आपका सारा डेटा खो जाएगा।';

  @override
  String get delete => 'हटाएं';

  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get resetPasswordMessage =>
      'पासवर्ड रीसेट लिंक प्राप्त करने के लिए अपना ईमेल पता दर्ज करें।';

  @override
  String get sendLink => 'लिंक भेजें';

  @override
  String get passwordResetEmailSent =>
      'पासवर्ड रीसेट ईमेल भेज दिया गया! अपना इनबॉक्स जांचें।';

  @override
  String errorResetPassword(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get loggingOut => 'लॉगआउट हो रहा है...';

  @override
  String failedToLogout(String error) {
    return 'लॉगआउट में विफल: $error';
  }

  @override
  String get accountDeletedSuccessfully => 'खाता सफलतापूर्वक हटाया गया';

  @override
  String get confirmingLogin => 'लॉगिन की पुष्टि की जा रही है...';

  @override
  String get cropImage => 'छवि क्रॉप करें';

  @override
  String get profileUpdatedSuccessfully => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई!';

  @override
  String failedToUpdateProfile(String error) {
    return 'प्रोफ़ाइल अपडेट करने में विफल: $error';
  }

  @override
  String get profilePictureUpdatedSuccessfully =>
      'प्रोफ़ाइल चित्र सफलतापूर्वक अपडेट किया गया!';

  @override
  String failedToUpdateProfilePicture(String error) {
    return 'प्रोफ़ाइल चित्र अपडेट करने में विफल: $error';
  }

  @override
  String get userNotLoggedIn => 'उपयोगकर्ता लॉग इन नहीं है';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get uploadingProfilePicture => 'प्रोफ़ाइल चित्र अपलोड हो रहा है...';

  @override
  String get viewMore => 'और देखें';

  @override
  String get showLess => 'कम दिखाएं';

  @override
  String get email => 'ईमेल';

  @override
  String get userNotLoggedInError => 'उपयोगकर्ता लॉग इन नहीं है';
}
