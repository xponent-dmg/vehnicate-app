String? registrationNumberValidator(String? value) {
  final registration = value?.trim() ?? '';
  if (registration.isEmpty) return 'Required';
  if (!RegExp(r'^[A-Za-z]{2}\d{2}[A-Za-z]{2}\d{4}$').hasMatch(registration)) {
    return 'Use format AA00AA0000';
  }
  return null;
}
