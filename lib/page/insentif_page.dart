import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/login_controller.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class InsentifPage extends StatefulWidget {
  const InsentifPage({super.key});

  @override
  State<InsentifPage> createState() => _InsentifPageState();
}

class _InsentifPageState extends State<InsentifPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: const Text('Insentif'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          InsentifPremiTab(tabController: _tabController),
          InsentifLemburTab(tabController: _tabController),
        ],
      ),
    );
  }
}

class InsentifLemburTab extends StatefulWidget {
  final TabController tabController;

  const InsentifLemburTab({super.key, required this.tabController});

  @override
  State<InsentifLemburTab> createState() => _InsentifLemburTabState();
}

class _InsentifLemburTabState extends State<InsentifLemburTab> {
  final TextEditingController _nrpController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showForm = false;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _nrpController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showForm ? _buildAddForm() : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showForm = !_showForm;
          });
        },
        child: Icon(_showForm ? Icons.list : Icons.add),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchInsentifLembur(year: _selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final lembur = snapshot.data ?? [];
        final total = lembur.fold<int>(
          0,
          (sum, item) => sum + _parseNominal(item['nominal']),
        );
        if (lembur.isEmpty) {
          return Column(
            children: [
              _buildYearHeader(title: 'Total Lembur', total: total),
              const Expanded(
                child: Center(child: Text('Belum ada data insentif lembur')),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildYearHeader(title: 'Total Lembur', total: total),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: lembur.length,
                itemBuilder: (context, index) {
                  final item = lembur[index];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final nominalStr = NumberFormat.currency(
                          locale: 'id_ID', symbol: '', decimalDigits: 0)
                      .format(_parseNominal(item['nominal']));
                  final bulanStr = _formatDate(item['bulan']);
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['nama'] ?? 'Unknown').toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'NRP: ${(item['nrp'] ?? '-').toString()}',
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
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border:
                                            Border.all(color: Colors.orange),
                                      ),
                                      child: Text(
                                        'Lembur • $bulanStr',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rp $nominalStr',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
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
                              color: Colors.orange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Icon(Icons.chevron_right,
                                color: Colors.orange, size: 20),
                          ),
                        ],
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

  Widget _buildYearHeader({required String title, required int total}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedYear -= 1;
              });
            },
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Tahun sebelumnya',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedYear.toString(),
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
            onPressed: () {
              setState(() {
                _selectedYear += 1;
              });
            },
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Tahun berikutnya',
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

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Insentif Lembur',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nrpController,
                    decoration: const InputDecoration(
                      labelText: 'NRP',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'NRP tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nominalController,
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nominal tidak boleh kosong';
                      }
                      if (int.tryParse(value.replaceAll('.', '')) == null) {
                        return 'Nominal harus berupa angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Bulan'),
                    subtitle: Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showForm = false;
                              _clearForm();
                            });
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitLembur,
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitLembur() {
    if (_nrpController.text.isEmpty || _nominalController.text.isEmpty) {
      showTopToast(
        'Harap isi semua field',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final nominal = int.tryParse(_nominalController.text.replaceAll('.', ''));
    if (nominal == null) {
      showTopToast(
        'Nominal harus berupa angka',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Here you would submit to Supabase
    showTopToast(
      'Insentif lembur berhasil ditambahkan',
      background: Colors.green,
      foreground: Colors.white,
      duration: const Duration(seconds: 3),
    );
    setState(() {
      _showForm = false;
      _clearForm();
    });
  }

  void _clearForm() {
    _nrpController.clear();
    _nominalController.clear();
    _selectedDate = DateTime.now();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInsentifLembur(
      {required int year}) async {
    try {
      if (!Get.isRegistered<LoginController>()) {
        return [];
      }

      final loginController = Get.find<LoginController>();
      final user = loginController.currentUser.value;
      final userId = user?['id'];
      final nrp = (user?['nrp'] ?? '').toString();

      if (userId == null && nrp.isEmpty) {
        return [];
      }

      Future<List<Map<String, dynamic>>?> tryQuery({
        required Map<String, dynamic> filters,
        required dynamic tahunValue,
      }) async {
        try {
          dynamic q = SupabaseService.instance.client
              .from('insentif_lembur')
              .select('nama, nrp, nominal, bulan, tahun')
              .eq('tahun', tahunValue);
          for (final entry in filters.entries) {
            q = q.eq(entry.key, entry.value);
          }
          final resp = await q
              .order('tahun', ascending: false)
              .order('bulan', ascending: false)
              .limit(50);
          return List<Map<String, dynamic>>.from(resp);
        } catch (_) {
          return null;
        }
      }

      List<Map<String, dynamic>>? result;

      if (userId != null) {
        result =
            await tryQuery(filters: {'users_id': userId}, tahunValue: year);
        result ??=
            await tryQuery(filters: {'user_id': userId}, tahunValue: year);

        if (result != null && result.isEmpty) {
          result = await tryQuery(
                  filters: {'users_id': userId}, tahunValue: year.toString()) ??
              await tryQuery(
                  filters: {'user_id': userId}, tahunValue: year.toString());
        }
      }

      if (result == null || result.isEmpty) {
        result = await tryQuery(filters: {'nrp': nrp}, tahunValue: year);
        if (result != null && result.isEmpty) {
          result = await tryQuery(
              filters: {'nrp': nrp}, tahunValue: year.toString());
        }
      }

      return result ?? [];
    } catch (e) {
      throw 'Failed to fetch lembur incentives: $e';
    }
  }
}

class InsentifPremiTab extends StatefulWidget {
  final TabController tabController;

  const InsentifPremiTab({super.key, required this.tabController});

  @override
  State<InsentifPremiTab> createState() => _InsentifPremiTabState();
}

class _InsentifPremiTabState extends State<InsentifPremiTab> {
  final TextEditingController _nrpController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showForm = false;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _nrpController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showForm ? _buildAddForm() : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showForm = !_showForm;
          });
        },
        child: Icon(_showForm ? Icons.list : Icons.add),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchInsentifPremi(year: _selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final premi = snapshot.data ?? [];
        final total = premi.fold<int>(
          0,
          (sum, item) => sum + _parseNominal(item['nominal']),
        );
        if (premi.isEmpty) {
          return Column(
            children: [
              _buildYearHeader(title: 'Total Premi', total: total),
              const Expanded(
                child: Center(child: Text('Belum ada data insentif premi')),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildYearHeader(title: 'Total Premi', total: total),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: premi.length,
                itemBuilder: (context, index) {
                  final item = premi[index];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final nominalStr = NumberFormat.currency(
                          locale: 'id_ID', symbol: '', decimalDigits: 0)
                      .format(_parseNominal(item['nominal']));
                  final bulanStr = _formatDate(item['bulan']);
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['nama'] ?? 'Unknown').toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'NRP: ${(item['nrp'] ?? '-').toString()} • Group: ${(item['group'] ?? '-').toString()}',
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
                                            Colors.teal.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(color: Colors.teal),
                                      ),
                                      child: Text(
                                        'Premi • $bulanStr',
                                        style: const TextStyle(
                                          color: Colors.teal,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rp $nominalStr',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
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
                              color: Colors.teal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.teal),
                            ),
                            child: const Icon(Icons.chevron_right,
                                color: Colors.teal, size: 20),
                          ),
                        ],
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

  Widget _buildYearHeader({required String title, required int total}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedYear -= 1;
              });
            },
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Tahun sebelumnya',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedYear.toString(),
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
            onPressed: () {
              setState(() {
                _selectedYear += 1;
              });
            },
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Tahun berikutnya',
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

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Insentif Premi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nrpController,
                    decoration: const InputDecoration(
                      labelText: 'NRP',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'NRP tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nominalController,
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nominal tidak boleh kosong';
                      }
                      if (int.tryParse(value.replaceAll('.', '')) == null) {
                        return 'Nominal harus berupa angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Bulan'),
                    subtitle: Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showForm = false;
                              _clearForm();
                            });
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitPremi,
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitPremi() {
    if (_nrpController.text.isEmpty || _nominalController.text.isEmpty) {
      showTopToast(
        'Harap isi semua field',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final nominal = int.tryParse(_nominalController.text.replaceAll('.', ''));
    if (nominal == null) {
      showTopToast(
        'Nominal harus berupa angka',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Here you would submit to Supabase
    showTopToast(
      'Insentif premi berhasil ditambahkan',
      background: Colors.green,
      foreground: Colors.white,
      duration: const Duration(seconds: 3),
    );
    setState(() {
      _showForm = false;
      _clearForm();
    });
  }

  void _clearForm() {
    _nrpController.clear();
    _nominalController.clear();
    _selectedDate = DateTime.now();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInsentifPremi(
      {required int year}) async {
    try {
      if (!Get.isRegistered<LoginController>()) {
        return [];
      }

      final loginController = Get.find<LoginController>();
      final user = loginController.currentUser.value;
      final userId = user?['id'];
      final nrp = (user?['nrp'] ?? '').toString();

      if (userId == null && nrp.isEmpty) {
        return [];
      }

      Future<List<Map<String, dynamic>>?> tryQuery({
        required Map<String, dynamic> filters,
        required dynamic tahunValue,
      }) async {
        try {
          dynamic q = SupabaseService.instance.client
              .from('insentif_premi')
              .select('nama, nrp, nominal, bulan, tahun')
              .eq('tahun', tahunValue);
          for (final entry in filters.entries) {
            q = q.eq(entry.key, entry.value);
          }
          final resp = await q
              .order('tahun', ascending: false)
              .order('bulan', ascending: false)
              .limit(50);
          return List<Map<String, dynamic>>.from(resp);
        } catch (_) {
          return null;
        }
      }

      List<Map<String, dynamic>>? result;

      if (userId != null) {
        result =
            await tryQuery(filters: {'users_id': userId}, tahunValue: year);
        result ??=
            await tryQuery(filters: {'user_id': userId}, tahunValue: year);

        if (result != null && result.isEmpty) {
          result = await tryQuery(
                  filters: {'users_id': userId}, tahunValue: year.toString()) ??
              await tryQuery(
                  filters: {'user_id': userId}, tahunValue: year.toString());
        }
      }

      if (result == null || result.isEmpty) {
        result = await tryQuery(filters: {'nrp': nrp}, tahunValue: year);
        if (result != null && result.isEmpty) {
          result = await tryQuery(
              filters: {'nrp': nrp}, tahunValue: year.toString());
        }
      }

      return result ?? [];
    } catch (e) {
      throw 'Failed to fetch premi incentives: $e';
    }
  }
}
