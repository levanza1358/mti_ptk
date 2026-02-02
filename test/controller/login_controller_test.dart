import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mti_ptk/controller/login_controller.dart';
import 'package:mti_ptk/services/supabase_service.dart';

// Mocks
class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockSupabaseService;
  late LoginController controller;

  setUp(() {
    mockSupabaseService = MockSupabaseService();
    SupabaseService.instance = mockSupabaseService;
    
    // Clear GetX dependency injection
    Get.reset();
    
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginController', () {
    test('Initial state is correct', () {
      controller = LoginController();
      expect(controller.isLoading.value, false);
      expect(controller.isLoggedIn.value, false);
      expect(controller.currentUser.value, null);
    });

    test('validateNrp returns error for empty or short NRP', () {
      controller = LoginController();
      expect(controller.validateNrp(null), 'NRP tidak boleh kosong');
      expect(controller.validateNrp(''), 'NRP tidak boleh kosong');
      expect(controller.validateNrp('12'), 'NRP minimal 3 karakter');
      expect(controller.validateNrp('123'), null);
    });

    test('validatePassword returns error for empty or short password', () {
      controller = LoginController();
      expect(controller.validatePassword(null), 'Password tidak boleh kosong');
      expect(controller.validatePassword(''), 'Password tidak boleh kosong');
      expect(controller.validatePassword('12345'), 'Password minimal 6 karakter');
      expect(controller.validatePassword('123456'), null);
    });

    test('checkLoginStatus restores session if data exists', () async {
      final user = {'id': '1', 'name': 'Test User', 'nrp': '12345', 'jabatan': 'Staff'};
      SharedPreferences.setMockInitialValues({
        'current_user': json.encode(user),
      });

      controller = LoginController();
      
      // Mock fetchJabatanPermissions (it does a DB call)
      // Since it's void, we don't strictly need to mock it if we don't care about the side effect 
      // OR we should verify it calls client.
      // But fetchJabatanPermissions calls SupabaseService.instance.client...
      // We need to mock client call if we want to test that fully. 
      // For now, let's assume it fails gracefully or we mock the client getter on the service?
      // Wait, we mocked SupabaseService.instance.
      // But fetchJabatanPermissions calls `SupabaseService.instance.client`. 
      // Since `instance` is a Mock object, accessing `.client` on it will return null or throw if not stubbed.
      // We need to stub `client` getter on the mock service if it's accessed.
      
      // Actually, LoginController fetches the service instance via the static getter.
      // which returns our Mock object.
      // The code is: `await SupabaseService.instance.client.from(...)`
      // So we need to stub `mockSupabaseService.client`.
      // Mocking the full Supabase chain is hard.
      // However, checkLoginStatus calls `fetchJabatanPermissions`.
      // If we don't stub it, it might crash.
      // A better way is if `fetchJabatanPermissions` was a separate method we could mock? 
      // No, it's on the controller.
      
      // Let's assume for this basic test we expect it to try.
      // We can use `when(() => mockSupabaseService.client).thenThrow('Error');` 
      // The controller catches errors in `fetchJabatanPermissions` and prints to console.
      // So it shouldn't crash.
      
      when(() => mockSupabaseService.client).thenThrow(Exception('DB Error'));

      await controller.checkLoginStatus(shouldRedirect: false);

      expect(controller.isLoggedIn.value, true);
      expect(controller.currentUser.value, user);
    });
    
    test('checkLoginStatus does nothing if no data', () async {
      SharedPreferences.setMockInitialValues({});
      controller = LoginController();
      await controller.checkLoginStatus(shouldRedirect: false);
      expect(controller.isLoggedIn.value, false);
    });
  });
}
