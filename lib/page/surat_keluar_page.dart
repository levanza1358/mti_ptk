import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/supabase_service.dart';

class SuratKeluarPage extends StatefulWidget {
  const SuratKeluarPage({super.key});

  @override
  State<SuratKeluarPage> createState() => _SuratKeluarPageState();
}

class _SuratKeluarPageState extends State<SuratKeluarPage> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _letterTitleController = TextEditingController();
  final TextEditingController _letterNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _showForm = false;

  @override
  void dispose() {
    _companyController.dispose();
    _letterTitleController.dispose();
    _letterNumberController.dispose();
    _descriptionController.dispose();
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
        title: const Text('Surat Keluar'),
      ),
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
      future: _fetchOutgoingLetters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final letters = snapshot.data ?? [];
        if (letters.isEmpty) {
          return const Center(child: Text('Belum ada data surat keluar'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: letters.length,
          itemBuilder: (context, index) {
            final letter = letters[index];
            return Card(
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
                            letter['judul_surat'] ?? 'Tanpa Judul',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          letter['nomor_surat'] ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kepada: ${letter['nama_perusahaan'] ?? '-'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deskripsi: ${letter['deskripsi_surat'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // View/download PDF functionality
                            Get.snackbar('Info', 'Fitur lihat PDF akan segera hadir');
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Lihat PDF'),
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

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Surat Keluar Baru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama perusahaan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _letterTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Surat',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul surat tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _letterNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Surat',
                      border: OutlineInputBorder(),
                      hintText: 'Contoh: 001/SK/MTI-PTK/2024',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Surat',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan deskripsi atau isi surat...',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi surat tidak boleh kosong';
                      }
                      return null;
                    },
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
                          onPressed: _submitLetter,
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

  void _submitLetter() {
    if (_companyController.text.isEmpty ||
        _letterTitleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      Get.snackbar('Error', 'Harap isi semua field yang wajib');
      return;
    }

    // Here you would submit to Supabase
    Get.snackbar('Success', 'Surat keluar berhasil ditambahkan');
    setState(() {
      _showForm = false;
      _clearForm();
    });
  }

  void _clearForm() {
    _companyController.clear();
    _letterTitleController.clear();
    _letterNumberController.clear();
    _descriptionController.clear();
  }

  Future<List<Map<String, dynamic>>> _fetchOutgoingLetters() async {
    try {
      final response = await SupabaseService.instance.client
          .from('surat_keluar')
          .select('nama_perusahaan, judul_surat, nomor_surat, deskripsi_surat, created_at')
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to fetch outgoing letters: $e';
    }
  }
}