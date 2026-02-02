import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';
import '../controller/theme_controller.dart';
import '../config/page_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageColor =
        isDark ? PageColors.settingsLight : PageColors.settingsDark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: const Text('Pengaturan'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [pageColor, pageColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              gradient: LinearGradient(
                colors: [
                  pageColor.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Pengguna',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final user = loginController.currentUser.value;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: pageColor,
                        child: Text(
                          (user?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?['name'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'NRP: ${user?['nrp'] ?? '-'}',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              'Jabatan: ${user?['jabatan'] ?? '-'}',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Appearance Section
          const _SectionHeader(title: 'Tampilan'),
          Obx(() => _SettingsTile(
                title: 'Dark Mode',
                subtitle: themeController.isDarkMode.value
                    ? 'Tema gelap aktif'
                    : 'Tema terang aktif',
                trailing: Switch(
                  value: themeController.isDarkMode.value,
                  onChanged: (_) => themeController.toggleTheme(),
                  activeTrackColor: pageColor,
                ),
                onTap: () => themeController.toggleTheme(),
              )),

          const SizedBox(height: 16),

          // Account Section
          const _SectionHeader(title: 'Akun'),
          _SettingsTile(
            title: 'Logout',
            subtitle: 'Keluar dari aplikasi',
            trailing: const Icon(Icons.logout, color: Colors.red),
            onTap: () => _showLogoutDialog(context, loginController),
          ),

          // App Info Section
          const _SectionHeader(title: 'Tentang Aplikasi'),
          _SettingsTile(
            title: 'Versi Aplikasi',
            subtitle: '1.0.0+1',
            trailing: const Icon(Icons.info_outline),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LoginController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isAction = onTap != null;
    final trailingWidget = trailing ??
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(Icons.chevron_right, color: color, size: 20),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
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
                const SizedBox(width: 8),
                isAction ? trailingWidget : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
