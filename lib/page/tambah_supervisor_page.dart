// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class TambahSupervisorPage extends StatefulWidget {
  const TambahSupervisorPage({super.key});

  @override
  State<TambahSupervisorPage> createState() => _TambahSupervisorPageState();
}

class _TambahSupervisorPageState extends State<TambahSupervisorPage> {
  final _formKey = GlobalKey<FormState>();
  final _supervisorNameController = TextEditingController();
  final _supervisorEmailController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final _supervisorDepartmentController = TextEditingController();

  String? _selectedEmployeeId;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _supervisorNameController.dispose();
    _supervisorEmailController.dispose();
    _supervisorPhoneController.dispose();
    _supervisorDepartmentController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await SupabaseService.instance.client
          .from('users')
          .select('id, nrp, name, jabatan')
          .order('name');

      setState(() {
        _employees = List<Map<String, dynamic>>.from(response);
        _isInitialLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data pegawai: $e');
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

    final employee =
        _employees.firstWhere((emp) => emp['id'].toString() == employeeId);
    setState(() {
      _selectedEmployeeId = employeeId;
      _supervisorNameController.text = employee['name'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedEmployeeId = null;
      _supervisorNameController.clear();
      _supervisorEmailController.clear();
      _supervisorPhoneController.clear();
      _supervisorDepartmentController.clear();
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
        title: const Text('Tambah Supervisor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Supervisor Baru',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih pegawai yang akan dijadikan supervisor dan lengkapi datanya',
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Cari Pegawai',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        items: _employees.map((employee) {
                          return DropdownMenuItem<String>(
                            value: employee['id'].toString(),
                            child: Text(
                                '${employee['name']} (NRP: ${employee['nrp']})'),
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

                // Supervisor Details Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Supervisor Name (auto-filled)
                        TextFormField(
                          controller: _supervisorNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Supervisor',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama supervisor tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _supervisorEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!value.contains('@')) {
                              return 'Email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _supervisorPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor telepon tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Department
                        TextFormField(
                          controller: _supervisorDepartmentController,
                          decoration: const InputDecoration(
                            labelText: 'Departemen',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                            hintText: 'Contoh: HR, IT, Finance',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Departemen tidak boleh kosong';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Info Card
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
                                  'Supervisor akan memiliki akses untuk approve permintaan cuti dan eksepsi dari bawahannya.',
                                  style: TextStyle(color: Colors.blue),
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
                                  backgroundColor: Colors.purple,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        'Tambah Supervisor',
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
      await SupabaseService.instance.client.from('supervisor').insert({
        'user_id': _selectedEmployeeId,
        'nama': _supervisorNameController.text.trim(),
        'email': _supervisorEmailController.text.trim(),
        'telepon': _supervisorPhoneController.text.trim(),
        'departemen': _supervisorDepartmentController.text.trim(),
      });

      Get.snackbar(
        'Berhasil',
        'Supervisor berhasil ditambahkan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear form
      _clearForm();
      Get.back(); // Go back to previous page
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menambah supervisor: $e',
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
