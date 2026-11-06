/// Validates whether a given vehicle registration number follows Indian
/// number plate standards, separated by either a space or a hyphen.
/// Allows null or empty values (indicating optional registration).
bool isValidIndianRegistration(String? value) {
  if (value == null) return true;
  final clean = value.trim();
  if (clean.isEmpty) return true;

  // Standard Indian vehicle registration plate format:
  // 2 letters (State), 1-2 digits with optional class letter (RTO),
  // optional 1-3 letters (Series), 1-4 digits (Number),
  // separated by space or hyphen.
  final standardRegex = RegExp(
    r'^[A-Za-z]{2}[ -]+\d{1,2}[A-Za-z]?[ -]+(?:[A-Za-z]{1,3}[ -]+)?\d{1,4}$',
  );

  // Bharat Series (BH):
  // 2 digits (Year), BH, 4 digits, 1-2 letters, separated by space or hyphen.
  final bhRegex = RegExp(
    r'^\d{2}[ -]+BH[ -]+\d{4}[ -]+[A-Za-z]{1,2}$',
    caseSensitive: false,
  );

  return standardRegex.hasMatch(clean) || bhRegex.hasMatch(clean);
}

/// Form field validator for Indian vehicle registration number.
/// Registration number is optional, but if entered, must be formatted
/// with spaces or hyphens (e.g. "DL 01 AB 1234" or "DL-01-AB-1234").
String? registrationNumberValidator(String? value) {
  final registration = value?.trim() ?? '';
  if (registration.isEmpty) return null; // Optional

  if (!isValidIndianRegistration(registration)) {
    return 'Invalid format (KA-01-AB-1234 or KA 01 AB 1234)';
  }
  return null;
}
