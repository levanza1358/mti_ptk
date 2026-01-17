import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mti_ptk/config/supabase_config.dart';
import 'package:mti_ptk/controller/login_controller.dart';
import 'package:mti_ptk/page/login_page.dart';
import 'package:mti_ptk/page/home_page.dart';
import 'package:mti_ptk/page/cuti_page.dart';
import 'package:mti_ptk/page/insentif_page.dart';
import 'package:mti_ptk/page/settings_page.dart';
import 'package:mti_ptk/page/surat_keluar_page.dart';
import 'package:mti_ptk/page/data_management_page.dart';
import 'package:mti_ptk/page/tambah_pegawai_page.dart';
import 'package:mti_ptk/page/edit_pegawai_page.dart';
import 'package:mti_ptk/page/tambah_group_page.dart';
import 'package:mti_ptk/page/edit_group_page.dart';
import 'package:mti_ptk/page/tambah_jabatan_page.dart';
import 'package:mti_ptk/page/edit_jabatan_page.dart';
import 'package:mti_ptk/page/edit_supervisor_page.dart';
import 'package:mti_ptk/page/semua_data_eksepsi_page.dart';
import 'package:mti_ptk/page/semua_data_cuti_page.dart';
import 'package:mti_ptk/page/semua_data_insentif_page.dart';
import 'package:mti_ptk/page/eksepsi_page.dart';
import 'package:mti_ptk/page/kalender_cuti_page.dart';
import 'package:mti_ptk/page/data_pribadi_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID');

  // Create permanent LoginController for the entire app
  final LoginController controller = Get.isRegistered<LoginController>()
      ? Get.find<LoginController>()
      : Get.put(LoginController(), permanent: true);

  // Load saved login data without redirecting
  await controller.checkLoginStatus(shouldRedirect: false);

  final String initialRoute = controller.isLoggedIn.value ? '/home' : '/login';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PT Multi Terminal Indonesia LR 2 Area Pontianak',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.blue.shade600,
          onPrimary: Colors.white,
          primaryContainer: Colors.blue.shade50,
          onPrimaryContainer: Colors.blue.shade900,
          secondary: Colors.pinkAccent.shade100,
          onSecondary: Colors.white,
          secondaryContainer: Colors.pink.shade50,
          onSecondaryContainer: Colors.pink.shade900,
          surface: const Color(0xFFF6F7FB),
          onSurface: const Color(0xFF1B1E24),
          surfaceContainerHighest: Colors.white,
          onSurfaceVariant: Colors.grey.shade700,
          outline: Colors.grey.shade300,
          outlineVariant: Colors.grey.shade200,
          shadow: Colors.black.withValues(alpha: 0.1),
          inverseSurface: const Color(0xFF1B1E24),
          onInverseSurface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          // Enhanced dark theme colors
          primary: Colors.blue.shade300,
          onPrimary: Colors.black,
          primaryContainer: Colors.blue.shade900,
          onPrimaryContainer: Colors.blue.shade100,
          secondary: Colors.teal.shade300,
          onSecondary: Colors.black,
          secondaryContainer: Colors.teal.shade900,
          onSecondaryContainer: Colors.teal.shade100,
          tertiary: Colors.purple.shade300,
          onTertiary: Colors.black,
          tertiaryContainer: Colors.purple.shade900,
          onTertiaryContainer: Colors.purple.shade100,
          error: Colors.red.shade300,
          onError: Colors.black,
          errorContainer: Colors.red.shade900,
          onErrorContainer: Colors.red.shade100,
          surface: Color(0xFF0F1419), // Darker surface
          onSurface: Colors.white,
          surfaceContainerHighest: Color(0xFF1C1B1F),
          onSurfaceVariant: Colors.white.withValues(alpha: 0.8),
          outline: Colors.white.withValues(alpha: 0.2),
          outlineVariant: Colors.white.withValues(alpha: 0.1),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: Colors.white,
          onInverseSurface: Colors.black,
          inversePrimary: Colors.blue.shade600,
          surfaceTint: Colors.blue.shade300,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<LoginController>()) {
              final controller = LoginController();
              Get.put(controller, permanent: true);
              // For login page, check status with redirect
              controller.checkLoginStatus(shouldRedirect: true);
            }
          }),
        ),
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/cuti', page: () => const CutiPage()),
        GetPage(name: '/insentif', page: () => const InsentifPage()),
        GetPage(name: '/surat-keluar', page: () => const SuratKeluarPage()),
        GetPage(
            name: '/data-management', page: () => const DataManagementPage()),
        GetPage(name: '/tambah-pegawai', page: () => const TambahPegawaiPage()),
        GetPage(name: '/edit-pegawai', page: () => const EditPegawaiPage()),
        GetPage(name: '/tambah-group', page: () => const TambahGroupPage()),
        GetPage(name: '/edit-group', page: () => const EditGroupPage()),
        GetPage(name: '/tambah-jabatan', page: () => const TambahJabatanPage()),
        GetPage(name: '/edit-jabatan', page: () => const EditJabatanPage()),
        GetPage(
            name: '/edit-supervisor', page: () => const EditSupervisorPage()),
        GetPage(name: '/eksepsi', page: () => const EksepsiPage()),
        GetPage(name: '/kalender-cuti', page: () => const KalenderCutiPage()),
        GetPage(
            name: '/semua-data-eksepsi',
            page: () => const SemuaDataEksepsiPage()),
        GetPage(
            name: '/semua-data-cuti', page: () => const SemuaDataCutiPage()),
        GetPage(
            name: '/semua-data-insentif',
            page: () => const SemuaDataInsentifPage()),
        GetPage(name: '/settings', page: () => const SettingsPage()),
        GetPage(name: '/data-pribadi', page: () => const DataPribadiPage()),
      ],
    );
  }
}
