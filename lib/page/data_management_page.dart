// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  late final Future<Map<String, int>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummaryCounts();
  }

  Future<int> _fetchTableCount(String table) async {
    try {
      final resp = await SupabaseService.instance.client
          .from(table)
          .select('id')
          .count();
      final dynamic countValue = (resp as dynamic).count;
      return countValue is int ? countValue : 0;
    } catch (e) {
      showTopToast(
        'Gagal memuat jumlah data $table: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return 0;
    }
  }

  Future<Map<String, int>> _fetchSummaryCounts() async {
    final results = await Future.wait<int>([
      _fetchTableCount('users'),
      _fetchTableCount('group'),
      _fetchTableCount('jabatan'),
      _fetchTableCount('supervisor'),
    ]);

    return {
      'pegawai': results[0],
      'grup': results[1],
      'jabatan': results[2],
      'supervisor': results[3],
    };
  }

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
                  context,
                  'Tambah Pegawai',
                  Icons.person_add,
                  Colors.blue,
                  () => Get.toNamed('/tambah-pegawai'),
                ),
                _buildActionCard(
                  context,
                  'Edit Pegawai',
                  Icons.edit,
                  Colors.blue,
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
                  context,
                  'Tambah Grup',
                  Icons.group_add,
                  Colors.green,
                  () => Get.toNamed('/tambah-group'),
                ),
                _buildActionCard(
                  context,
                  'Edit Grup',
                  Icons.edit,
                  Colors.green,
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
                  context,
                  'Tambah Jabatan',
                  Icons.add,
                  Colors.orange,
                  () => Get.toNamed('/tambah-jabatan'),
                ),
                _buildActionCard(
                  context,
                  'Edit Jabatan',
                  Icons.edit,
                  Colors.orange,
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
                  context,
                  'Edit Supervisor',
                  Icons.edit,
                  Colors.purple,
                  () => Get.toNamed('/edit-supervisor'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<Map<String, int>>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final data = snapshot.data;
                    final pegawai = data?['pegawai'];
                    final grup = data?['grup'];
                    final jabatan = data?['jabatan'];
                    final supervisor = data?['supervisor'];

                    String formatCount(int? value) {
                      if (value == null) return isLoading ? '-' : '0';
                      return value.toString();
                    }

                    return Column(
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
                                  'Pegawai',
                                  formatCount(pegawai),
                                  Icons.people,
                                  Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard('Grup', formatCount(grup),
                                  Icons.group, Colors.green),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                  'Jabatan',
                                  formatCount(jabatan),
                                  Icons.work,
                                  Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                  'Supervisor',
                                  formatCount(supervisor),
                                  Icons.supervisor_account,
                                  Colors.purple),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              flex: 2,
                              child: SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
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
                    color: color.withValues(alpha: 0.12),
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

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    final iconBg = color.withValues(alpha: 0.14);
    final iconBorder = color.withValues(alpha: 0.28);
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
                  color: iconBg,
                  border: Border.all(color: iconBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
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
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        color: color.withValues(alpha: 0.12),
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
