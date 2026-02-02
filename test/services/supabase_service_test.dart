import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mti_ptk/services/supabase_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  test('SupabaseService.client returns injected mock client', () {
    final service = SupabaseService.instance;
    final mockClient = MockSupabaseClient();
    
    // Inject mock
    service.mockClient = mockClient;
    
    expect(service.client, equals(mockClient));
  });
}
