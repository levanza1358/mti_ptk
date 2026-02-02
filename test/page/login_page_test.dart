import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mti_ptk/controller/login_controller.dart';
import 'package:mti_ptk/page/login_page.dart';
import 'package:mti_ptk/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    
    final mockService = MockSupabaseService();
    SupabaseService.instance = mockService;
    
    // We need to mock the client getter because LoginController checkLoginStatus might access it
    // calling SupabaseService.instance.client
    final mockClient = MockSupabaseClient();
    when(() => mockService.client).thenReturn(mockClient);
    
    Get.put(LoginController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));

    expect(find.text('PT Multi Terminal Indonesia'), findsOneWidget);
    expect(find.text('LR 2 Area Pontianak'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // NRP and Password
  });

  testWidgets('LoginPage shows validation error on empty submit', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
      
      await tester.tap(find.text('LOGIN'));
      await tester.pump();
      
      expect(find.text('NRP tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);
  });
}
