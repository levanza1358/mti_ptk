// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final TextEditingController _groupNameController = TextEditingController();

  bool _showForm = false;

  @override
  void dispose() {
    _groupNameController.dispose();
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
        title: const Text('Manajemen Grup'),
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
      future: _fetchGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return const Center(child: Text('Belum ada data grup'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    (group['nama'] ?? 'G')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  group['nama'] ?? 'Tanpa Nama',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('ID Grup: ${group['id']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editGroup(group);
                    } else if (value == 'delete') {
                      _deleteGroup(group);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus'),
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
            'Tambah Grup Baru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Grup',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan nama grup baru',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama grup tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Grup digunakan untuk mengorganisir pengguna berdasarkan divisi atau tim kerja.',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
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
                          onPressed: _submitGroup,
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

  void _submitGroup() {
    if (_groupNameController.text.isEmpty) {
      Get.snackbar('Error', 'Nama grup tidak boleh kosong');
      return;
    }

    // Here you would submit to Supabase
    Get.snackbar('Success', 'Grup berhasil ditambahkan');
    setState(() {
      _showForm = false;
      _clearForm();
    });
  }

  void _editGroup(Map<String, dynamic> group) {
    _groupNameController.text = group['nama'] ?? '';
    setState(() {
      _showForm = true;
    });
    // In a real implementation, you'd track if this is an edit vs new
    Get.snackbar('Info', 'Fitur edit grup akan segera hadir');
  }

  void _deleteGroup(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content:
            Text('Apakah Anda yakin ingin menghapus grup "${group['nama']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would delete from Supabase
              Get.snackbar('Success', 'Grup berhasil dihapus');
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _groupNameController.clear();
  }

  Future<List<Map<String, dynamic>>> _fetchGroups() async {
    try {
      final response = await SupabaseService.instance.client
          .from('group')
          .select('id, nama, created_at')
          .order('nama');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to fetch groups: $e';
    }
  }
}
