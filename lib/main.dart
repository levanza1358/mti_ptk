import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mti_ptk/config/supabase_config.dart';
import 'package:mti_ptk/config/app_theme.dart';
import 'package:mti_ptk/controller/login_controller.dart';
import 'package:mti_ptk/controller/theme_controller.dart';
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

  // Initialize ThemeController for dark mode support
  Get.put(ThemeController(), permanent: true);

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
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'PT Multi Terminal Indonesia LR 2 Area Pontianak',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: themeController.themeMode,
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
          GetPage(
              name: '/tambah-pegawai', page: () => const TambahPegawaiPage()),
          GetPage(name: '/edit-pegawai', page: () => const EditPegawaiPage()),
          GetPage(name: '/tambah-group', page: () => const TambahGroupPage()),
          GetPage(name: '/edit-group', page: () => const EditGroupPage()),
          GetPage(
              name: '/tambah-jabatan', page: () => const TambahJabatanPage()),
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
      ),
    );
  }
}
