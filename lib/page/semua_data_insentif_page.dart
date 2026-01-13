import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class SemuaDataInsentifPage extends StatefulWidget {
  const SemuaDataInsentifPage({super.key});

  @override
  State<SemuaDataInsentifPage> createState() => _SemuaDataInsentifPageState();
}

class _SemuaDataInsentifPageState extends State<SemuaDataInsentifPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  String _typeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Semua Data Insentif'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lembur'),
            Tab(text: 'Premi'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Cari berdasarkan nama atau NRP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Filter Bulan:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _typeFilter,
                      items: ['Semua', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                              'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember']
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _typeFilter = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLemburTab(),
                _buildPremiTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLemburTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllInsentifLembur(),
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

        if (filteredLembur.isEmpty) {
          return const Center(child: Text('Tidak ada data insentif lembur'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredLembur.length,
          itemBuilder: (context, index) {
            final item = filteredLembur[index];
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
                            item['nama'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text(
                            'Lembur',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('NRP: ${item['nrp'] ?? '-'}'),
                    Text('Bulan: ${_getMonthName(item['bulan'])} ${item['tahun'] ?? ''}'),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(item['nominal'] ?? 0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Tanggal: ${item['created_at'] != null ? DateFormat('dd/MM/yyyy', 'id_ID').format(DateTime.parse(item['created_at'])) : '-'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showDetailDialog(item, 'Lembur'),
                          icon: const Icon(Icons.visibility),
                          label: const Text('Detail'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllInsentifPremi(),
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

        if (filteredPremi.isEmpty) {
          return const Center(child: Text('Tidak ada data insentif premi'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredPremi.length,
          itemBuilder: (context, index) {
            final item = filteredPremi[index];
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
                            item['nama'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple),
                          ),
                          child: const Text(
                            'Premi',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('NRP: ${item['nrp'] ?? '-'}'),
                    Text('Bulan: ${_getMonthName(item['bulan'])} ${item['tahun'] ?? ''}'),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(item['nominal'] ?? 0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Tanggal: ${item['created_at'] != null ? DateFormat('dd/MM/yyyy', 'id_ID').format(DateTime.parse(item['created_at'])) : '-'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showDetailDialog(item, 'Premi'),
                          icon: const Icon(Icons.visibility),
                          label: const Text('Detail'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              Text('Bulan: ${_getMonthName(insentif['bulan'])} ${insentif['tahun']}'),
              Text('Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(insentif['nominal'] ?? 0)}'),
              if (insentif['created_at'] != null)
                Text('Tanggal Dibuat: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(insentif['created_at']))}'),
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

  Future<List<Map<String, dynamic>>> _fetchAllInsentifLembur() async {
    try {
      final response = await SupabaseService.instance.client
          .from('insentif_lembur')
          .select('''
            id, nama, nominal, bulan, tahun, nrp, created_at,
            users!inner(name)
          ''')
          .order('users.name');

      // Transform the nested data
      return response.map((item) => {
        'id': item['id'],
        'nama': item['nama'] ?? item['users']?['name'],
        'nominal': item['nominal'],
        'bulan': item['bulan'],
        'tahun': item['tahun'],
        'nrp': item['nrp'] ?? item['users']?['nrp'],
        'created_at': item['created_at'],
      }).toList();
    } catch (e) {
      throw 'Failed to fetch all insentif lembur: $e';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllInsentifPremi() async {
    try {
      final response = await SupabaseService.instance.client
          .from('insentif_premi')
          .select('''
            id, nama, nominal, bulan, tahun, nrp, created_at,
            users!inner(name)
          ''')
          .order('users.name');

      // Transform the nested data
      return response.map((item) => {
        'id': item['id'],
        'nama': item['nama'] ?? item['users']?['name'],
        'nominal': item['nominal'],
        'bulan': item['bulan'],
        'tahun': item['tahun'],
        'nrp': item['nrp'] ?? item['users']?['nrp'],
        'created_at': item['created_at'],
      }).toList();
    } catch (e) {
      throw 'Failed to fetch all insentif premi: $e';
    }
  }
}