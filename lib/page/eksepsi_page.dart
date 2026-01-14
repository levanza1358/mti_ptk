import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import '../controller/login_controller.dart';

class EksepsiPage extends StatefulWidget {
  const EksepsiPage({super.key});

  @override
  State<EksepsiPage> createState() => _EksepsiPageState();
}

class _EksepsiPageState extends State<EksepsiPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {};

  final TextEditingController _reasonController = TextEditingController();
  String _selectedExceptionType = 'Eksepsi Datang Terlambat';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: const Text('Eksepsi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pengajuan'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildApplicationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengajuan Eksepsi Baru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Exception Type Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Eksepsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExceptionType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      'Eksepsi Datang Terlambat',
                      'Eksepsi Pulang Awal',
                      'Eksepsi Tidak Masuk',
                      'Eksepsi Lainnya'
                    ].map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExceptionType = value!;
                        _selectedDates.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                  TableCalendar(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => _selectedDates.contains(day),
                    onDaySelected: _onDaySelected,
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
                          label: Text('${date.day}/${date.month}/${date.year}'),
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
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
                child: OutlinedButton.icon(
                  onPressed: _previewPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Preview PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchExceptionRequests(),
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
            return Card(
              child: ListTile(
                title: Text('Eksepsi ${exception['nama'] ?? 'Unknown'}'),
                subtitle: Text('Jenis: ${exception['jenis_eksepsi'] ?? 'N/A'}'),
                trailing: Text(
                  DateFormat('dd/MM/yyyy', 'id_ID').format(
                    DateTime.parse(exception['tanggal_pengajuan'] ?? DateTime.now().toString())
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_selectedDates.contains(selectedDay)) {
        _selectedDates.remove(selectedDay);
      } else {
        _selectedDates.add(selectedDay);
      }
    });
  }

  void _previewPdf() async {
    if (_selectedDates.isEmpty) {
      Get.snackbar('Error', 'Pilih minimal satu tanggal eksepsi terlebih dahulu');
      return;
    }

    final loginController = Get.find<LoginController>();
    final currentUser = loginController.currentUser.value;

    if (currentUser == null) {
      Get.snackbar('Error', 'User tidak ditemukan');
      return;
    }

    try {
      final pdfData = await PdfService.generateExceptionPdf(
        employeeName: currentUser['name'] ?? 'Unknown',
        exceptionType: _selectedExceptionType,
        selectedDates: _selectedDates.toList(),
        reason: _reasonController.text,
        employeeId: currentUser['nrp'] ?? 'N/A',
        position: currentUser['jabatan'] ?? 'Staff',
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'Formulir Pengajuan Eksepsi',
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuat preview PDF: $e');
    }
  }

  void _submitExceptionApplication() {
    if (_selectedDates.isEmpty) {
      Get.snackbar('Error', 'Pilih minimal satu tanggal eksepsi');
      return;
    }

    if (_reasonController.text.isEmpty) {
      Get.snackbar('Error', 'Alasan eksepsi tidak boleh kosong');
      return;
    }

    // Here you would submit to Supabase
    Get.snackbar('Success', 'Pengajuan eksepsi berhasil dikirim');
    setState(() {
      _selectedDates.clear();
      _reasonController.clear();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchExceptionRequests() async {
    try {
      final LoginController loginController = Get.find<LoginController>();
      final currentUser = loginController.currentUser.value;

      if (currentUser == null) {
        return [];
      }

      final response = await SupabaseService.instance.client
          .from('eksepsi')
          .select('''
            id, user_id, jenis_eksepsi, tanggal_pengajuan, created_at,
            users!inner(name)
          ''')
          .eq('user_id', currentUser['id'])
          .order('tanggal_pengajuan', ascending: false)
          .limit(20);

      // Transform the nested data
      return response.map((item) => {
        'id': item['id'],
        'user_id': item['user_id'],
        'jenis_eksepsi': item['jenis_eksepsi'],
        'tanggal_pengajuan': item['tanggal_pengajuan'],
        'created_at': item['created_at'],
        'nama': item['users']?['name'] ?? 'Unknown',
      }).toList();
    } catch (e) {
      throw 'Failed to fetch exception requests: $e';
    }
  }
}
