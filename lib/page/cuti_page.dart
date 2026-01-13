import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/supabase_service.dart';
import '../controller/login_controller.dart';

class CutiPage extends StatefulWidget {
  const CutiPage({super.key});

  @override
  State<CutiPage> createState() => _CutiPageState();
}

class _CutiPageState extends State<CutiPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {};

  final TextEditingController _reasonController = TextEditingController();
  String _selectedLeaveType = 'Cuti Tahunan';

  // Riwayat navigation
  int _currentYear = DateTime.now().year;

  // Sisa cuti
  int _sisaCuti = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserLeaveBalance();
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
                        Text(
                          '$_sisaCuti hari',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
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

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitLeaveApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentYear--;
                  });
                },
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
                  _currentYear.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentYear++;
                  });
                },
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Tahun berikutnya',
              ),
            ],
          ),
        ),

        // Leave History List
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchLeaveRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final allLeaves = snapshot.data ?? [];

              // Filter by selected year
              final filteredLeaves = allLeaves.where((leave) {
                if (leave['tanggal_pengajuan'] == null) return false;
                try {
                  final date = DateTime.parse(leave['tanggal_pengajuan']);
                  return date.year == _currentYear;
                } catch (e) {
                  return false;
                }
              }).toList();

              if (filteredLeaves.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada data cuti untuk tahun $_currentYear',
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
            },
          ),
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

  void _submitLeaveApplication() {
    if (_selectedDates.isEmpty) {
      Get.snackbar('Error', 'Pilih minimal satu tanggal cuti');
      return;
    }

    if (_selectedLeaveType == 'Cuti Tahunan' &&
        _reasonController.text.isEmpty) {
      Get.snackbar('Error', 'Alasan cuti tidak boleh kosong');
      return;
    }

    // Here you would submit to Supabase
    Get.snackbar('Success', 'Pengajuan cuti berhasil dikirim');
    setState(() {
      _selectedDates.clear();
      _reasonController.clear();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchLeaveRequests() async {
    try {
      final LoginController loginController = Get.find<LoginController>();
      final currentUser = loginController.currentUser.value;

      if (currentUser == null) {
        return [];
      }

      if (currentUser['id'] == null) {
        return [];
      }

      // First, let's check if there are any records at all
      await SupabaseService.instance.client
          .from('cuti')
          .select('count')
          .limit(1);

      // Check records for this user
      final userRecords = await SupabaseService.instance.client
          .from('cuti')
          .select('id, nama, users_id')
          .eq('users_id', currentUser['id']);
      if (userRecords.isNotEmpty) {}

      final response = await SupabaseService.instance.client
          .from('cuti')
          .select(
              'nama, alasan_cuti, lama_cuti, tanggal_pengajuan, users_id, jenis_cuti, sisa_cuti')
          .eq('users_id', currentUser['id'])
          .order('tanggal_pengajuan', ascending: false)
          .limit(100);

      if (response.isNotEmpty) {}

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to fetch leave requests: $e';
    }
  }

  Future<void> _loadUserLeaveBalance() async {
    try {
      final LoginController loginController = Get.find<LoginController>();
      final currentUser = loginController.currentUser.value;

      if (currentUser == null || currentUser['id'] == null) {
        return;
      }

      final response = await SupabaseService.instance.client
          .from('users')
          .select('sisa_cuti')
          .eq('id', currentUser['id'])
          .single();

      if (response['sisa_cuti'] != null) {
        setState(() {
          _sisaCuti = response['sisa_cuti'] as int;
        });
      } else {}
    } catch (e) {
      // Keep default value of 0
    }
  }
}
