import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/supabase_service.dart';

class InsentifPage extends StatefulWidget {
  const InsentifPage({super.key});

  @override
  State<InsentifPage> createState() => _InsentifPageState();
}

class _InsentifPageState extends State<InsentifPage> with TickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: const Text('Insentif'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lembur'),
            Tab(text: 'Premi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InsentifLemburTab(tabController: _tabController),
          InsentifPremiTab(tabController: _tabController),
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
      future: _fetchInsentifLembur(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final lembur = snapshot.data ?? [];
        if (lembur.isEmpty) {
          return const Center(child: Text('Belum ada data insentif lembur'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: lembur.length,
          itemBuilder: (context, index) {
            final item = lembur[index];
            return Card(
              child: ListTile(
                title: Text(item['nama'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NRP: ${item['nrp']}'),
                    Text('Bulan: ${_formatDate(item['bulan'])}'),
                  ],
                ),
                trailing: Text(
                  'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(item['nominal'] ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
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
                    subtitle: Text(DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate)),
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
      Get.snackbar('Error', 'Harap isi semua field');
      return;
    }

    final nominal = int.tryParse(_nominalController.text.replaceAll('.', ''));
    if (nominal == null) {
      Get.snackbar('Error', 'Nominal harus berupa angka');
      return;
    }

    // Here you would submit to Supabase
    Get.snackbar('Success', 'Insentif lembur berhasil ditambahkan');
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

  Future<List<Map<String, dynamic>>> _fetchInsentifLembur() async {
    try {
      final response = await SupabaseService.instance.client
          .from('insentif_lembur')
          .select('nama, nrp, nominal, bulan, tahun')
          .order('tahun', ascending: false)
          .order('bulan', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
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
      future: _fetchInsentifPremi(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final premi = snapshot.data ?? [];
        if (premi.isEmpty) {
          return const Center(child: Text('Belum ada data insentif premi'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: premi.length,
          itemBuilder: (context, index) {
            final item = premi[index];
            return Card(
              child: ListTile(
                title: Text(item['nama'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NRP: ${item['nrp']}'),
                    Text('Bulan: ${_formatDate(item['bulan'])}'),
                  ],
                ),
                trailing: Text(
                  'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(item['nominal'] ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
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
                    subtitle: Text(DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate)),
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
      Get.snackbar('Error', 'Harap isi semua field');
      return;
    }

    final nominal = int.tryParse(_nominalController.text.replaceAll('.', ''));
    if (nominal == null) {
      Get.snackbar('Error', 'Nominal harus berupa angka');
      return;
    }

    // Here you would submit to Supabase
    Get.snackbar('Success', 'Insentif premi berhasil ditambahkan');
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

  Future<List<Map<String, dynamic>>> _fetchInsentifPremi() async {
    try {
      final response = await SupabaseService.instance.client
          .from('insentif_premi')
          .select('nama, nrp, nominal, bulan, tahun')
          .order('tahun', ascending: false)
          .order('bulan', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to fetch premi incentives: $e';
    }
  }
}
