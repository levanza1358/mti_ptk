import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/login_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          // User Info Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.cardColor,
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
                        backgroundColor: theme.primaryColor,
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
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              'Jabatan: ${user?['jabatan'] ?? '-'}',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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

          const SizedBox(height: 16),

          // Notifications Section
          const _SectionHeader(title: 'Notifikasi'),
          _SettingsTile(
            title: 'Notifikasi',
            subtitle: 'Aktifkan notifikasi aplikasi',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications', value);
              },
            ),
          ),

          // Account Section
          const _SectionHeader(title: 'Akun'),
          _SettingsTile(
            title: 'Ubah Password',
            subtitle: 'Perbarui password akun Anda',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.snackbar('Info', 'Fitur ubah password akan segera hadir');
            },
          ),

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

          _SettingsTile(
            title: 'Cek Pembaruan',
            subtitle: 'Periksa versi terbaru aplikasi',
            trailing: const Icon(Icons.system_update),
            onTap: () {
              Get.snackbar('Info', 'Fitur cek pembaruan akan segera hadir');
            },
          ),

          _SettingsTile(
            title: 'Hubungi Developer',
            subtitle: 'Kirim masukan atau laporkan masalah',
            trailing: const Icon(Icons.contact_support),
            onTap: () async {
              const email = 'mailto:support@mti-ptk.com?subject=Masukan Aplikasi MTI PTK';
              if (await canLaunchUrl(Uri.parse(email))) {
                await launchUrl(Uri.parse(email));
              } else {
                Get.snackbar('Error', 'Tidak dapat membuka email client');
              }
            },
          ),

          _SettingsTile(
            title: 'Lisensi',
            subtitle: 'Informasi lisensi aplikasi',
            trailing: const Icon(Icons.description),
            onTap: () {
              _showLicenseDialog(context);
            },
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

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lisensi'),
        content: const SingleChildScrollView(
          child: Text(
            'Aplikasi MTI PTK\n\n'
            'Versi: 1.0.0+1\n\n'
            'Dikembangkan untuk keperluan internal MTI Pontianak.\n\n'
            '© 2024 MTI PTK. All rights reserved.',
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
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
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
