// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class EditGroupPage extends StatefulWidget {
  const EditGroupPage({super.key});

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();

  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final response = await SupabaseService.instance.client
          .from('group')
          .select('id, nama')
          .order('nama');

      setState(() {
        _groups = List<Map<String, dynamic>>.from(response);
        _isInitialLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data grup: $e');
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _onGroupSelected(String? groupId) {
    if (groupId == null) {
      _clearForm();
      return;
    }

    final group = _groups.firstWhere((g) => g['id'].toString() == groupId);
    setState(() {
      _selectedGroupId = groupId;
      _groupNameController.text = group['nama'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedGroupId = null;
      _groupNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
        title: const Text('Edit Grup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Data Grup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih grup yang ingin diedit dan perbarui namanya',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Group Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Grup',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Cari Grup',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        items: _groups.map((group) {
                          return DropdownMenuItem<String>(
                            value: group['id'].toString(),
                            child: Text(group['nama'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: _onGroupSelected,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Grup harus dipilih';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedGroupId != null) ...[
                const SizedBox(height: 16),

                // Edit Form
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
                            prefixIcon: Icon(Icons.group),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama grup tidak boleh kosong';
                            }
                            if (value.length < 2) {
                              return 'Nama grup minimal 2 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Perubahan nama grup akan mempengaruhi semua pengguna yang terkait dengan grup ini.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearForm,
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(color: Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.instance.client
          .from('group')
          .update({'nama': _groupNameController.text.trim()}).eq(
              'id', _selectedGroupId!);

      Get.snackbar(
        'Berhasil',
        'Nama grup berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh the groups list
      await _loadGroups();
      // Clear form after successful update
      _clearForm();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui nama grup: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
