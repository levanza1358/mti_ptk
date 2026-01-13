import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class SemuaDataEksepsiPage extends StatefulWidget {
  const SemuaDataEksepsiPage({super.key});

  @override
  State<SemuaDataEksepsiPage> createState() => _SemuaDataEksepsiPageState();
}

class _SemuaDataEksepsiPageState extends State<SemuaDataEksepsiPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        title: const Text('Semua Data Eksepsi'),
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
              ],
            ),
          ),

          // Data List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllEksepsi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final eksepsi = snapshot.data ?? [];

                // Apply filters
                final filteredEksepsi = eksepsi.where((item) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      (item['nama']?.toLowerCase().contains(_searchQuery) == true) ||
                      (item['nrp']?.toLowerCase().contains(_searchQuery) == true);

                  return matchesSearch;
                }).toList();

                if (filteredEksepsi.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada data eksepsi',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  key: const PageStorageKey('eksepsi_list'),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredEksepsi.length,
                  itemBuilder: (context, index) {
                    final item = filteredEksepsi[index];
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'NRP: ${item['nrp'] ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Jenis: ${item['jenis_eksepsi'] ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Tanggal Pengajuan: ${item['tanggal_pengajuan'] != null ? DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(item['tanggal_pengajuan'])) : '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (item['total_hari'] != null) ...[
                              Text(
                                'Total Hari: ${item['total_hari']}',
                                style: const TextStyle(fontSize: 14),
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
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showPrintDialog(item),
                                  icon: const Icon(Icons.print),
                                  label: const Text('Print'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
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



  void _showDetailDialog(Map<String, dynamic> eksepsi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Eksepsi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${eksepsi['nama']}'),
              Text('NRP: ${eksepsi['nrp']}'),
              Text('Jenis: ${eksepsi['jenis_eksepsi']}'),
              if (eksepsi['tanggal_pengajuan'] != null)
                Text('Tanggal Pengajuan: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(eksepsi['tanggal_pengajuan']))}'),
              const SizedBox(height: 16),
              const Text('Tanggal Eksepsi:', style: TextStyle(fontWeight: FontWeight.bold)),
              // Here you would load and display eksepsi_tanggal data
              const Text('(Detail tanggal akan dimuat...)'),
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

  void _showPrintDialog(Map<String, dynamic> eksepsi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Eksepsi'),
        content: const Text(
          'Dokumen eksepsi akan dicetak dan memerlukan tanda tangan manual untuk approval.',
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
                'Dokumen eksepsi dikirim ke printer',
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

  Future<List<Map<String, dynamic>>> _fetchAllEksepsi() async {
    try {
      // First, check if eksepsi table exists with simple query
      final simpleResponse = await SupabaseService.instance.client
          .from('eksepsi')
          .select('id')
          .limit(1);

      if (simpleResponse.isEmpty) {
        return [];
      }

      // Try full query without complex joins first
      final response = await SupabaseService.instance.client
          .from('eksepsi')
          .select('''
            id, user_id, jenis_eksepsi, tanggal_pengajuan
          ''')
          .order('tanggal_pengajuan', ascending: false)
          .limit(50);

      // Transform data with fallback values
      return response.map((item) => {
        'id': item['id'],
        'user_id': item['user_id'],
        'jenis_eksepsi': item['jenis_eksepsi'] ?? 'Eksepsi',
        'tanggal_pengajuan': item['tanggal_pengajuan'],
        'nrp': 'N/A', // Placeholder since we can't join
        'nama': 'User ${item['user_id'] ?? 'Unknown'}',
      }).toList();
    } catch (e) {
      // If query fails, try even simpler version
      try {
        final fallbackResponse = await SupabaseService.instance.client
            .from('eksepsi')
            .select('id, jenis_eksepsi')
            .limit(20);

        return fallbackResponse.map((item) => {
          'id': item['id'],
          'user_id': null,
          'jenis_eksepsi': item['jenis_eksepsi'] ?? 'Eksepsi',
          'tanggal_pengajuan': null,
          'nrp': 'N/A',
          'nama': 'Unknown User',
        }).toList();
      } catch (fallbackError) {
        // Final fallback - return empty list to prevent crash
        return [];
      }
    }
  }
}