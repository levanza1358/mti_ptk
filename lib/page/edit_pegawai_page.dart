import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class EditPegawaiPage extends StatefulWidget {
  const EditPegawaiPage({super.key});

  @override
  State<EditPegawaiPage> createState() => _EditPegawaiPageState();
}

class _EditPegawaiPageState extends State<EditPegawaiPage> {
  final _formKey = GlobalKey<FormState>();
  final _nrpController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedEmployeeId;
  String? _selectedGroup;
  String? _selectedJabatan;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _jabatan = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nrpController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load employees, groups, and jabatan
      final employeesResponse = await SupabaseService.instance.client
          .from('users')
          .select('id, nrp, name, jabatan, "group"')
          .order('name');

      final groupsResponse = await SupabaseService.instance.client
          .from('group')
          .select('id, nama')
          .order('nama');

      final jabatanResponse = await SupabaseService.instance.client
          .from('jabatan')
          .select('id, nama')
          .order('nama');

      setState(() {
        _employees = List<Map<String, dynamic>>.from(employeesResponse);
        _groups = List<Map<String, dynamic>>.from(groupsResponse);
        _jabatan = List<Map<String, dynamic>>.from(jabatanResponse);
        _isInitialLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _onEmployeeSelected(String? employeeId) {
    if (employeeId == null) {
      _clearForm();
      return;
    }

    final employee = _employees.firstWhere((emp) => emp['id'].toString() == employeeId);
    setState(() {
      _selectedEmployeeId = employeeId;
      _nrpController.text = employee['nrp'] ?? '';
      _nameController.text = employee['name'] ?? '';
      _selectedGroup = employee['group']?.toString();
      _selectedJabatan = employee['jabatan']?.toString();
    });
  }

  void _clearForm() {
    setState(() {
      _selectedEmployeeId = null;
      _nrpController.clear();
      _nameController.clear();
      _passwordController.clear();
      _selectedGroup = null;
      _selectedJabatan = null;
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
        title: const Text('Edit Pegawai'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Data Pegawai',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih pegawai yang ingin diedit dan perbarui datanya',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Employee Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Pegawai',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Cari Pegawai',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        items: _employees.map((employee) {
                          return DropdownMenuItem<String>(
                            value: employee['id'].toString(),
                            child: Text('${employee['name']} (${employee['nrp']})'),
                          );
                        }).toList(),
                        onChanged: _onEmployeeSelected,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pegawai harus dipilih';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedEmployeeId != null) ...[
                const SizedBox(height: 16),

                // Edit Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // NRP Field (disabled)
                        TextFormField(
                          controller: _nrpController,
                          decoration: const InputDecoration(
                            labelText: 'NRP',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          enabled: false, // NRP cannot be changed
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field (optional)
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password Baru (Opsional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            hintText: 'Kosongkan jika tidak ingin mengubah password',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),

                        // Group Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGroup,
                          decoration: const InputDecoration(
                            labelText: 'Grup',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: _groups.map((group) {
                            return DropdownMenuItem<String>(
                              value: group['id'].toString(),
                              child: Text(group['nama'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGroup = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Jabatan Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedJabatan,
                          decoration: const InputDecoration(
                            labelText: 'Jabatan',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work),
                          ),
                          items: _jabatan.map((jabatan) {
                            return DropdownMenuItem<String>(
                              value: jabatan['id'].toString(),
                              child: Text(jabatan['nama'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedJabatan = value;
                            });
                          },
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
                                  backgroundColor: Colors.blue,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
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
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'jabatan': _selectedJabatan,
        'group': _selectedGroup,
      };

      // Only update password if provided
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      await SupabaseService.instance.client
          .from('users')
          .update(updateData)
          .eq('id', _selectedEmployeeId!);

      Get.snackbar(
        'Berhasil',
        'Data pegawai berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear form after successful update
      _clearForm();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui data pegawai: $e',
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