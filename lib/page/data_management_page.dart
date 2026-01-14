// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Get.previousRoute.isNotEmpty) {
              Get.back();
            } else {
              Get.offAllNamed('/home');
            }
          },
          tooltip: 'Kembali',
        ),
        title: const Text('Data Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Data Sistem',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambah, edit, dan kelola data pegawai, grup, jabatan, dan supervisor',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Pegawai Management
            _buildManagementSection(
              context,
              'Manajemen Pegawai',
              Icons.people,
              Colors.blue,
              [
                _buildActionCard(
                  'Tambah Pegawai',
                  Icons.person_add,
                  Colors.blue.shade100,
                  () => Get.toNamed('/tambah-pegawai'),
                ),
                _buildActionCard(
                  'Edit Pegawai',
                  Icons.edit,
                  Colors.blue.shade100,
                  () => Get.toNamed('/edit-pegawai'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Group Management
            _buildManagementSection(
              context,
              'Manajemen Grup',
              Icons.group,
              Colors.green,
              [
                _buildActionCard(
                  'Tambah Grup',
                  Icons.group_add,
                  Colors.green.shade100,
                  () => Get.toNamed('/tambah-group'),
                ),
                _buildActionCard(
                  'Edit Grup',
                  Icons.edit,
                  Colors.green.shade100,
                  () => Get.toNamed('/edit-group'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Jabatan Management
            _buildManagementSection(
              context,
              'Manajemen Jabatan',
              Icons.work,
              Colors.orange,
              [
                _buildActionCard(
                  'Tambah Jabatan',
                  Icons.add,
                  Colors.orange.shade100,
                  () => Get.toNamed('/tambah-jabatan'),
                ),
                _buildActionCard(
                  'Edit Jabatan',
                  Icons.edit,
                  Colors.orange.shade100,
                  () => Get.toNamed('/edit-jabatan'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Supervisor Management
            _buildManagementSection(
              context,
              'Manajemen Supervisor',
              Icons.supervisor_account,
              Colors.purple,
              [
                _buildActionCard(
                  'Tambah Supervisor',
                  Icons.person_add,
                  Colors.purple.shade100,
                  () => Get.toNamed('/tambah-supervisor'),
                ),
                _buildActionCard(
                  'Edit Supervisor',
                  Icons.edit,
                  Colors.purple.shade100,
                  () => Get.toNamed('/edit-supervisor'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                              'Pegawai', '0', Icons.people, Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                              'Grup', '0', Icons.group, Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                              'Jabatan', '0', Icons.work, Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Supervisor', '0',
                              Icons.supervisor_account, Colors.purple),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Container(), // Empty space
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> actionCards,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actionCards,
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color bgColor, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
