import 'package:flutter_test/flutter_test.dart';
import 'package:vehnway/utils/vehicle_validation.dart';

void main() {
  test('accepts optional / null / empty registration', () {
    expect(registrationNumberValidator(null), isNull);
    expect(registrationNumberValidator(''), isNull);
    expect(registrationNumberValidator('   '), isNull);
    expect(isValidIndianRegistration(null), isTrue);
    expect(isValidIndianRegistration(''), isTrue);
  });

  test('accepts Indian registration numbers separated by space or hyphen', () {
    expect(registrationNumberValidator('KA-01-AB-1234'), isNull);
    expect(registrationNumberValidator('KA 01 AB 1234'), isNull);
    expect(registrationNumberValidator('ka-01-ab-1234'), isNull);
    expect(registrationNumberValidator('DL 1C AA 1111'), isNull);
    expect(registrationNumberValidator('DL-1C-AA-1111'), isNull);
    expect(registrationNumberValidator('22 BH 1234 AA'), isNull);
    expect(registrationNumberValidator('22-BH-1234-AA'), isNull);
  });

  test('rejects registrations that do not match the required Indian format with space/hyphen', () {
    expect(registrationNumberValidator('KA01AB1234'), isNotNull);
    expect(registrationNumberValidator('KA_01_AB_1234'), isNotNull);
    expect(registrationNumberValidator('KA 01 AB 12345'), isNotNull);
    expect(registrationNumberValidator('12345'), isNotNull);
    expect(registrationNumberValidator('K 01 AB 1234'), isNotNull);
  });
}
