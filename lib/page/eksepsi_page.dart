import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import '../controller/login_controller.dart';
import 'pdf_preview_page.dart';
import '../utils/top_toast.dart';

class EksepsiPage extends StatefulWidget {
  const EksepsiPage({super.key});

  @override
  State<EksepsiPage> createState() => _EksepsiPageState();
}

class _EksepsiPageState extends State<EksepsiPage>
    with TickerProviderStateMixin {
  static const int _maxEksepsiDaysForOnePagePdf = 8;

  late TabController _tabController;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {};
  int _selectedYear = DateTime.now().year;

  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
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
          _tabController.index == 0 ? 'Pengajuan Eksepsi' : 'Riwayat Eksepsi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.zero,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Pengajuan'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationTab(context),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildApplicationTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Calendar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Tanggal Eksepsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Maksimal $_maxEksepsiDaysForOnePagePdf hari (untuk 1 halaman PDF)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TableCalendar(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) =>
                        _selectedDates.any((d) => isSameDay(d, day)),
                    onDaySelected: _onDaySelected,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDates.isNotEmpty) ...[
                    Text(
                      'Tanggal dipilih: ${_selectedDates.length} hari',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _selectedDates.map((date) {
                        return Chip(
                          label: Text(
                              DateFormat('dd/MM/yyyy', 'id_ID').format(date)),
                          onDeleted: () {
                            setState(() {
                              _selectedDates.remove(date);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reason
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alasan Eksepsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      hintText: 'Masukkan alasan pengajuan eksepsi...',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alasan eksepsi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDates.clear();
                      _reasonController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitExceptionApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ajukan Eksepsi',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Tahun sebelumnya',
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Expanded(
                  child: Text(
                    'TAHUN $_selectedYear',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Tahun berikutnya',
                  onPressed: () => setState(() => _selectedYear++),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchExceptionRequests(year: _selectedYear),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final exceptions = snapshot.data ?? [];
              if (exceptions.isEmpty) {
                return const Center(child: Text('Belum ada data eksepsi'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: exceptions.length,
                itemBuilder: (context, index) {
                  final exception = exceptions[index];
                  final tanggalEksepsiLabel =
                      _formatTanggalDdMmRange(exception);
                  final jumlahHari = _countTanggalEksepsi(exception);
                  final alasanPertama = _firstAlasanEksepsi(exception);
                  final pengajuanIso =
                      (exception['tanggal_pengajuan'] ?? '').toString();
                  final pengajuan = DateTime.tryParse(pengajuanIso);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showEksepsiDetailSheet(exception),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tanggal Eksepsi',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        tanggalEksepsiLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jumlah Hari',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        '$jumlahHari Hari',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (pengajuan != null)
                              Text(
                                'Tanggal Pengajuan: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(pengajuan)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            if (alasanPertama.isNotEmpty &&
                                alasanPertama != '-') ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Alasan',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                alasanPertama,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf,
                                      size: 18),
                                  label: const Text('Lihat PDF'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _previewExistingEksepsiPdf(exception),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  label: const Text('Hapus'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteEksepsi(exception),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  String _formatTanggalDdMmRange(Map<String, dynamic> eksepsi) {
    final rawList = eksepsi['eksepsi_tanggal'];
    final List<DateTime> dates = [];

    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          final raw = (item['tanggal_eksepsi'] ?? '').toString();
          final parsed = DateTime.tryParse(raw);
          if (parsed != null) dates.add(parsed);
        }
      }
    }

    dates.sort();
    if (dates.isEmpty) {
      return '-';
    }
    if (dates.length == 1) {
      return DateFormat('dd/MM', 'id_ID').format(dates.first);
    }
    return '${DateFormat('dd/MM', 'id_ID').format(dates.first)} - ${DateFormat('dd/MM', 'id_ID').format(dates.last)}';
  }

  int _countTanggalEksepsi(Map<String, dynamic> eksepsi) {
    final rawList = eksepsi['eksepsi_tanggal'];
    if (rawList is List) {
      return rawList.length;
    }
    return 0;
  }

  String _firstAlasanEksepsi(Map<String, dynamic> eksepsi) {
    final rawList = eksepsi['eksepsi_tanggal'];
    if (rawList is List && rawList.isNotEmpty) {
      final first = rawList.first;
      if (first is Map) {
        final alasan = (first['alasan_eksepsi'] ?? '').toString();
        if (alasan.isNotEmpty) return alasan;
      }
    }
    return '-';
  }

  void _showEksepsiDetailSheet(Map<String, dynamic> eksepsi) {
    final List items = (eksepsi['eksepsi_tanggal'] as List?) ?? const [];
    final name = (eksepsi['nama'] ?? 'Unknown').toString();
    if (items.isEmpty) {
      showTopToast('$name belum mengajukan cuti');
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final initialSize = items.length <= 2 ? 0.45 : 0.8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if ((eksepsi['jenis_eksepsi'] ?? '').toString().isNotEmpty)
                    Text(
                      'Jenis: ${eksepsi['jenis_eksepsi']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is! Map) return const SizedBox.shrink();
                        final rawDate =
                            (item['tanggal_eksepsi'] ?? '').toString();
                        final dt = DateTime.tryParse(rawDate);
                        final tanggalLabel = dt != null
                            ? DateFormat('dd/MM/yyyy', 'id_ID').format(dt)
                            : '-';
                        final alasan =
                            (item['alasan_eksepsi'] ?? '-').toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(tanggalLabel),
                            subtitle: Text('Alasan: $alasan'),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      final normalized =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      final existing = _selectedDates.cast<DateTime?>().firstWhere(
          (d) => d != null && isSameDay(d, normalized),
          orElse: () => null);
      if (existing != null) {
        _selectedDates.remove(existing);
        _focusedDay = focusedDay;
        return;
      }
      if (_selectedDates.length >= _maxEksepsiDaysForOnePagePdf) {
        showTopToast(
          'Tanggal eksepsi maksimal $_maxEksepsiDaysForOnePagePdf hari untuk 1 halaman PDF',
          background: Colors.orange,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        _focusedDay = focusedDay;
        return;
      }
      _selectedDates.add(normalized);
      _focusedDay = focusedDay;
    });
  }

  Future<void> _submitExceptionApplication() async {
    if (_selectedDates.isEmpty) {
      showTopToast(
        'Pilih minimal satu tanggal eksepsi',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      showTopToast(
        'Alasan eksepsi tidak boleh kosong',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    await _submitEksepsiToSupabase();
  }

  Future<void> _submitEksepsiToSupabase() async {
    dynamic eksepsiId;
    try {
      final loginController = Get.find<LoginController>();
      final currentUser = loginController.currentUser.value;
      if (currentUser == null) {
        showTopToast(
          'User tidak ditemukan',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final userId = currentUser['id'];
      final nowIso = DateTime.now().toIso8601String();
      final jenis = 'Jam Masuk & Jam Pulang';

      final eksepsiInsert = {
        'user_id': userId,
        'jenis_eksepsi': jenis,
        'tanggal_pengajuan': nowIso,
      };

      final insertedParent = await SupabaseService.instance.client
          .from('eksepsi')
          .insert(eksepsiInsert)
          .select('id')
          .single();

      eksepsiId = insertedParent['id'];
      if (eksepsiId == null) {
        showTopToast(
          'Gagal mendapatkan ID eksepsi',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final sortedDates = _selectedDates.toList()..sort();
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final alasan = _reasonController.text.trim();

      final List<Map<String, dynamic>> tanggalRows = [];
      for (int i = 0; i < sortedDates.length; i++) {
        final d = sortedDates[i];
        tanggalRows.add({
          'eksepsi_id': eksepsiId,
          'tanggal_eksepsi': dateFormatter.format(d),
          'urutan': i + 1,
          'alasan_eksepsi': alasan,
        });
      }

      if (tanggalRows.isNotEmpty) {
        await SupabaseService.instance.client
            .from('eksepsi_tanggal')
            .insert(tanggalRows);
      }

      showTopToast(
        'Pengajuan eksepsi berhasil dikirim',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );

      setState(() {
        _selectedDates.clear();
        _reasonController.clear();
      });

      _tabController.animateTo(1);
    } catch (e) {
      if (eksepsiId != null) {
        try {
          await SupabaseService.instance.client
              .from('eksepsi_tanggal')
              .delete()
              .eq('eksepsi_id', eksepsiId);
        } catch (_) {}

        try {
          await SupabaseService.instance.client
              .from('eksepsi')
              .delete()
              .eq('id', eksepsiId);
        } catch (_) {}
      }

      showTopToast(
        'Gagal mengajukan eksepsi: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
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

  void _previewExistingEksepsiPdf(Map<String, dynamic> eksepsi) async {
    final loginController = Get.find<LoginController>();
    final currentUser = loginController.currentUser.value;

    if (currentUser == null) {
      showTopToast(
        'User tidak ditemukan',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final freshUser =
        await _fetchUserById((currentUser['id'] ?? '').toString());
    final userForPdf = freshUser ?? currentUser;

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

    try {
      showTopToast(
        'Memuat PDF eksepsi...',
        background: Colors.blue,
        foreground: Colors.white,
        duration: const Duration(seconds: 2),
      );

      final detail = await _fetchEksepsiDetail(eksepsiId);
      final eksepsiData = <String, dynamic>{
        ...eksepsi,
        if (detail != null) ...detail,
      };

      final supervisorJenis =
          _getSupervisorJenisByUserStatus(userForPdf['status']?.toString());
      final supervisorData = await _fetchSupervisorByJenis(supervisorJenis);
      final managerData = await _fetchSupervisorByJenis('Manager_PDS');

      final pdfData = await PdfService.generateEksepsiPdf(
        eksepsiData: eksepsiData,
        userData: userForPdf,
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
          title: 'PDF Eksepsi - ${userForPdf['name'] ?? 'Unknown'}',
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

  Future<List<Map<String, dynamic>>> _fetchExceptionRequests(
      {int? year}) async {
    try {
      final LoginController loginController = Get.find<LoginController>();
      final currentUser = loginController.currentUser.value;

      if (currentUser == null) {
        return [];
      }

      final int targetYear = year ?? DateTime.now().year;
      final start = DateTime(targetYear, 1, 1);
      final end = DateTime(targetYear, 12, 31, 23, 59, 59);

      final response = await SupabaseService.instance.client
          .from('eksepsi')
          .select('''
            id, user_id, jenis_eksepsi, tanggal_pengajuan, created_at,
            users!inner(name),
            eksepsi_tanggal(urutan, tanggal_eksepsi, alasan_eksepsi)
          ''')
          .eq('user_id', currentUser['id'])
          .gte('tanggal_pengajuan', start.toIso8601String())
          .lte('tanggal_pengajuan', end.toIso8601String())
          .order('tanggal_pengajuan', ascending: false)
          .limit(20);

      // Transform the nested data
      return response
          .map((item) => {
                'id': item['id'],
                'user_id': item['user_id'],
                'jenis_eksepsi': item['jenis_eksepsi'],
                'tanggal_pengajuan': item['tanggal_pengajuan'],
                'created_at': item['created_at'],
                'nama': item['users']?['name'] ?? 'Unknown',
                'eksepsi_tanggal': item['eksepsi_tanggal'],
              })
          .toList();
    } catch (e) {
      throw 'Failed to fetch exception requests: $e';
    }
  }
}
