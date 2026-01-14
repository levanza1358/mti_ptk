import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controller/cuti_controller.dart';
import 'pdf_preview_page.dart';

class CutiPage extends StatefulWidget {
  const CutiPage({super.key});

  @override
  State<CutiPage> createState() => _CutiPageState();
}

class _CutiPageState extends State<CutiPage> with TickerProviderStateMixin {
  final CutiController cutiController = Get.put(CutiController());
  late TabController _tabController;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {};

  final TextEditingController _reasonController = TextEditingController();
  String _selectedLeaveType = 'Cuti Tahunan';

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
        title: const Text('Cuti'),
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
            'Pengajuan Cuti Baru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Sisa Cuti Info Card
          Card(
            color: Colors.blue.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sisa Cuti Tahunan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final remaining = cutiController.sisaCuti.value;
                          return Text(
                            '$remaining hari',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Leave Type Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Cuti',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLeaveType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: ['Cuti Tahunan', 'Cuti Alasan Penting']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value!;
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
                    'Pilih Tanggal Cuti',
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
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
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
          if (_selectedLeaveType == 'Cuti Tahunan')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alasan Cuti',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan alasan pengajuan cuti...',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alasan cuti tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanda Tangan Digital',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final hasSignature = cutiController.hasSignature.value;
                    final url = cutiController.signatureUrl.value;

                    if (!hasSignature || url.isEmpty) {
                      return const Text(
                        'Belum ada tanda tangan tersimpan.',
                        style: TextStyle(fontSize: 14),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanda tangan tersimpan:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: cutiController.showSignatureDialog,
                      icon: const Icon(Icons.border_color),
                      label: const Text('Buat / Ubah Tanda Tangan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitLeaveApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ajukan Cuti',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Year Navigation Header
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).cardColor,
          child: Obx(() {
            final currentYear = cutiController.selectedYear.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: cutiController.previousYear,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Tahun sebelumnya',
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentYear.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: cutiController.nextYear,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Tahun berikutnya',
                ),
              ],
            );
          }),
        ),

        // Leave History List
        Expanded(
          child: Obx(() {
            if (cutiController.isLoadingHistory.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredLeaves = cutiController.filteredCutiHistory;
            final currentYear = cutiController.selectedYear.value;

            if (filteredLeaves.isEmpty) {
              return Center(
                child: Text(
                  'Tidak ada data cuti untuk tahun $currentYear',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredLeaves.length,
              itemBuilder: (context, index) {
                final leave = filteredLeaves[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                leave['nama'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _previewExistingCutiPdf(leave),
                                  tooltip: 'Preview PDF',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    await cutiController
                                        .showDeleteConfirmation(leave);
                                    setState(() {});
                                  },
                                  tooltip: 'Hapus Cuti',
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Text(
                                    leave['jenis_cuti'] ?? 'Cuti',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lama Cuti: ${leave['lama_cuti'] ?? 0} hari',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Sisa Cuti: ${leave['sisa_cuti'] ?? 0} hari',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (leave['tanggal_pengajuan'] != null) ...[
                          Text(
                            'Tanggal Pengajuan: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(leave['tanggal_pengajuan']))}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                        if (leave['alasan_cuti'] != null &&
                            leave['alasan_cuti'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Alasan: ${leave['alasan_cuti']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
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

  Future<void> _submitLeaveApplication() async {
    if (_selectedDates.isEmpty) {
      Get.snackbar('Error', 'Pilih minimal satu tanggal cuti');
      return;
    }

    if (_selectedLeaveType == 'Cuti Tahunan' &&
        _reasonController.text.isEmpty) {
      Get.snackbar('Error', 'Alasan cuti tidak boleh kosong');
      return;
    }

    cutiController.selectedDates
      ..clear()
      ..addAll(_selectedDates);
    cutiController.selectedLeaveType.value = _selectedLeaveType;
    cutiController.alasanController.text = _reasonController.text;

    await cutiController.submitCutiApplication();

    setState(() {
      _selectedDates.clear();
      _reasonController.clear();
    });
  }

  void _previewExistingCutiPdf(Map<String, dynamic> cutiData) async {
    try {
      // Get PDF controller and generate PDF from existing cuti data
      final pdfController = Get.put(PdfCutiController());

      // Show loading
      Get.snackbar('Loading', 'Memuat PDF cuti...',
          duration: const Duration(seconds: 2));

      final pdfData = await pdfController.generateCutiPdf(cutiData);

      // Check if PDF data is valid
      if (pdfData.isEmpty) {
        Get.snackbar('Error', 'PDF kosong, data cuti tidak valid');
        return;
      }

      // Navigate to PDF Preview Page
      Get.to(() => PdfPreviewPage(
            title: 'PDF Cuti - ${cutiData['nama'] ?? 'Unknown'}',
            pdfGenerator: () async => pdfData,
          ));
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat PDF cuti: $e');
    }
  }
}
