import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_page.dart';
import '../utils/top_toast.dart';

class SemuaDataEksepsiPage extends StatefulWidget {
  const SemuaDataEksepsiPage({super.key});

  @override
  State<SemuaDataEksepsiPage> createState() => _SemuaDataEksepsiPageState();
}

class _SemuaDataEksepsiPageState extends State<SemuaDataEksepsiPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _historyMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime _addMonths(DateTime base, int months) {
    return DateTime(base.year, base.month + months, 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: Text(
            'Eksepsi - ${DateFormat('MMMM yyyy', 'id_ID').format(_historyMonth)}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau NRP',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _historyMonth = _addMonths(_historyMonth, -1);
                    });
                  },
                  tooltip: 'Bulan sebelumnya',
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(_historyMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _historyMonth = _addMonths(_historyMonth, 1);
                    });
                  },
                  tooltip: 'Bulan berikutnya',
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllEksepsi(month: _historyMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final eksepsi = snapshot.data ?? [];
                final filteredEksepsi = eksepsi.where((item) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      (item['nama']?.toLowerCase().contains(_searchQuery) ==
                          true) ||
                      (item['nrp']?.toLowerCase().contains(_searchQuery) ==
                          true);

                  return matchesSearch;
                }).toList();

                if (filteredEksepsi.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.report_problem_outlined,
                            size: 52,
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada data eksepsi',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  key: const PageStorageKey('eksepsi_list'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filteredEksepsi.length,
                  itemBuilder: (context, index) {
                    final item = filteredEksepsi[index];
                    final nama = (item['nama'] ?? 'Unknown').toString();
                    final tanggalPengajuan =
                        (item['formatted_tanggal_pengajuan'] ?? '-').toString();
                    final tanggalEksepsi =
                        (item['formatted_tanggal_eksepsi'] ?? '-').toString();
                    final badgeColor = Colors.orange;

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
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetailDialog(item),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: badgeColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: badgeColor,
                                    child: Text(
                                      (nama.isNotEmpty ? nama[0] : '?')
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nama,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tanggal Pengajuan: $tanggalPengajuan',
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tanggal Eksepsi: $tanggalEksepsi',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            size: 20,
                                          ),
                                          tooltip: 'Lihat PDF',
                                          onPressed: () =>
                                              _previewEksepsiPdf(item),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print,
                                            size: 20,
                                          ),
                                          tooltip: 'Print',
                                          onPressed: () =>
                                              _showPrintDialog(item),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Hapus',
                                      onPressed: () =>
                                          _confirmDeleteEksepsi(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> eksepsi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Eksepsi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${eksepsi['nama']}'),
              Text('NRP: ${eksepsi['nrp']}'),
              Text('Jenis: ${eksepsi['jenis_eksepsi']}'),
              if (eksepsi['tanggal_pengajuan'] != null)
                Text(
                  'Tanggal Pengajuan: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(eksepsi['tanggal_pengajuan']))}',
                ),
              const SizedBox(height: 16),
              const Text('Tanggal Eksepsi:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              // Here you would load and display eksepsi_tanggal data
              const Text('(Detail tanggal akan dimuat...)'),
            ],
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

  void _showPrintDialog(Map<String, dynamic> eksepsi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Eksepsi'),
        content: const Text(
          'Dokumen eksepsi akan dicetak dan memerlukan tanda tangan manual untuk approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showTopToast(
                'Dokumen eksepsi dikirim ke printer',
                background: Colors.blue,
                foreground: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEksepsi(Map<String, dynamic> eksepsi) async {
    final eksepsiId = (eksepsi['id'] ?? '').toString();
    if (eksepsiId.isEmpty) {
      showTopToast(
        'ID eksepsi tidak valid',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final jenis = (eksepsi['jenis_eksepsi'] ?? '').toString();
    final tanggal = (eksepsi['tanggal_pengajuan'] ?? '').toString();
    final parsedTanggal = DateTime.tryParse(tanggal);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus eksepsi ini?'),
            const SizedBox(height: 8),
            if (jenis.isNotEmpty) Text('Jenis: $jenis'),
            if (parsedTanggal != null)
              Text(
                'Tanggal Pengajuan: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(parsedTanggal)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEksepsiById(eksepsiId);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEksepsiById(String eksepsiId) async {
    try {
      try {
        await SupabaseService.instance.client
            .from('eksepsi_tanggal')
            .delete()
            .eq('eksepsi_id', eksepsiId);
      } catch (_) {}

      await SupabaseService.instance.client
          .from('eksepsi')
          .delete()
          .eq('id', eksepsiId);

      showTopToast(
        'Eksepsi berhasil dihapus',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );

      setState(() {});
    } catch (e) {
      showTopToast(
        'Gagal menghapus eksepsi: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchEksepsiDetail(String id) async {
    try {
      final response =
          await SupabaseService.instance.client.from('eksepsi').select('''
            id, user_id, jenis_eksepsi, tanggal_pengajuan, created_at, url_ttd_eksepsi,
            eksepsi_tanggal(urutan, tanggal_eksepsi, alasan_eksepsi)
          ''').eq('id', id).single();
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchUserById(String userId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('users')
          .select('id, name, nrp, jabatan, kontak, "group", status')
          .eq('id', userId)
          .single();
      return response;
    } catch (_) {
      return null;
    }
  }

  String _getSupervisorJenisByUserStatus(String? userStatus) {
    if (userStatus == 'Non Operasional') {
      return 'Penunjang';
    }
    if (userStatus == 'Operasional') {
      return 'Logistik';
    }
    return 'Logistik';
  }

  Future<Map<String, dynamic>?> _fetchSupervisorByJenis(String jenis) async {
    try {
      final response = await SupabaseService.instance.client
          .from('supervisor')
          .select('*')
          .eq('jenis', jenis)
          .single();
      return response;
    } catch (_) {
      return null;
    }
  }

  void _previewEksepsiPdf(Map<String, dynamic> item) async {
    final eksepsiId = (item['id'] ?? '').toString();
    if (eksepsiId.isEmpty) {
      showTopToast(
        'ID eksepsi tidak valid',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final userId = (item['user_id'] ?? '').toString();
    if (userId.isEmpty) {
      showTopToast(
        'User ID tidak ditemukan',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      showTopToast(
        'Memuat PDF eksepsi...',
        background: Colors.blue,
        foreground: Colors.white,
        duration: const Duration(seconds: 2),
      );

      final detail = await _fetchEksepsiDetail(eksepsiId);
      final user = await _fetchUserById(userId);

      if (user == null) {
        showTopToast(
          'Data user tidak ditemukan',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final eksepsiData = <String, dynamic>{
        ...item,
        if (detail != null) ...detail,
      };

      final supervisorJenis =
          _getSupervisorJenisByUserStatus(user['status']?.toString());
      final supervisorData = await _fetchSupervisorByJenis(supervisorJenis);
      final managerData = await _fetchSupervisorByJenis('Manager_PDS');

      final pdfData = await PdfService.generateEksepsiPdf(
        eksepsiData: eksepsiData,
        userData: user,
        supervisorData: supervisorData,
        managerData: managerData,
      );

      if (pdfData.isEmpty) {
        showTopToast(
          'PDF kosong, data eksepsi tidak valid',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      Get.to(
        () => PdfPreviewPage(
          title: 'PDF Eksepsi - ${user['name'] ?? 'Unknown'}',
          pdfGenerator: () async => pdfData,
        ),
      );
    } catch (e) {
      showTopToast(
        'Gagal memuat PDF eksepsi: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllEksepsi(
      {required DateTime month}) async {
    try {
      // First, check if eksepsi table exists with simple query
      final simpleResponse = await SupabaseService.instance.client
          .from('eksepsi')
          .select('id')
          .limit(1);

      if (simpleResponse.isEmpty) {
        return [];
      }

      final startOfMonth = DateTime(month.year, month.month, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      // Try full query tanpa join kompleks
      final response = await SupabaseService.instance.client
          .from('eksepsi')
          .select('''
            id, user_id, jenis_eksepsi, tanggal_pengajuan,
            eksepsi_tanggal(tanggal_eksepsi)
          ''')
          .gte('tanggal_pengajuan', startOfMonth.toIso8601String())
          .lt('tanggal_pengajuan', nextMonth.toIso8601String())
          .order('tanggal_pengajuan', ascending: false)
          .limit(50);

      final List<dynamic> rows = response;
      final userIds = rows
          .map((e) => e['user_id'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> userById = {};
      if (userIds.isNotEmpty) {
        final users = await SupabaseService.instance.client
            .from('users')
            .select('id, name, nrp')
            .filter(
              'id',
              'in',
              '(${userIds.map((e) => '"$e"').join(',')})',
            );
        for (final u in users) {
          final id = (u['id'] ?? '').toString();
          if (id.isNotEmpty) {
            userById[id] = Map<String, dynamic>.from(u as Map);
          }
        }
      }

      return rows.map((item) {
        final tanggalPengajuan = item['tanggal_pengajuan'];

        String formattedTanggalPengajuan = '-';
        if (tanggalPengajuan != null) {
          try {
            formattedTanggalPengajuan = DateFormat('dd/MM/yyyy HH:mm', 'id_ID')
                .format(DateTime.parse(tanggalPengajuan));
          } catch (_) {}
        }

        DateTime? firstEksepsi;
        DateTime? lastEksepsi;
        final tanggalList = (item['eksepsi_tanggal'] as List<dynamic>?)
                ?.map((e) => e['tanggal_eksepsi'])
                .where((e) => e != null)
                .map((e) => DateTime.tryParse(e.toString()))
                .whereType<DateTime>()
                .toList() ??
            [];

        if (tanggalList.isNotEmpty) {
          tanggalList.sort();
          firstEksepsi = tanggalList.first;
          lastEksepsi = tanggalList.last;
        }

        String formattedTanggalEksepsi = '-';
        if (firstEksepsi != null && lastEksepsi != null) {
          final fmt = DateFormat('dd/MM/yyyy', 'id_ID');
          if (firstEksepsi.isAtSameMomentAs(lastEksepsi)) {
            formattedTanggalEksepsi = fmt.format(firstEksepsi);
          } else {
            formattedTanggalEksepsi =
                '${fmt.format(firstEksepsi)} - ${fmt.format(lastEksepsi)}';
          }
        }

        final userId = (item['user_id'] ?? '').toString();
        final user = userById[userId];
        final resolvedNama = (user?['name'] ?? 'Unknown').toString();
        final resolvedNrp = (user?['nrp'] ?? '-').toString();

        return {
          'id': item['id'],
          'user_id': userId,
          'jenis_eksepsi': item['jenis_eksepsi'] ?? 'Eksepsi',
          'tanggal_pengajuan': tanggalPengajuan,
          'nrp': resolvedNrp,
          'nama': resolvedNama,
          'formatted_tanggal_pengajuan': formattedTanggalPengajuan,
          'formatted_tanggal_eksepsi': formattedTanggalEksepsi,
        };
      }).toList();
    } catch (e) {
      // If query fails, try even simpler version
      try {
        final fallbackResponse = await SupabaseService.instance.client
            .from('eksepsi')
            .select('id, jenis_eksepsi')
            .limit(20);

        return fallbackResponse
            .map((item) => {
                  'id': item['id'],
                  'user_id': null,
                  'jenis_eksepsi': item['jenis_eksepsi'] ?? 'Eksepsi',
                  'tanggal_pengajuan': null,
                  'nrp': 'N/A',
                  'nama': 'Unknown User',
                  'formatted_tanggal_pengajuan': '-',
                  'formatted_tanggal_eksepsi': '-',
                })
            .toList();
      } catch (fallbackError) {
        // Final fallback - return empty list to prevent crash
        return [];
      }
    }
  }
}
