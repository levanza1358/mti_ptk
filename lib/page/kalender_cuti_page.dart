import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class KalenderCutiPage extends StatefulWidget {
  const KalenderCutiPage({super.key});

  @override
  State<KalenderCutiPage> createState() => _KalenderCutiPageState();
}

class _KalenderCutiPageState extends State<KalenderCutiPage> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Store leave dates with employee info
  Map<DateTime, List<Map<String, dynamic>>> _leaveEvents = {};
  List<Map<String, dynamic>> _selectedDayLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    try {
      final response = await SupabaseService.instance.client
          .from('cuti')
          .select('nama, list_tanggal_cuti, jenis_cuti, lama_cuti')
          .limit(100);

      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (final leave in response) {
        final dateString = leave['list_tanggal_cuti'];
        if (dateString != null && dateString.isNotEmpty) {
          // Parse dates from the list_tanggal_cuti string
          // This assumes the format is something like "01/01/2024, 02/01/2024, ..."
          final dates = _parseDateList(dateString);

          for (final date in dates) {
            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (!events.containsKey(normalizedDate)) {
              events[normalizedDate] = [];
            }
            events[normalizedDate]!.add({
              'nama': leave['nama'] ?? 'Unknown',
              'jenis_cuti': leave['jenis_cuti'] ?? 'Cuti',
              'lama_cuti': leave['lama_cuti'] ?? 1,
            });
          }
        }
      }

      setState(() {
        _leaveEvents = events;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data cuti: $e');
    }
  }

  List<DateTime> _parseDateList(String dateList) {
    final dates = <DateTime>[];
    try {
      // Split by comma and parse each date
      final dateStrings = dateList.split(',');
      for (final dateStr in dateStrings) {
        final trimmed = dateStr.trim();
        if (trimmed.isNotEmpty) {
          // Try different date formats
          DateTime? parsedDate;
          try {
            parsedDate = DateFormat('dd/MM/yyyy').parse(trimmed);
          } catch (_) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parse(trimmed);
            } catch (_) {
              // Skip invalid dates
              continue;
            }
          }
          dates.add(parsedDate);
        }
      }
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
    return dates;
  }

  List<Map<String, dynamic>> _getLeaveEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _leaveEvents[normalizedDay] ?? [];
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
        title: const Text('Kalender Cuti'),
      ),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TableCalendar(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                eventLoader: _getLeaveEventsForDay,
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
          ),

          // Selected Day Details
          if (_selectedDay != null && _selectedDayLeaves.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Cuti pada ${DateFormat('dd/MM/yyyy', 'id_ID').format(_selectedDay!)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _selectedDayLeaves.length,
                itemBuilder: (context, index) {
                  final leave = _selectedDayLeaves[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          leave['nama']?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(leave['nama'] ?? 'Unknown'),
                      subtitle: Text(
                        '${leave['jenis_cuti'] ?? 'Cuti'} - ${leave['lama_cuti'] ?? 1} hari',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          'Cuti',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (_selectedDay != null) ...[
            Expanded(
              child: Center(
                child: Text(
                  'Tidak ada cuti pada ${DateFormat('dd/MM/yyyy', 'id_ID').format(_selectedDay!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih tanggal untuk melihat detail cuti',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDayLeaves = _getLeaveEventsForDay(selectedDay);
    });
  }
}
