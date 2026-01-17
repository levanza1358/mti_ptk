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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withValues(alpha: 0.06),
              ),
            ),
          ),
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final user = loginController.currentUser.value;
                  final userDetail = homeController.userDetail.value ?? {};

                  final nama = (userDetail['name'] ?? user?['name'] ?? 'User')
                      .toString();
                  final nrp =
                      (userDetail['nrp'] ?? user?['nrp'] ?? '-').toString();
                  final jabatan =
                      (userDetail['jabatan'] ?? user?['jabatan'] ?? '-')
                          .toString();
                  final group =
                      (userDetail['group'] ?? user?['group'] ?? '-').toString();

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Text(
                            (nama.isNotEmpty ? nama[0] : 'U').toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nama,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    tooltip: 'Refresh',
                                    onPressed: () {
                                      homeController.fetchUserDetail();
                                      homeController.fetchAnnualSummary();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NRP: $nrp',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Jabatan: $jabatan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                'Group: $group',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.8),
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
                          currencyFormat
                              .format(homeController.totalPremi.value),
                          Colors.blueAccent,
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Lembur (${DateTime.now().year})',
                          '',
                          currencyFormat
                              .format(homeController.totalLembur.value),
                          Colors.pinkAccent,
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
                Obx(() {
                  final permissions =
                      loginController.currentJabatan.value ?? {};

                  // Helper to check permission
                  bool has(String key) => permissions[key] == true;
                  final List<Widget> menuItems = [];

                  menuItems.add(_buildMenuTile(
                    context,
                    'Data Pribadi',
                    'Ubah nomor HP dan ukuran',
                    Icons.person,
                    Colors.blue,
                    () => Get.toNamed('/data-pribadi')?.then((_) {
                      homeController.fetchUserDetail();
                    }),
                  ));

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
                const SizedBox(height: 24),
                Obx(() {
                  final user = loginController.currentUser.value;
                  final userDetail = homeController.userDetail.value ?? {};
                  final isDetailLoading =
                      homeController.isUserDetailLoading.value;

                  final rawKontak =
                      (userDetail['kontak'] ?? user?['kontak'] ?? '')
                          .toString();
                  final kontak =
                      rawKontak.isEmpty ? '-' : _formatPhone(rawKontak);
                  final ukuranBaju =
                      (userDetail['ukuran_baju'] ?? '-').toString();
                  final ukuranCelana =
                      (userDetail['ukuran_celana'] ?? '-').toString();
                  final ukuranSepatu =
                      (userDetail['ukuran_sepatu'] ?? '-').toString();

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.blueGrey.shade900,
                                Colors.blueGrey.shade800,
                              ]
                            : [
                                Colors.blue.shade50,
                                Colors.blue.shade100,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.blue.withValues(alpha: 0.12),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data Pribadi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.color,
                                        ),
                                      ),
                                      Text(
                                        'Pastikan data selalu terbaru',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    Get.toNamed('/data-pribadi')?.then((_) {
                                  homeController.fetchUserDetail();
                                }),
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isDetailLoading)
                            const LinearProgressIndicator(minHeight: 2)
                          else ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Nomor HP / WA: $kontak',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.checkroom, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ukuran Baju: $ukuranBaju',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.straighten, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ukuran Celana: $ukuranCelana',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.directions_walk, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ukuran Sepatu: $ukuranSepatu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String subtitle,
      String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSubtitle = subtitle.trim().isNotEmpty;

    final bgGradient = LinearGradient(
      colors: [
        color.withValues(alpha: isDark ? 0.35 : 0.18),
        color.withValues(alpha: isDark ? 0.15 : 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: bgGradient,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? color : Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = LinearGradient(
      colors: [
        color.withValues(alpha: isDark ? 0.35 : 0.18),
        color.withValues(alpha: isDark ? 0.2 : 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradient,
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
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? color : Colors.black87,
                    size: 24,
                  ),
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPhone(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^0-9]'), '');

    if (s.startsWith('00')) {
      s = s.substring(2);
    }

    if (s.startsWith('62')) {
      return s;
    }

    if (s.startsWith('0') && s.length > 1) {
      return '62${s.substring(1)}';
    }

    if (s.startsWith('8')) {
      return '62$s';
    }

    return s;
  }
}
