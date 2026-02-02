// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/supabase_service.dart';
import '../config/page_colors.dart';
import '../utils/top_toast.dart';
import '../utils/web_download.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  late final Future<Map<String, int>> _summaryFuture;
  bool _isExportingPegawai = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummaryCounts();
  }

  Future<void> _exportPegawaiToExcel() async {
    if (_isExportingPegawai) return;
    setState(() {
      _isExportingPegawai = true;
    });

    try {
      final users = await SupabaseService.instance.client.from('users').select(
          'nrp, name, jabatan, "group", kontak, ukuran_baju, ukuran_celana, ukuran_sepatu');

      final rows = List<Map<String, dynamic>>.from(users);

      final excel = xlsx.Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      final header = <xlsx.CellValue?>[
        xlsx.TextCellValue('No'),
        xlsx.TextCellValue('NRP'),
        xlsx.TextCellValue('Nama'),
        xlsx.TextCellValue('Jabatan'),
        xlsx.TextCellValue('Group'),
        xlsx.TextCellValue('Nomor HP'),
        xlsx.TextCellValue('Ukuran Baju'),
        xlsx.TextCellValue('Ukuran Celana'),
        xlsx.TextCellValue('Ukuran Sepatu'),
      ];

      sheet.appendRow(header);

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final rawKontak = (row['kontak'] ?? '').toString();
        final formattedKontak = _formatPhone(rawKontak);
        sheet.appendRow(<xlsx.CellValue?>[
          xlsx.TextCellValue((i + 1).toString()),
          xlsx.TextCellValue((row['nrp'] ?? '').toString()),
          xlsx.TextCellValue((row['name'] ?? '').toString()),
          xlsx.TextCellValue((row['jabatan'] ?? '').toString()),
          xlsx.TextCellValue((row['group'] ?? '').toString()),
          xlsx.TextCellValue(formattedKontak),
          xlsx.TextCellValue((row['ukuran_baju'] ?? '').toString()),
          xlsx.TextCellValue((row['ukuran_celana'] ?? '').toString()),
          xlsx.TextCellValue((row['ukuran_sepatu'] ?? '').toString()),
        ]);
      }

      final bytes = Uint8List.fromList(excel.encode()!);
      final fileName =
          'data_pegawai_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        await triggerDownload(bytes, fileName);
        showTopToast(
          'File Excel diunduh melalui browser',
          background: Colors.green,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);

      showTopToast(
        'File Excel tersimpan di ${file.path}',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal export data pegawai: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPegawai = false;
        });
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark
                    ? PageColors.dataManagementDark
                    : PageColors.dataManagementLight,
                (isDark
                        ? PageColors.dataManagementDark
                        : PageColors.dataManagementLight)
                    .withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                _buildActionCard(
                  context,
                  'Export Pegawai ke Excel',
                  Icons.download,
                  Colors.green,
                  _exportPegawaiToExcel,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color),
                  ),
                  child: Icon(Icons.chevron_right, color: color, size: 20),
                ),
              ],
            ),
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
