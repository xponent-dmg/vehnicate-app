import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnway/services/supabase/supabase_core_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

void main() {
  group('SupabaseCoreService Tests', () {
    late SupabaseCoreService coreService;

    setUp(() {
      coreService = SupabaseCoreService();
    });

    test('Singleton check', () {
      expect(SupabaseCoreService(), equals(coreService));
    });
  });
}
