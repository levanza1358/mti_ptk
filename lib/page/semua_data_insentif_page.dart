// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class SemuaDataInsentifPage extends StatefulWidget {
  const SemuaDataInsentifPage({super.key});

  @override
  State<SemuaDataInsentifPage> createState() => _SemuaDataInsentifPageState();
}

class _SemuaDataInsentifPageState extends State<SemuaDataInsentifPage>
    with TickerProviderStateMixin {
  void _logUpload(String message) {
    if (kReleaseMode) return;
    debugPrint('[UPLOAD_INSENTIF] $message');
  }

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  String _typeFilter = 'Semua';
  final ScrollController _monthScrollController = ScrollController();
  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];
  late int _selectedYearLembur;
  late int _selectedYearPremi;
  bool _isDeletingLembur = false;
  bool _isDeletingPremi = false;
  bool _isUploadingLembur = false;
  bool _isUploadingPremi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _selectedYearLembur = now.year;
    _selectedYearPremi = now.year;
    _typeFilter = DateFormat('MMMM', 'id_ID').format(now);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _monthScrollController.dispose();
    super.dispose();
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
        title: const Text('Semua Data Insentif'),
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
              dividerColor: Colors.transparent,
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
                Tab(text: 'Premi'),
                Tab(text: 'Lembur'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari berdasarkan nama atau NRP',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Bulan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                if (!_monthScrollController.hasClients) return;
                                final target =
                                    (_monthScrollController.offset - 200).clamp(
                                        0.0,
                                        _monthScrollController
                                            .position.maxScrollExtent);
                                _monthScrollController.animateTo(
                                  target,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              },
                            ),
                            Expanded(
                              child: ScrollConfiguration(
                                behavior:
                                    const MaterialScrollBehavior().copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.touch,
                                  },
                                ),
                                child: SingleChildScrollView(
                                  controller: _monthScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...[
                                        'Semua',
                                        ..._months,
                                      ].map((value) {
                                        final isSelected = _typeFilter == value;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: ChoiceChip(
                                            label: Text(
                                              value,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            selected: isSelected,
                                            onSelected: (_) {
                                              setState(() {
                                                _typeFilter = value;
                                              });
                                            },
                                            selectedColor: Colors.blue,
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[700]
                                                    : Colors.grey[300],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                if (!_monthScrollController.hasClients) return;
                                final target =
                                    (_monthScrollController.offset + 200).clamp(
                                        0.0,
                                        _monthScrollController
                                            .position.maxScrollExtent);
                                _monthScrollController.animateTo(
                                  target,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPremiTab(),
                _buildLemburTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLemburTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllInsentifLembur(year: _selectedYearLembur),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final lembur = snapshot.data ?? [];

        // Apply filters
        final filteredLembur = lembur.where((item) {
          final matchesSearch = _searchQuery.isEmpty ||
              item['nama']?.toLowerCase().contains(_searchQuery) == true ||
              item['nrp']?.toLowerCase().contains(_searchQuery) == true;

          final matchesMonth = _typeFilter == 'Semua' ||
              _getMonthName(item['bulan']) == _typeFilter;

          return matchesSearch && matchesMonth;
        }).toList();

        filteredLembur.sort(_compareByNamaAsc);

        final total = filteredLembur.fold<int>(
          0,
          (sum, item) => sum + _parseNominal(item['nominal']),
        );

        if (filteredLembur.isEmpty) {
          return Column(
            children: [
              _buildYearHeader(
                selectedYear: _selectedYearLembur,
                title: 'Total Lembur',
                total: total,
                onPrev: () {
                  setState(() {
                    _selectedYearLembur -= 1;
                  });
                },
                onNext: () {
                  setState(() {
                    _selectedYearLembur += 1;
                  });
                },
                isDeleting: _isDeletingLembur,
                isUploading: _isUploadingLembur,
                visibleCount: filteredLembur.length,
                onDeleteVisible: null,
                onUpload: _isUploadingLembur || _isDeletingLembur
                    ? null
                    : () => _openUploadDialog(
                          table: 'insentif_lembur',
                          label: 'Lembur',
                          defaultYear: _selectedYearLembur,
                        ),
              ),
              const Expanded(
                  child: Center(child: Text('Tidak ada data insentif lembur'))),
            ],
          );
        }

        return Column(
          children: [
            _buildYearHeader(
              selectedYear: _selectedYearLembur,
              title: 'Total Lembur',
              total: total,
              onPrev: () {
                setState(() {
                  _selectedYearLembur -= 1;
                });
              },
              onNext: () {
                setState(() {
                  _selectedYearLembur += 1;
                });
              },
              isDeleting: _isDeletingLembur,
              isUploading: _isUploadingLembur,
              visibleCount: filteredLembur.length,
              onDeleteVisible: _isDeletingLembur || filteredLembur.isEmpty
                  ? null
                  : () => _confirmDeleteVisible(
                        table: 'insentif_lembur',
                        label: 'Lembur',
                        items: filteredLembur,
                      ),
              onUpload: _isUploadingLembur || _isDeletingLembur
                  ? null
                  : () => _openUploadDialog(
                        table: 'insentif_lembur',
                        label: 'Lembur',
                        defaultYear: _selectedYearLembur,
                      ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredLembur.length,
                itemBuilder: (context, index) {
                  final item = filteredLembur[index];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  const badgeColor = Colors.blue;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.08),
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
                        onTap: () => _showDetailDialog(item, 'Lembur'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: badgeColor, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: badgeColor,
                                      child: Text(
                                        (item['nama'] ?? 'U')
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
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
                                                (item['nama'] ?? 'Unknown')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: badgeColor
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: badgeColor),
                                              ),
                                              child: const Text(
                                                'Lembur',
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'NRP: ${item['nrp'] ?? '-'} • Bulan: ${_getMonthName(item['bulan'])} ${item['tahun'] ?? ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(_parseNominal(item['nominal']))}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                  Text(
                                    'Tanggal: ${item['created_at'] != null ? DateFormat('dd/MM/yyyy', 'id_ID').format(DateTime.parse(item['created_at'])) : '-'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showDetailDialog(item, 'Lembur'),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Detail'),
                                  ),
                                  TextButton.icon(
                                    onPressed: _isDeletingLembur
                                        ? null
                                        : () => _confirmDeleteOne(
                                              table: 'insentif_lembur',
                                              label: 'Lembur',
                                              item: item,
                                            ),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Hapus'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllInsentifPremi(year: _selectedYearPremi),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final premi = snapshot.data ?? [];

        // Apply filters
        final filteredPremi = premi.where((item) {
          final matchesSearch = _searchQuery.isEmpty ||
              item['nama']?.toLowerCase().contains(_searchQuery) == true ||
              item['nrp']?.toLowerCase().contains(_searchQuery) == true;

          final matchesMonth = _typeFilter == 'Semua' ||
              _getMonthName(item['bulan']) == _typeFilter;

          return matchesSearch && matchesMonth;
        }).toList();

        filteredPremi.sort(_compareByNamaAsc);

        final total = filteredPremi.fold<int>(
          0,
          (sum, item) => sum + _parseNominal(item['nominal']),
        );

        if (filteredPremi.isEmpty) {
          return Column(
            children: [
              _buildYearHeader(
                selectedYear: _selectedYearPremi,
                title: 'Total Premi',
                total: total,
                onPrev: () {
                  setState(() {
                    _selectedYearPremi -= 1;
                  });
                },
                onNext: () {
                  setState(() {
                    _selectedYearPremi += 1;
                  });
                },
                isDeleting: _isDeletingPremi,
                isUploading: _isUploadingPremi,
                visibleCount: filteredPremi.length,
                onDeleteVisible: null,
                onUpload: _isUploadingPremi || _isDeletingPremi
                    ? null
                    : () => _openUploadDialog(
                          table: 'insentif_premi',
                          label: 'Premi',
                          defaultYear: _selectedYearPremi,
                        ),
              ),
              const Expanded(
                  child: Center(child: Text('Tidak ada data insentif premi'))),
            ],
          );
        }

        return Column(
          children: [
            _buildYearHeader(
              selectedYear: _selectedYearPremi,
              title: 'Total Premi',
              total: total,
              onPrev: () {
                setState(() {
                  _selectedYearPremi -= 1;
                });
              },
              onNext: () {
                setState(() {
                  _selectedYearPremi += 1;
                });
              },
              isDeleting: _isDeletingPremi,
              isUploading: _isUploadingPremi,
              visibleCount: filteredPremi.length,
              onDeleteVisible: _isDeletingPremi || filteredPremi.isEmpty
                  ? null
                  : () => _confirmDeleteVisible(
                        table: 'insentif_premi',
                        label: 'Premi',
                        items: filteredPremi,
                      ),
              onUpload: _isUploadingPremi || _isDeletingPremi
                  ? null
                  : () => _openUploadDialog(
                        table: 'insentif_premi',
                        label: 'Premi',
                        defaultYear: _selectedYearPremi,
                      ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredPremi.length,
                itemBuilder: (context, index) {
                  final item = filteredPremi[index];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  const badgeColor = Colors.blue;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.08),
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
                        onTap: () => _showDetailDialog(item, 'Premi'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: badgeColor, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: badgeColor,
                                      child: Text(
                                        (item['nama'] ?? 'U')
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
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
                                                (item['nama'] ?? 'Unknown')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: badgeColor
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: badgeColor),
                                              ),
                                              child: const Text(
                                                'Premi',
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'NRP: ${item['nrp'] ?? '-'} • Bulan: ${_getMonthName(item['bulan'])} ${item['tahun'] ?? ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(_parseNominal(item['nominal']))}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                  Text(
                                    'Tanggal: ${item['created_at'] != null ? DateFormat('dd/MM/yyyy', 'id_ID').format(DateTime.parse(item['created_at'])) : '-'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showDetailDialog(item, 'Premi'),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Detail'),
                                  ),
                                  TextButton.icon(
                                    onPressed: _isDeletingPremi
                                        ? null
                                        : () => _confirmDeleteOne(
                                              table: 'insentif_premi',
                                              label: 'Premi',
                                              item: item,
                                            ),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Hapus'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearHeader({
    required int selectedYear,
    required String title,
    required int total,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required bool isDeleting,
    required bool isUploading,
    required int visibleCount,
    required VoidCallback? onDeleteVisible,
    required VoidCallback? onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Tahun sebelumnya',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  selectedYear.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$title: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(total)}',
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Tahun berikutnya',
          ),
          IconButton(
            onPressed: onUpload,
            icon: isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            tooltip: 'Upload data',
          ),
          IconButton(
            onPressed: onDeleteVisible,
            icon: isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep),
            tooltip: visibleCount > 0
                ? 'Hapus $visibleCount data yang tampil'
                : 'Tidak ada data untuk dihapus',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  int _parseNominal(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    final raw = value.toString().trim();
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(cleaned) ?? 0;
  }

  int _compareByNamaAsc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final nameA = (a['nama'] ?? '').toString().toLowerCase();
    final nameB = (b['nama'] ?? '').toString().toLowerCase();
    final byName = nameA.compareTo(nameB);
    if (byName != 0) return byName;

    final nrpA = (a['nrp'] ?? '').toString().toLowerCase();
    final nrpB = (b['nrp'] ?? '').toString().toLowerCase();
    return nrpA.compareTo(nrpB);
  }

  String _getMonthName(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showDetailDialog(Map<String, dynamic> insentif, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Insentif $type'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${insentif['nama']}'),
              Text('NRP: ${insentif['nrp']}'),
              Text('Jenis: $type'),
              Text(
                  'Bulan: ${_getMonthName(insentif['bulan'])} ${insentif['tahun']}'),
              Text(
                  'Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(insentif['nominal'] ?? 0)}'),
              if (insentif['created_at'] != null)
                Text(
                    'Tanggal Dibuat: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(insentif['created_at']))}'),
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

  Future<void> _openUploadDialog({
    required String table,
    required String label,
    required int defaultYear,
  }) async {
    _logUpload('openDialog table=$table label=$label defaultYear=$defaultYear');
    final yearController = TextEditingController(text: defaultYear.toString());
    final months = <String>[
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    var selectedMonth = DateTime.now().month;
    var isSubmitting = false;
    PlatformFile? selectedFile;
    Uint8List? selectedBytes;

    Future<void> setUploading(bool value) async {
      if (!mounted) return;
      setState(() {
        if (table == 'insentif_lembur') {
          _isUploadingLembur = value;
        } else {
          _isUploadingPremi = value;
        }
      });
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Upload Insentif $label'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Bulan',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (i) => i + 1)
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(months[m - 1]),
                                ),
                              )
                              .toList(),
                          onChanged: isSubmitting
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setLocalState(() => selectedMonth = value);
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tahun',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !isSubmitting,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  _logUpload('pickFile start');
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: const ['xlsx'],
                                    withData: true,
                                  );
                                  _logUpload(
                                    'pickFile result='
                                    '${result == null ? 'null' : 'files=${result.files.length}'}',
                                  );
                                  final file = result?.files.isNotEmpty == true
                                      ? result!.files.first
                                      : null;
                                  final bytes = file?.bytes;
                                  _logUpload(
                                    'pickFile selected='
                                    '${file?.name ?? 'null'} bytes=${bytes?.length ?? 0}',
                                  );
                                  setLocalState(() {
                                    selectedFile = file;
                                    selectedBytes = bytes;
                                  });
                                },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Pilih File .xlsx'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selectedFile?.name ?? 'Belum ada file dipilih',
                      style: TextStyle(
                        color: selectedFile == null
                            ? Colors.grey
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      _logUpload(
                        'submit pressed table=$table label=$label '
                        'month=$selectedMonth yearText="${yearController.text.trim()}"',
                      );
                      final year = int.tryParse(yearController.text.trim());
                      if (year == null || year < 2000 || year > 2100) {
                        _logUpload('submit invalidYear parsedYear=$year');
                        showTopToast(
                          'Tahun tidak valid',
                          background: Colors.red,
                          foreground: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }

                      if (selectedBytes == null || selectedBytes!.isEmpty) {
                        _logUpload('submit missingFile bytes=nullOrEmpty');
                        showTopToast(
                          'File .xlsx belum dipilih',
                          background: Colors.red,
                          foreground: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }

                      final monthIso =
                          DateTime(year, selectedMonth, 1).toIso8601String();
                      _logUpload('submit monthIso=$monthIso year=$year');

                      _logUpload('fetch users map start');
                      final userMaps = await _fetchUserIdByNrpMaps();
                      _logUpload(
                        'fetch users map done exact=${userMaps.exact.length} loose=${userMaps.loose.length}',
                      );
                      final parsed = _parseXlsxInsentif(
                        bytes: selectedBytes!,
                        monthIso: monthIso,
                        year: year,
                        usersByNrpExact: userMaps.exact,
                        usersByNrpLoose: userMaps.loose,
                      );
                      final rows = parsed.rows;
                      final skipped = parsed.skipped;
                      _logUpload(
                          'parse done rows=${rows.length} skipped=$skipped');

                      if (rows.isEmpty) {
                        _logUpload('submit noValidRows');
                        showTopToast(
                          'Tidak ada baris yang valid',
                          background: Colors.red,
                          foreground: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }

                      setLocalState(() => isSubmitting = true);
                      await setUploading(true);
                      try {
                        _logUpload(
                            'insert start table=$table rows=${rows.length}');
                        await _insertInsentifRows(table: table, rows: rows);
                        _logUpload('insert success table=$table');
                        if (!mounted) return;

                        setState(() {
                          if (table == 'insentif_lembur') {
                            _selectedYearLembur = year;
                          } else {
                            _selectedYearPremi = year;
                          }
                        });

                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        showTopToast(
                          'Upload $label: ${rows.length} baris, skip $skipped',
                          background: Colors.green,
                          foreground: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      } catch (e, st) {
                        _logUpload('insert error table=$table error=$e');
                        _logUpload('insert stack=${st.toString()}');
                        if (!mounted) return;
                        showTopToast(
                          'Gagal upload $label: $e',
                          background: Colors.red,
                          foreground: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                        setLocalState(() => isSubmitting = false);
                      } finally {
                        await setUploading(false);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  ({List<Map<String, dynamic>> rows, int skipped}) _parseXlsxInsentif({
    required Uint8List bytes,
    required String monthIso,
    required int year,
    required Map<String, ({String id, String nrp})> usersByNrpExact,
    required Map<String, ({String id, String nrp})> usersByNrpLoose,
  }) {
    final excel = xlsx.Excel.decodeBytes(bytes);
    final sheetName =
        excel.tables.keys.isNotEmpty ? excel.tables.keys.first : null;
    final sheet = sheetName != null ? excel.tables[sheetName] : null;
    if (sheet == null) {
      _logUpload('parse sheet=null');
      return (rows: <Map<String, dynamic>>[], skipped: 0);
    }

    final rows = <Map<String, dynamic>>[];
    var skipped = 0;
    var skippedEmptyRow = 0;
    var skippedMissingFields = 0;
    var skippedUserNotFound = 0;

    int colNrp = 0;
    int colNama = 1;
    int colNominal = 2;
    var dataStartIndex = 0;

    if (sheet.rows.isNotEmpty) {
      final header = sheet.rows.first
          .map((c) => c?.value?.toString().trim().toLowerCase() ?? '')
          .toList();
      final headerJoined = header.join(' ');
      if (headerJoined.contains('nrp') &&
          headerJoined.contains('nama') &&
          headerJoined.contains('nominal')) {
        colNrp = header.indexWhere((h) => h.contains('nrp'));
        colNama = header.indexWhere((h) => h.contains('nama'));
        colNominal = header.indexWhere((h) => h.contains('nominal'));
        if (colNrp < 0) colNrp = 0;
        if (colNama < 0) colNama = 1;
        if (colNominal < 0) colNominal = 2;
        dataStartIndex = 1;
      }
    }

    for (var r = dataStartIndex; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) {
        skipped += 1;
        skippedEmptyRow += 1;
        continue;
      }

      dynamic cellAt(int i) => i >= 0 && i < row.length ? row[i]?.value : null;

      final nrpRaw = cellAt(colNrp);
      final namaRaw = cellAt(colNama);
      final nominalRaw = cellAt(colNominal);

      final nrpKey = _normalizeNrpValue(nrpRaw);
      final nama = (namaRaw ?? '').toString().trim();
      final nominal = _parseNominal(nominalRaw);

      if (nrpKey.isEmpty || nama.isEmpty) {
        skipped += 1;
        skippedMissingFields += 1;
        continue;
      }

      final user = usersByNrpExact[nrpKey] ??
          usersByNrpLoose[_stripLeadingZeros(nrpKey)];
      if (user == null) {
        skipped += 1;
        skippedUserNotFound += 1;
        continue;
      }

      rows.add({
        'nrp': user.nrp,
        'nama': nama,
        'nominal': nominal,
        'bulan': monthIso,
        'tahun': year,
        'users_id': user.id,
      });
    }

    _logUpload(
      'parse stats totalSheetRows=${sheet.rows.length} '
      'dataStart=$dataStartIndex '
      'skipped=$skipped emptyRow=$skippedEmptyRow missingFields=$skippedMissingFields userNotFound=$skippedUserNotFound',
    );
    return (rows: rows, skipped: skipped);
  }

  Future<
      ({
        Map<String, ({String id, String nrp})> exact,
        Map<String, ({String id, String nrp})> loose
      })> _fetchUserIdByNrpMaps() async {
    final response = await SupabaseService.instance.client
        .from('users')
        .select('id, nrp')
        .limit(5000);

    final exact = <String, ({String id, String nrp})>{};
    final loose = <String, ({String id, String nrp})>{};

    for (final u in response) {
      final id = (u['id'] ?? '').toString().trim();
      final nrp = (u['nrp'] ?? '').toString().trim();
      if (id.isEmpty || nrp.isEmpty) continue;

      final keyExact = _normalizeNrpValue(nrp);
      if (keyExact.isEmpty) continue;

      exact.putIfAbsent(keyExact, () => (id: id, nrp: nrp));
      final keyLoose = _stripLeadingZeros(keyExact);
      if (keyLoose.isNotEmpty) {
        loose.putIfAbsent(keyLoose, () => (id: id, nrp: nrp));
      }
    }

    return (exact: exact, loose: loose);
  }

  String _normalizeNrpValue(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    if (value is double) {
      final asInt = value.toInt();
      if (value == asInt.toDouble()) return asInt.toString();
      return value.toString();
    }

    var s = value.toString().trim();
    if (s.isEmpty) return '';
    s = s.replaceAll(' ', '');
    final m = RegExp(r'^(\d+)\.0$').firstMatch(s);
    if (m != null) {
      s = m.group(1) ?? s;
    }
    return s;
  }

  String _stripLeadingZeros(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return '';
    final out = trimmed.replaceFirst(RegExp(r'^0+'), '');
    return out.isEmpty ? '0' : out;
  }

  Future<void> _insertInsentifRows({
    required String table,
    required List<Map<String, dynamic>> rows,
  }) async {
    const chunkSize = 200;
    for (var i = 0; i < rows.length; i += chunkSize) {
      var end = i + chunkSize;
      if (end > rows.length) end = rows.length;
      final chunk = rows.sublist(i, end);
      _logUpload(
          'insert chunk start table=$table range=$i..${end - 1} size=${chunk.length}');
      try {
        await SupabaseService.instance.client.from(table).insert(chunk);
        _logUpload('insert chunk ok table=$table range=$i..${end - 1}');
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final looksLikeUsersIdMissing = msg.contains('users_id') &&
            msg.contains('column') &&
            msg.contains('exist');
        if (!looksLikeUsersIdMissing) {
          _logUpload(
              'insert chunk error table=$table range=$i..${end - 1} error=$e');
          rethrow;
        }

        _logUpload(
            'insert chunk fallback users_id->user_id table=$table range=$i..${end - 1}');

        final fallbackChunk = chunk
            .map((r) => Map<String, dynamic>.from(r)
              ..update(
                'users_id',
                (v) => v,
                ifAbsent: () => null,
              ))
            .map((r) {
          if (r.containsKey('users_id')) {
            final v = r.remove('users_id');
            if (v != null) {
              r['user_id'] = v;
            }
          }
          return r;
        }).toList();

        await SupabaseService.instance.client.from(table).insert(fallbackChunk);
        _logUpload(
            'insert chunk fallback ok table=$table range=$i..${end - 1}');
      }
    }
  }

  Future<void> _confirmDeleteOne({
    required String table,
    required String label,
    required Map<String, dynamic> item,
  }) async {
    final id = item['id'];
    if (id == null) {
      showTopToast(
        'ID data tidak valid',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final nama = (item['nama'] ?? '-').toString();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus data $label untuk "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteIds(
                table: table,
                label: label,
                ids: [id],
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteVisible({
    required String table,
    required String label,
    required List<Map<String, dynamic>> items,
  }) async {
    final ids = items
        .map((e) => e['id'])
        .where((id) => id != null)
        .toList(growable: false);

    if (ids.isEmpty) {
      showTopToast('Tidak ada data yang bisa dihapus');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus ${ids.length} data $label yang tampil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteIds(table: table, label: label, ids: ids);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIds({
    required String table,
    required String label,
    required List<dynamic> ids,
  }) async {
    final isLembur = table == 'insentif_lembur';
    if (isLembur) {
      setState(() => _isDeletingLembur = true);
    } else {
      setState(() => _isDeletingPremi = true);
    }

    try {
      try {
        await SupabaseService.instance.client.from(table).delete().inFilter(
              'id',
              ids,
            );
      } catch (_) {
        for (final id in ids) {
          await SupabaseService.instance.client
              .from(table)
              .delete()
              .eq('id', id);
        }
      }

      if (mounted) {
        showTopToast(
          'Data $label berhasil dihapus',
          background: Colors.green,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        showTopToast(
          'Gagal menghapus data $label: $e',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        if (isLembur) {
          setState(() => _isDeletingLembur = false);
        } else {
          setState(() => _isDeletingPremi = false);
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllInsentifLembur(
      {required int year}) async {
    try {
      dynamic response;
      try {
        response = await SupabaseService.instance.client
            .from('insentif_lembur')
            .select('''
            id, nama, nominal, bulan, tahun, nrp, created_at,
            users(name, nrp)
          ''')
            .eq('tahun', year)
            .order('nama');
      } catch (_) {
        try {
          response = await SupabaseService.instance.client
              .from('insentif_lembur')
              .select('''
            id, nama, nominal, bulan, tahun, nrp, created_at,
            users(name, nrp)
          ''')
              .eq('tahun', year.toString())
              .order('nama');
        } catch (_) {
          try {
            response = await SupabaseService.instance.client
                .from('insentif_lembur')
                .select('id, nama, nominal, bulan, tahun, nrp, created_at')
                .eq('tahun', year)
                .order('nama');
          } catch (_) {
            response = await SupabaseService.instance.client
                .from('insentif_lembur')
                .select('id, nama, nominal, bulan, tahun, nrp, created_at')
                .eq('tahun', year.toString())
                .order('nama');
          }
        }
      }

      final List<dynamic> raw = List<dynamic>.from(response as List);

      return raw.map<Map<String, dynamic>>((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final users = map['users'];
        final usersMap = users is Map ? Map<String, dynamic>.from(users) : null;

        return <String, dynamic>{
          'id': map['id'],
          'nama': map['nama'] ?? usersMap?['name'],
          'nominal': map['nominal'],
          'bulan': map['bulan'],
          'tahun': map['tahun'],
          'nrp': map['nrp'] ?? usersMap?['nrp'],
          'created_at': map['created_at'],
        };
      }).toList();
    } catch (e) {
      throw 'Failed to fetch all insentif lembur: $e';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllInsentifPremi(
      {required int year}) async {
    try {
      dynamic response;
      try {
        response = await SupabaseService.instance.client
            .from('insentif_premi')
            .select('''
            id, nama, nominal, bulan, tahun, nrp, created_at,
            users(name, nrp)
          ''')
            .eq('tahun', year)
            .order('nama');
      } catch (_) {
        try {
          response = await SupabaseService.instance.client
              .from('insentif_premi')
              .select('''
            id, nama, nominal, bulan, tahun, nrp, created_at,
            users(name, nrp)
          ''')
              .eq('tahun', year.toString())
              .order('nama');
        } catch (_) {
          try {
            response = await SupabaseService.instance.client
                .from('insentif_premi')
                .select('id, nama, nominal, bulan, tahun, nrp, created_at')
                .eq('tahun', year)
                .order('nama');
          } catch (_) {
            response = await SupabaseService.instance.client
                .from('insentif_premi')
                .select('id, nama, nominal, bulan, tahun, nrp, created_at')
                .eq('tahun', year.toString())
                .order('nama');
          }
        }
      }

      final List<dynamic> raw = List<dynamic>.from(response as List);

      return raw.map<Map<String, dynamic>>((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final users = map['users'];
        final usersMap = users is Map ? Map<String, dynamic>.from(users) : null;

        return <String, dynamic>{
          'id': map['id'],
          'nama': map['nama'] ?? usersMap?['name'],
          'nominal': map['nominal'],
          'bulan': map['bulan'],
          'tahun': map['tahun'],
          'nrp': map['nrp'] ?? usersMap?['nrp'],
          'created_at': map['created_at'],
        };
      }).toList();
    } catch (e) {
      throw 'Failed to fetch all insentif premi: $e';
    }
  }
}
