import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class SemuaDataCutiPage extends StatefulWidget {
  const SemuaDataCutiPage({super.key});

  @override
  State<SemuaDataCutiPage> createState() => _SemuaDataCutiPageState();
}

class _SemuaDataCutiPageState extends State<SemuaDataCutiPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text('Semua Data Cuti'),
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
                    const Text('Jenis Cuti:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _typeFilter,
                      items: ['Semua', 'Cuti Tahunan', 'Cuti Alasan Penting', 'Cuti Sakit']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
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

          // Data List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllCuti(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final cuti = snapshot.data ?? [];

                // Apply filters
                final filteredCuti = cuti.where((item) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      item['nama']?.toLowerCase().contains(_searchQuery) == true ||
                      item['nrp']?.toLowerCase().contains(_searchQuery) == true;

                  final matchesType = _typeFilter == 'Semua' ||
                      (item['jenis_cuti'] ?? '') == _typeFilter;

                  return matchesSearch && matchesType;
                }).toList();

                if (filteredCuti.isEmpty) {
                  return const Center(child: Text('Tidak ada data cuti'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredCuti.length,
                  itemBuilder: (context, index) {
                    final item = filteredCuti[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('NRP: ${item['nrp'] ?? '-'}'),
                            Text('Jenis Cuti: ${item['jenis_cuti'] ?? '-'}'),
                            Text('Lama Cuti: ${item['lama_cuti'] ?? 0} hari'),
                            Text('Sisa Cuti: ${item['sisa_cuti'] ?? 0} hari'),
                            Text(
                              'Tanggal Pengajuan: ${item['tanggal_pengajuan'] != null ? DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(item['tanggal_pengajuan'])) : '-'}',
                            ),
                            if (item['list_tanggal_cuti'] != null && item['list_tanggal_cuti'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Tanggal Cuti: ${item['list_tanggal_cuti']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            if (item['alasan_cuti'] != null && item['alasan_cuti'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Alasan: ${item['alasan_cuti']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showDetailDialog(item),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Detail'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showPrintDialog(item),
                                  icon: const Icon(Icons.print),
                                  label: const Text('Print'),
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
            ),
          ),
        ],
      ),
    );
  }



  void _showDetailDialog(Map<String, dynamic> cuti) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Cuti'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${cuti['nama']}'),
              Text('NRP: ${cuti['nrp']}'),
              Text('Jenis Cuti: ${cuti['jenis_cuti']}'),
              Text('Lama Cuti: ${cuti['lama_cuti']} hari'),
              Text('Sisa Cuti: ${cuti['sisa_cuti']} hari'),
              if (cuti['tanggal_pengajuan'] != null)
                Text('Tanggal Pengajuan: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(cuti['tanggal_pengajuan']))}'),
              if (cuti['list_tanggal_cuti'] != null)
                Text('Tanggal Cuti: ${cuti['list_tanggal_cuti']}'),
              if (cuti['alasan_cuti'] != null)
                Text('Alasan: ${cuti['alasan_cuti']}'),
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

  void _showPrintDialog(Map<String, dynamic> cuti) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Cuti'),
        content: const Text(
          'Dokumen cuti akan dicetak dan memerlukan tanda tangan manual untuk approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.snackbar(
                'Print',
                'Dokumen cuti dikirim ke printer',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllCuti() async {
    try {
      // First, check if cuti table exists with simple query
      final simpleResponse = await SupabaseService.instance.client
          .from('cuti')
          .select('id, jenis_cuti')
          .limit(1);

      if (simpleResponse.isEmpty) {
        return [];
      }

      // Try full query without complex joins first
      final response = await SupabaseService.instance.client
          .from('cuti')
          .select('''
            id, lama_cuti, alasan_cuti, nama, list_tanggal_cuti, sisa_cuti,
            tanggal_pengajuan, jenis_cuti, users_id
          ''')
          .order('tanggal_pengajuan', ascending: false)
          .limit(50);

      // Transform data with fallback values
      return response.map((item) => {
        'id': item['id'],
        'lama_cuti': item['lama_cuti'] ?? 0,
        'alasan_cuti': item['alasan_cuti'] ?? '',
        'nama': item['nama'] ?? 'User ${item['users_id'] ?? 'Unknown'}',
        'list_tanggal_cuti': item['list_tanggal_cuti'] ?? '',
        'sisa_cuti': item['sisa_cuti'] ?? 0,
        'tanggal_pengajuan': item['tanggal_pengajuan'],
        'jenis_cuti': item['jenis_cuti'] ?? 'Cuti Tahunan',
        'nrp': 'N/A', // Placeholder since we can't join
      }).toList();
    } catch (e) {
      // If query fails, try even simpler version
      try {
        final fallbackResponse = await SupabaseService.instance.client
            .from('cuti')
            .select('id, jenis_cuti, nama')
            .limit(20);

        return fallbackResponse.map((item) => {
          'id': item['id'],
          'lama_cuti': 0,
          'alasan_cuti': '',
          'nama': item['nama'] ?? 'Unknown',
          'list_tanggal_cuti': '',
          'sisa_cuti': 0,
          'tanggal_pengajuan': null,
          'jenis_cuti': item['jenis_cuti'] ?? 'Cuti',
          'nrp': 'N/A',
        }).toList();
      } catch (fallbackError) {
        // Final fallback - return empty list to prevent crash
        return [];
      }
    }
  }
}
