import 'package:flutter_test/flutter_test.dart';
import 'package:vehnway/utils/vehicle_validation.dart';

void main() {
  test('accepts the required registration format', () {
    expect(registrationNumberValidator('KA01AB1234'), isNull);
    expect(registrationNumberValidator('ka01ab1234'), isNull);
  });

  test('rejects registrations that do not match the required format', () {
    expect(registrationNumberValidator('KA1AB1234'), isNotNull);
    expect(registrationNumberValidator('KA01ABC1234'), isNotNull);
    expect(registrationNumberValidator('KA01AB123'), isNotNull);
    expect(registrationNumberValidator(''), 'Required');
  });
}
