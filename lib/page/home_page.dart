import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/login_controller.dart';
import '../controller/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final HomeController homeController = Get.put(HomeController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0, // Hide AppBar but keep status bar control
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Obx(() {
              final user = loginController.currentUser.value;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        (user?['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['name'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NRP: ${user?['nrp'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Summary Section
            Obx(() {
              if (homeController.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final currencyFormat = NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Premi (${DateTime.now().year})',
                      '',
                      currencyFormat.format(homeController.totalPremi.value),
                      Colors.green.shade600,
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Lembur (${DateTime.now().year})',
                      '',
                      currencyFormat.format(homeController.totalLembur.value),
                      Colors.orange.shade600,
                      Icons.access_time,
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            Text(
              "Menu Utama",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),

            // Menu List
            Obx(() {
              final permissions = loginController.currentJabatan.value ?? {};

              // Helper to check permission
              bool has(String key) => permissions[key] == true;

              final List<Widget> menuItems = [];

              if (has('permissionCuti')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Cuti',
                  'Pengajuan dan riwayat cuti',
                  Icons.calendar_today,
                  Colors.green,
                  () => Get.toNamed('/cuti'),
                ));
              }

              if (has('permissionCuti')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Kalender Cuti',
                  'Lihat jadwal cuti karyawan',
                  Icons.calendar_month,
                  Colors.purple,
                  () => Get.toNamed('/kalender-cuti'),
                ));
              }

              if (has('permissionAllCuti')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Semua Data Cuti',
                  'Rekap data cuti keseluruhan',
                  Icons.summarize,
                  Colors.teal,
                  () => Get.toNamed('/semua-data-cuti'),
                ));
              }

              if (has('permissionEksepsi')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Eksepsi',
                  'Pengajuan dan riwayat eksepsi',
                  Icons.warning_amber_rounded,
                  Colors.orange,
                  () => Get.toNamed('/eksepsi'),
                ));
              }

              if (has('permissionAllEksepsi')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Semua Data Eksepsi',
                  'Rekap data eksepsi keseluruhan',
                  Icons.report_problem,
                  Colors.amber.shade700,
                  () => Get.toNamed('/semua-data-eksepsi'),
                ));
              }

              if (has('permissionInsentif')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Insentif',
                  'Informasi insentif dan lembur',
                  Icons.monetization_on,
                  Colors.orange,
                  () => Get.toNamed('/insentif'),
                ));
              }

              if (has('permissionAllInsentif')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Semua Data Insentif',
                  'Rekap insentif karyawan',
                  Icons.payments,
                  Colors.deepOrange,
                  () => Get.toNamed('/semua-data-insentif'),
                ));
              }

              if (has('permissionSuratKeluar')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Surat Keluar',
                  'Arsip surat keluar',
                  Icons.outbox,
                  Colors.indigo,
                  () => Get.toNamed('/surat-keluar'),
                ));
              }

              if (has('permissionManagementData')) {
                menuItems.add(_buildMenuTile(
                  context,
                  'Data Management',
                  'Pengaturan data master',
                  Icons.admin_panel_settings,
                  Colors.red,
                  () => Get.toNamed('/data-management'),
                ));
              }

              // Settings - Always visible
              menuItems.add(_buildMenuTile(
                context,
                'Settings',
                'Pengaturan aplikasi',
                Icons.settings,
                Colors.grey,
                () => Get.toNamed('/settings'),
              ));

              return Column(
                children: menuItems,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String subtitle,
      String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          if (hasSubtitle)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          if (hasSubtitle) const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                          .iconTheme
                          .color
                          ?.withValues(alpha: 0.5) ??
                      Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
