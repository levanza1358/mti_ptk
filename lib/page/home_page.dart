import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTI PTK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: loginController.logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final user = loginController.currentUser.value;
              return Text(
                'Selamat datang, ${user?['name'] ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Dashboard MTI Pontianak',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuCard(
                  context,
                  'Data Pegawai',
                  Icons.people,
                  Colors.blue,
                  () => Get.toNamed('/data-pegawai'),
                ),
                _buildMenuCard(
                  context,
                  'Cuti',
                  Icons.calendar_today,
                  Colors.green,
                  () => Get.toNamed('/cuti'),
                ),
                _buildMenuCard(
                  context,
                  'Eksepsi',
                  Icons.warning,
                  Colors.orange,
                  () => Get.toNamed('/eksepsi'),
                ),
                _buildMenuCard(
                  context,
                  'Kalender Cuti',
                  Icons.calendar_view_month,
                  Colors.purple,
                  () => Get.toNamed('/kalender-cuti'),
                ),
                _buildMenuCard(
                  context,
                  'Insentif',
                  Icons.attach_money,
                  Colors.orange,
                  () => Get.toNamed('/insentif'),
                ),
                _buildMenuCard(
                  context,
                  'Surat Keluar',
                  Icons.description,
                  Colors.purple,
                  () => Get.toNamed('/surat-keluar'),
                ),
                _buildMenuCard(
                  context,
                  'Group Management',
                  Icons.group,
                  Colors.teal,
                  () => Get.toNamed('/group-management'),
                ),
                _buildMenuCard(
                  context,
                  'Semua Data Eksepsi',
                  Icons.warning,
                  Colors.amber,
                  () => Get.toNamed('/semua-data-eksepsi'),
                ),
                _buildMenuCard(
                  context,
                  'Semua Data Cuti',
                  Icons.calendar_view_month,
                  Colors.teal,
                  () => Get.toNamed('/semua-data-cuti'),
                ),
                _buildMenuCard(
                  context,
                  'Semua Data Insentif',
                  Icons.attach_money,
                  Colors.deepOrange,
                  () => Get.toNamed('/semua-data-insentif'),
                ),
                _buildMenuCard(
                  context,
                  'Data Management',
                  Icons.admin_panel_settings,
                  Colors.red,
                  () => Get.toNamed('/data-management'),
                ),
                _buildMenuCard(
                  context,
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => Get.toNamed('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
