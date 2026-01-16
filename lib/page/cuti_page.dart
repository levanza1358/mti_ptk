import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controller/cuti_controller.dart';
import 'pdf_preview_page.dart';
import '../utils/top_toast.dart';
import '../services/supabase_service.dart';

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

  final TextEditingController _reasonController = TextEditingController();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title:
            const Text('Cuti', style: TextStyle(fontWeight: FontWeight.bold)),
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
                color: Theme.of(context).colorScheme.secondaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Theme.of(context).colorScheme.onSecondaryContainer,
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
          _buildHistoryTab(context),
        ],
      ),
    );
  }

  Widget _buildApplicationTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Sisa Cuti Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue.shade900, Colors.blue.shade700]
                    : [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final name = cutiController.currentUser.value?['name']
                                ?.toString() ??
                            '-';
                        return Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Obx(() {
                        final nrp = cutiController.currentUser.value?['nrp']
                                ?.toString() ??
                            '-';
                        return Text(
                          nrp,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Obx(() {
                        final remaining = cutiController.sisaCuti.value;
                        return Text(
                          'Sisa Cuti Tahunan: $remaining Hari',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Leave Type Selection
          _buildSectionTitle(context, 'Detail Pengajuan'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Cuti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final selectedType = cutiController.selectedLeaveType.value;
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: Theme.of(context).cardColor,
                    initialValue: selectedType,
                    items: ['Cuti Tahunan', 'Cuti Alasan Penting']
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      cutiController.selectedLeaveType.value = value;
                      if (value != 'Cuti Alasan Penting') {
                        cutiController.selectedReasonFromDb.value = '';
                      }
                      cutiController.clearSelectedDates();
                    },
                  );
                }),
                const SizedBox(height: 16),
                Obx(() {
                  final selectedType = cutiController.selectedLeaveType.value;

                  if (selectedType == 'Cuti Tahunan') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alasan Cuti',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[800] : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Jelaskan alasan pengajuan cuti...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alasan cuti tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ],
                    );
                  }

                  if (selectedType == 'Cuti Alasan Penting') {
                    final reasons =
                        cutiController.importantLeaveMaxDays.keys.toList();
                    final selected = cutiController.selectedReasonFromDb.value;
                    final selectedValue = selected.isEmpty ? null : selected;
                    final maxDays = selectedValue != null
                        ? cutiController.importantLeaveMaxDays[selectedValue]
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Alasan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(selectedValue ?? ''),
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[800] : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Pilih alasan cuti...',
                          ),
                          dropdownColor: Theme.of(context).cardColor,
                          initialValue: selectedValue,
                          items: reasons.map((reason) {
                            final max =
                                cutiController.importantLeaveMaxDays[reason];
                            final isHaji = reason == 'Ibadah Haji';
                            final label = isHaji
                                ? '$reason (Maks. 45 hari)'
                                : '$reason (Maks. ${max ?? '-'} hari)';
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            cutiController.selectedReasonFromDb.value =
                                value ?? '';
                            cutiController.clearSelectedDates();
                          },
                        ),
                        if (maxDays != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.blue[300]),
                              const SizedBox(width: 4),
                              Text(
                                selectedValue == 'Ibadah Haji'
                                    ? 'Kalender maksimal $maxDays hari'
                                    : 'Maksimal $maxDays hari',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[300],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Calendar
          _buildSectionTitle(context, 'Pilih Tanggal'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final selectedDatesSnapshot =
                      List<DateTime>.from(cutiController.selectedDates);
                  return TableCalendar(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) =>
                        selectedDatesSnapshot.any((d) => isSameDay(d, day)),
                    onDaySelected: (selectedDay, focusedDay) {
                      cutiController.onDaySelected(selectedDay, focusedDay);
                      setState(() {});
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Obx(() {
                  final selectedDates = cutiController.selectedDates;
                  if (selectedDates.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada tanggal dipilih',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Dipilih (${selectedDates.length} Hari):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedDates.map((date) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('dd/MM').format(date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    cutiController.selectedDates.remove(date);
                                  },
                                  child: Icon(Icons.close,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Tanda Tangan Digital'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Obx(() {
                  final hasSignature = cutiController.hasSignature.value;
                  final url = cutiController.signatureUrl.value;

                  if (!hasSignature || url.isEmpty) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.draw, color: Colors.grey, size: 32),
                          const SizedBox(height: 8),
                          Text('Belum ada tanda tangan',
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.grey[400] : Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tanda Tangan Terverifikasi',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: cutiController.showSignatureDialog,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Buat / Ubah Tanda Tangan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitLeaveApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ajukan Permohonan Cuti',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Year Navigation Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Obx(() {
            final currentYear = cutiController.selectedYear.value;
            return Container(
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
                    onPressed: cutiController.previousYear,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Tahun sebelumnya',
                  ),
                  Expanded(
                    child: Text(
                      'TAHUN $currentYear',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: cutiController.nextYear,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Tahun berikutnya',
                  ),
                ],
              ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada riwayat cuti\ndi tahun $currentYear',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: filteredLeaves.length,
              itemBuilder: (context, index) {
                final leave = filteredLeaves[index];
                final date =
                    DateTime.tryParse(leave['tanggal_pengajuan'] ?? '') ??
                        DateTime.now();
                final formattedDate = DateFormat('dd MMM yyyy').format(date);
                final lamaCuti = leave['lama_cuti'] ?? 0;
                final jenisCuti = leave['jenis_cuti'] ?? '-';
                final isLocked = (leave['kunci_cuti'] ?? false) == true;
                final lockColor = isLocked ? Colors.red : Colors.green;
                final lockIcon = isLocked ? Icons.lock : Icons.lock_open;
                final lockLabel = isLocked ? 'Terkunci' : 'Terbuka';

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        jenisCuti,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: lockColor.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(color: lockColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            lockIcon,
                                            size: 14,
                                            color: lockColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lockLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: lockColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.date_range,
                                      color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Lama Cuti',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        '$lamaCuti Hari',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                                      _handleViewPdfAndLockIfNeeded(leave),
                                ),
                                if (!isLocked) ...[
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Hapus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    onPressed: () async {
                                      await cutiController
                                          .showDeleteConfirmation(leave);
                                    },
                                  ),
                                ],
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
          }),
        ),
      ],
    );
  }

  void _submitLeaveApplication() async {
    // Collect the text from the controller since it's not observable
    if (cutiController.selectedLeaveType.value == 'Cuti Tahunan') {
      cutiController.alasanController.text = _reasonController.text;
    }
    final success = await cutiController.submitCutiApplication();
    if (success) {
      _reasonController.clear();
      _tabController.animateTo(1);
    }
  }

  Future<void> _handleViewPdfAndLockIfNeeded(
      Map<String, dynamic> leaveData) async {
    final isLocked = (leaveData['kunci_cuti'] ?? false) == true;

    if (!isLocked) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Generate PDF Cuti'),
            content: const Text(
              'Apakah Anda ingin lanjut generate PDF cuti?\n\n'
              'Setelah PDF dibuat, pengajuan cuti ini akan dikunci dan tidak dapat dihapus.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Lanjut'),
              ),
            ],
          );
        },
      );

      if (shouldProceed != true) {
        return;
      }

      try {
        final cutiId = leaveData['id'];
        if (cutiId != null) {
          await SupabaseService.instance.client
              .from('cuti')
              .update({'kunci_cuti': true}).eq('id', cutiId);

          await cutiController.loadCutiHistory();

          showTopToast(
            'Cuti berhasil dikunci. Data tidak dapat dihapus.',
            background: Colors.orange.withValues(alpha: 0.9),
            foreground: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        showTopToast(
          'Gagal mengunci cuti: $e',
          background: Colors.red.withValues(alpha: 0.9),
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    _previewExistingCutiPdf(leaveData);
  }

  void _previewExistingCutiPdf(Map<String, dynamic> leaveData) {
    final user = cutiController.currentUser.value;
    if (user == null) {
      showTopToast(
        'Data user tidak ditemukan',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final datesString = leaveData['list_tanggal_cuti'] as String? ?? '';
    final datesList = datesString.split(',');
    final dates = datesList.map((d) {
      try {
        return DateTime.parse(d);
      } catch (e) {
        return DateTime.now();
      }
    }).toList();
    dates.sort();

    // Mapping data for PDF
    final Map<String, dynamic> pdfData = {
      'nama': leaveData['nama'] ?? user['name'],
      'jabatan': user['jabatan'] ?? '-',
      'nrp': user['nrp'] ?? '-',
      'unit_kerja': user['unit_kerja'] ?? 'Pontianak',
      'jenis_cuti':
          (leaveData['jenis_cuti'] ?? 'CUTI TAHUNAN').toString().toUpperCase(),
      'alasan_cuti': leaveData['alasan_cuti'] ?? '-',
      'lama_cuti': leaveData['lama_cuti'] ?? 0,
      'list_tanggal_cuti': datesString,
      'tanggal_pengajuan': (() {
        final raw = (leaveData['tanggal_pengajuan'] ?? '').toString();
        if (raw.isNotEmpty) return raw;
        return DateTime.now().toIso8601String();
      })(),
      'alamat_cuti': '-', // Not in current form
      'telepon': user['telepon'] ?? '-',
      'url_ttd': leaveData['url_ttd'] ?? '',
      'ttd_atasan': '', // Not yet approved
      'nama_atasan': '', // Not yet approved
      'status': 'Diajukan', // Default status
      'users_id': user['id'],
    };

    final pdfController = Get.put(PdfCutiController());

    Get.to(() => PdfPreviewPage(
          title: 'Surat Cuti',
          pdfGenerator: () => pdfController.generateCutiPdf(pdfData),
        ));
  }

  void _showCutiDetailSheet(Map<String, dynamic> item) {
    final user = cutiController.currentUser.value ?? {};
    final nama = (item['nama'] ?? user['name'] ?? 'Unknown').toString();
    final group = (user['group'] ?? '-').toString();
    final jabatan = (user['jabatan'] ?? '-').toString();
    final lama = (item['lama_cuti'] ?? 0).toString();
    final sisaCuti = (user['sisa_cuti'] ?? '-').toString();
    final alasanRaw = (item['alasan_cuti'] ?? '-').toString();
    final alasan = alasanRaw.trim().isEmpty ? '-' : alasanRaw;
    final nrp = (user['nrp'] ?? '-').toString();
    final jenis = (item['jenis_cuti'] ?? '-').toString();

    final dates = _parseDateList((item['list_tanggal_cuti'] ?? '').toString());
    dates.sort();

    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      backgroundColor: Colors.transparent,
      builder: (context) => Wrap(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 6),
                    Text(
                      '$group - $jabatan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _jenisCutiBadgeColor(jenis)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            jenis,
                            style: TextStyle(
                              color: _jenisCutiBadgeColor(jenis),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$lama hari',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NRP: $nrp • Sisa: ${sisaCuti == '-' ? '-' : '$sisaCuti hari'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (dates.isEmpty)
                      Text(
                        '-',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dates.map((d) {
                          final label =
                              DateFormat('dd MMM yyyy', 'id_ID').format(d);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    Text(alasan),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _parseDateList(String dateList) {
    final dates = <DateTime>[];
    try {
      final parts = dateList.split(',');
      for (final raw in parts) {
        final s = raw.trim();
        if (s.isEmpty) continue;
        DateTime? d = DateTime.tryParse(s);
        if (d == null) {
          try {
            d = DateFormat('dd/MM/yyyy').parse(s);
          } catch (_) {}
        }
        if (d != null) {
          dates.add(d);
        }
      }
    } catch (_) {}
    return dates;
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
}
