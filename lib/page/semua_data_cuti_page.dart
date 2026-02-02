// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../config/page_colors.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class SemuaDataCutiPage extends StatefulWidget {
  const SemuaDataCutiPage({super.key});

  @override
  State<SemuaDataCutiPage> createState() => _SemuaDataCutiPageState();
}

class _SemuaDataCutiPageState extends State<SemuaDataCutiPage>
    with TickerProviderStateMixin {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late TabController _tabController;

  Map<DateTime, List<Map<String, dynamic>>> _leaveEvents = {};
  List<Map<String, dynamic>> _selectedDayLeaves = [];

  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _cutiHistory = [];
  late DateTime _historyMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDay!;
    _historyMonth = DateTime(now.year, now.month, 1);
    _loadLeaveData();
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveData() async {
    try {
      dynamic response;
      try {
        response = await SupabaseService.instance.client
            .from('cuti')
            .select(
                'id, users_id, nama, list_tanggal_cuti, jenis_cuti, lama_cuti, tanggal_pengajuan, alasan_cuti, sisa_cuti')
            .limit(200);
      } catch (_) {
        response = await SupabaseService.instance.client
            .from('cuti')
            .select('users_id, nama, list_tanggal_cuti, jenis_cuti, lama_cuti')
            .limit(200);
      }

      final Map<DateTime, List<Map<String, dynamic>>> events = {};
      final Set<String> userIds = {};

      for (final leave in response) {
        final userId = (leave['users_id'] ?? '').toString();
        if (userId.isNotEmpty) {
          userIds.add(userId);
        }
      }

      final Map<String, Map<String, dynamic>> usersById = {};
      if (userIds.isNotEmpty) {
        dynamic usersResponse;
        try {
          usersResponse = await SupabaseService.instance.client
              .from('users')
              .select('id, name, nrp, "group", jabatan, sisa_cuti')
              .inFilter('id', userIds.toList());
        } catch (_) {
          try {
            usersResponse = await SupabaseService.instance.client
                .from('users')
                .select('id, name, nrp, "group"')
                .inFilter('id', userIds.toList());
          } catch (_) {
            usersResponse = null;
          }
        }

        if (usersResponse != null) {
          for (final u in usersResponse) {
            final id = (u['id'] ?? '').toString();
            if (id.isNotEmpty) {
              usersById[id] = Map<String, dynamic>.from(u);
            }
          }
        }
      }

      for (final leave in response) {
        final userId = (leave['users_id'] ?? '').toString();
        final user = usersById[userId];
        final nama = (leave['nama'] ?? user?['name'] ?? 'Unknown').toString();
        final nrp = (user?['nrp'] ?? '-').toString();
        final group = (user?['group'] ?? '-').toString();
        final jabatan = (user?['jabatan'] ?? '-').toString();
        final sisaCutiResolved =
            (leave['sisa_cuti'] ?? user?['sisa_cuti'] ?? '-');

        final dateString = leave['list_tanggal_cuti'];
        if (dateString != null && dateString.isNotEmpty) {
          final dates = _parseDateList(dateString);

          for (final date in dates) {
            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (!events.containsKey(normalizedDate)) {
              events[normalizedDate] = [];
            }
            events[normalizedDate]!.add({
              'id': leave['id'],
              'users_id': userId,
              'nama': nama,
              'nrp': nrp,
              'group': group,
              'jabatan': jabatan,
              'nama_resolved': nama,
              'nrp_resolved': nrp,
              'group_resolved': group,
              'jabatan_resolved': jabatan,
              'jenis_cuti': leave['jenis_cuti'] ?? 'Cuti',
              'lama_cuti': leave['lama_cuti'] ?? 1,
              'list_tanggal_cuti': dateString,
              'tanggal_pengajuan': leave['tanggal_pengajuan'],
              'alasan_cuti': leave['alasan_cuti'],
              'sisa_cuti_resolved': sisaCutiResolved,
              'tanggal_cuti_dates': dates,
            });
          }
        }
      }

      setState(() {
        _leaveEvents = events;
        if (_selectedDay != null) {
          _selectedDayLeaves = _getLeaveEventsForDay(_selectedDay!);
        }
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat data cuti: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      dynamic response;
      try {
        response = await SupabaseService.instance.client
            .from('cuti')
            .select(
                'id, users_id, nama, jenis_cuti, lama_cuti, list_tanggal_cuti, tanggal_pengajuan, alasan_cuti, sisa_cuti')
            .order('tanggal_pengajuan', ascending: false)
            .limit(300);
      } catch (_) {
        response = await SupabaseService.instance.client
            .from('cuti')
            .select(
                'id, users_id, nama, jenis_cuti, lama_cuti, list_tanggal_cuti, tanggal_pengajuan')
            .order('tanggal_pengajuan', ascending: false)
            .limit(300);
      }

      final Set<String> userIds = {};
      for (final item in response) {
        final userId = (item['users_id'] ?? '').toString();
        if (userId.isNotEmpty) {
          userIds.add(userId);
        }
      }

      final Map<String, Map<String, dynamic>> usersById = {};
      if (userIds.isNotEmpty) {
        dynamic usersResponse;
        try {
          usersResponse = await SupabaseService.instance.client
              .from('users')
              .select('id, name, nrp, "group", jabatan, sisa_cuti')
              .inFilter('id', userIds.toList());
        } catch (_) {
          try {
            usersResponse = await SupabaseService.instance.client
                .from('users')
                .select('id, name, nrp, "group"')
                .inFilter('id', userIds.toList());
          } catch (_) {
            usersResponse = null;
          }
        }

        if (usersResponse != null) {
          for (final u in usersResponse) {
            final id = (u['id'] ?? '').toString();
            if (id.isNotEmpty) {
              usersById[id] = Map<String, dynamic>.from(u);
            }
          }
        }
      }

      final List<Map<String, dynamic>> mapped = [];
      for (final item in response) {
        final m = Map<String, dynamic>.from(item);
        final userId = (m['users_id'] ?? '').toString();
        final user = usersById[userId];
        final nama = (m['nama'] ?? user?['name'] ?? 'Unknown').toString();
        final nrp = (user?['nrp'] ?? '-').toString();
        final group = (user?['group'] ?? '-').toString();
        final jabatan = (user?['jabatan'] ?? '-').toString();
        final sisaCutiResolved = (m['sisa_cuti'] ?? user?['sisa_cuti'] ?? '-');

        final tanggalPengajuanRaw = (m['tanggal_pengajuan'] ?? '').toString();
        final tanggalPengajuan = DateTime.tryParse(tanggalPengajuanRaw);

        final listTanggal = (m['list_tanggal_cuti'] ?? '').toString();
        final dates = listTanggal.isNotEmpty ? _parseDateList(listTanggal) : [];
        dates.sort();

        String tanggalCutiLabel = '-';
        if (dates.isNotEmpty) {
          if (dates.length == 1) {
            tanggalCutiLabel =
                DateFormat('dd/MM/yyyy', 'id_ID').format(dates[0]);
          } else {
            tanggalCutiLabel =
                '${DateFormat('dd/MM/yyyy', 'id_ID').format(dates.first)} - ${DateFormat('dd/MM/yyyy', 'id_ID').format(dates.last)}';
          }
        }

        mapped.add({
          ...m,
          'nama_resolved': nama,
          'nrp_resolved': nrp,
          'group_resolved': group,
          'jabatan_resolved': jabatan,
          'sisa_cuti_resolved': sisaCutiResolved,
          'tanggal_pengajuan_dt': tanggalPengajuan,
          'tanggal_cuti_label': tanggalCutiLabel,
          'tanggal_cuti_dates': dates,
        });
      }

      setState(() {
        _cutiHistory = mapped;
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat riwayat cuti: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  List<DateTime> _parseDateList(String dateList) {
    final dates = <DateTime>[];
    try {
      final dateStrings = dateList.split(',');
      for (final dateStr in dateStrings) {
        final trimmed = dateStr.trim();
        if (trimmed.isNotEmpty) {
          DateTime? parsedDate;
          parsedDate = DateTime.tryParse(trimmed);
          if (parsedDate != null) {
            dates.add(parsedDate);
            continue;
          }
          try {
            parsedDate = DateFormat('dd/MM/yyyy').parse(trimmed);
          } catch (_) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parse(trimmed);
            } catch (_) {
              continue;
            }
          }
          dates.add(parsedDate);
        }
      }
    } catch (e) {
      return [];
    }
    return dates;
  }

  List<Map<String, dynamic>> _getLeaveEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _leaveEvents[normalizedDay] ?? [];
  }

  DateTime _addMonths(DateTime base, int delta) {
    return DateTime(base.year, base.month + delta, 1);
  }

  int _monthIndex(DateTime d) => d.year * 12 + d.month;

  Widget _buildCalendarTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                Expanded(
                  child: Text(
                    _selectedDay != null
                        ? DateFormat('dd MMM yyyy', 'id_ID')
                            .format(_selectedDay!)
                        : 'Belum memilih tanggal',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_selectedDayLeaves.length} cuti',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                final badgeColor = _jenisCutiBadgeColor(leave['jenis_cuti']);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                      onTap: () => _showCutiDetailSheet(leave),
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
                                border: Border.all(color: badgeColor, width: 2),
                              ),
                              child: CircleAvatar(
                                backgroundColor: badgeColor,
                                child: Text(
                                  (leave['nama'] ?? 'U')[0]
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (leave['nama'] ?? 'Unknown').toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NRP: ${leave['nrp'] ?? '-'} • Group: ${leave['group'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              badgeColor.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(color: badgeColor),
                                        ),
                                        child: Text(
                                          _jenisCutiBadgeText(
                                              leave['jenis_cuti']),
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(leave['lama_cuti'] ?? 1)} hari',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: badgeColor),
                              ),
                              child:
                                  Icon(Icons.chevron_right, color: badgeColor),
                            ),
                          ],
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
                    color: Colors.grey.withOpacity(0.5),
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
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cutiHistory.isEmpty) {
      return const Center(child: Text('Belum ada pengajuan cuti'));
    }

    final months = _cutiHistory
        .map((e) => e['tanggal_pengajuan_dt'])
        .whereType<DateTime>()
        .map(_monthIndex)
        .toSet()
        .toList()
      ..sort();

    final hasAnyMonth = months.isNotEmpty;
    final currentMonthIndex = _monthIndex(_historyMonth);
    final minMonthIndex = hasAnyMonth ? months.first : currentMonthIndex;
    final maxMonthIndex = hasAnyMonth ? months.last : currentMonthIndex;

    final canPrev = currentMonthIndex > minMonthIndex;
    final canNext = currentMonthIndex < maxMonthIndex;

    final monthItems = _cutiHistory.where((item) {
      final dt = item['tanggal_pengajuan_dt'];
      if (dt is! DateTime) return false;
      return dt.year == _historyMonth.year && dt.month == _historyMonth.month;
    }).toList()
      ..sort((a, b) {
        final adt = a['tanggal_pengajuan_dt'];
        final bdt = b['tanggal_pengajuan_dt'];
        if (adt is DateTime && bdt is DateTime) {
          return bdt.compareTo(adt);
        }
        return 0;
      });

    final monthTitle =
        DateFormat('MMMM yyyy', 'id_ID').format(_historyMonth).toString();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: canPrev
                    ? () {
                        setState(() {
                          _historyMonth = _addMonths(_historyMonth, -1);
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: canNext
                    ? () {
                        setState(() {
                          _historyMonth = _addMonths(_historyMonth, 1);
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: monthItems.isEmpty
              ? const Center(child: Text('Tidak ada pengajuan di bulan ini'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: monthItems.length,
                  itemBuilder: (context, index) {
                    final item = monthItems[index];
                    final nama =
                        (item['nama_resolved'] ?? 'Unknown').toString();
                    final nrp = (item['nrp_resolved'] ?? '-').toString();
                    final group = (item['group_resolved'] ?? '-').toString();
                    final jenis = (item['jenis_cuti'] ?? 'Cuti').toString();
                    final lama = (item['lama_cuti'] ?? 0).toString();
                    final tanggalCuti =
                        (item['tanggal_cuti_label'] ?? '-').toString();
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final badgeColor = _jenisCutiBadgeColor(jenis);
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
                          onTap: () => _showCutiDetailSheet(item),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: badgeColor, width: 2),
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
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              nama,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            tanggalCuti,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'NRP: $nrp • Group: $group',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(
                                                  alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border:
                                                  Border.all(color: badgeColor),
                                            ),
                                            child: Text(
                                              _jenisCutiBadgeText(jenis),
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$lama hari',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(32),
                                    onTap: () => _deleteCuti(item),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _deleteCuti(Map<String, dynamic> cutiData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cuti'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus data cuti ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final cutiId = cutiData['id'];
      final userId = cutiData['users_id'];
      final jenisCuti = (cutiData['jenis_cuti'] ?? '').toString();
      final listTanggal = (cutiData['list_tanggal_cuti'] ?? '').toString();
      final dates = listTanggal.isNotEmpty ? listTanggal.split(',') : [];
      final daysToRestore = dates.length;

      // 1. Delete the cuti record
      await SupabaseService.instance.client
          .from('cuti')
          .delete()
          .eq('id', cutiId);

      // 2. Only restore leave balance for annual leave
      // Check if it is annual leave (case insensitive check just to be safe, but typically it is uppercase)
      if (jenisCuti.toUpperCase().contains('TAHUN') && daysToRestore > 0) {
        // Get current user's leave balance
        final userResult = await SupabaseService.instance.client
            .from('users')
            .select('sisa_cuti')
            .eq('id', userId)
            .single();

        final currentBalance = userResult['sisa_cuti'] ?? 0;
        final newBalance = currentBalance + daysToRestore;

        // Update user's leave balance
        await SupabaseService.instance.client
            .from('users')
            .update({'sisa_cuti': newBalance}).eq('id', userId);
      }

      // 3. Refresh data
      _loadLeaveData();
      _loadHistoryData();

      // Navigator.pop(context); // REMOVED: No longer needed as we are not in a detail sheet

      showTopToast(
        'Data cuti berhasil dihapus${jenisCuti.toUpperCase().contains('TAHUN') ? ' dan kuota dikembalikan' : ''}',
        background: Colors.green,
        foreground: Colors.white,
      );
    } catch (e) {
      showTopToast(
        'Gagal menghapus data cuti: $e',
        background: Colors.red,
        foreground: Colors.white,
      );
    }
  }

  void _showCutiDetailSheet(Map<String, dynamic> item) {
    final nama = (item['nama_resolved'] ?? 'Unknown').toString();
    final group = (item['group_resolved'] ?? '-').toString();
    final jabatan = (item['jabatan_resolved'] ?? '-').toString();
    final lama = (item['lama_cuti'] ?? 0).toString();
    final idPengajuan = (item['id'] ?? '-').toString();
    final sisaCuti = (item['sisa_cuti_resolved'] ?? '-').toString();
    final alasan = (item['alasan_cuti'] ?? '-').toString().trim().isEmpty
        ? '-'
        : (item['alasan_cuti'] ?? '-').toString();
    final nrp = (item['nrp_resolved'] ?? '-').toString();

    final List<DateTime> tanggalCutiDates =
        (item['tanggal_cuti_dates'] is List<DateTime>)
            ? List<DateTime>.from(item['tanggal_cuti_dates'] as List)
            : _parseDateList((item['list_tanggal_cuti'] ?? '').toString());

    tanggalCutiDates.sort();

    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
                  const SizedBox(height: 16),
                  Text(
                    nama,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$group - $jabatan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$lama hari',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Nama Pengaju',
                    value: nama,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    context: context,
                    icon: Icons.badge_outlined,
                    label: 'NRP',
                    value: nrp,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    context: context,
                    icon: Icons.confirmation_number_outlined,
                    label: 'ID Pengajuan',
                    value: idPengajuan,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    context: context,
                    icon: Icons.event_available_outlined,
                    label: 'Sisa cuti tersisa',
                    value: sisaCuti == '-' ? '-' : '$sisaCuti hari',
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Daftar Tanggal Cuti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tanggalCutiDates.map((d) {
                      final label =
                          DateFormat('dd MMM yyyy', 'id_ID').format(d);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  if (alasan != '-') ...[
                    const Text(
                      'Alasan Pengajuan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(alasan),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _jenisCutiBadgeColor(Object? raw) {
    final v = (raw ?? '').toString().toUpperCase();
    if (v.contains('ALASAN') || v.contains('PENTING')) {
      return Colors.red;
    }
    if (v.contains('TAHUN')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  String _jenisCutiBadgeText(Object? raw) {
    final v = (raw ?? '').toString().toUpperCase();
    if (v.contains('ALASAN') || v.contains('PENTING')) {
      return 'CUTI ALASAN PENTING';
    }
    if (v.contains('TAHUN')) {
      return 'CUTI TAHUNAN';
    }
    return 'CUTI';
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
        title: const Text('Semua Data Cuti'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? PageColors.cutiDark : PageColors.cutiLight,
                (isDark ? PageColors.cutiDark : PageColors.cutiLight)
                    .withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
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
                Tab(text: 'Kalender'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildHistoryTab(),
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
