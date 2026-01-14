// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class EditSupervisorPage extends StatefulWidget {
  const EditSupervisorPage({super.key});

  @override
  State<EditSupervisorPage> createState() => _EditSupervisorPageState();
}

class _EditSupervisorPageState extends State<EditSupervisorPage> {
  final _formKey = GlobalKey<FormState>();
  final _supervisorNameController = TextEditingController();
  final _supervisorEmailController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final _supervisorDepartmentController = TextEditingController();

  String? _selectedSupervisorId;
  List<Map<String, dynamic>> _supervisors = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  @override
  void dispose() {
    _supervisorNameController.dispose();
    _supervisorEmailController.dispose();
    _supervisorPhoneController.dispose();
    _supervisorDepartmentController.dispose();
    super.dispose();
  }

  Future<void> _loadSupervisors() async {
    try {
      final response = await SupabaseService.instance.client
          .from('supervisor')
          .select('id, nama, email, telepon, departemen, user_id')
          .order('nama');

      setState(() {
        _supervisors = List<Map<String, dynamic>>.from(response);
        _isInitialLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data supervisor: $e');
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _onSupervisorSelected(String? supervisorId) {
    if (supervisorId == null) {
      _clearForm();
      return;
    }

    final supervisor =
        _supervisors.firstWhere((s) => s['id'].toString() == supervisorId);
    setState(() {
      _selectedSupervisorId = supervisorId;
      _supervisorNameController.text = supervisor['nama'] ?? '';
      _supervisorEmailController.text = supervisor['email'] ?? '';
      _supervisorPhoneController.text = supervisor['telepon'] ?? '';
      _supervisorDepartmentController.text = supervisor['departemen'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedSupervisorId = null;
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
        title: const Text('Edit Supervisor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Data Supervisor',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih supervisor yang ingin diedit dan perbarui datanya',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Supervisor Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Supervisor',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSupervisorId,
                        decoration: const InputDecoration(
                          labelText: 'Cari Supervisor',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        items: _supervisors.map((supervisor) {
                          return DropdownMenuItem<String>(
                            value: supervisor['id'].toString(),
                            child: Text(
                                '${supervisor['nama']} - ${supervisor['departemen']}'),
                          );
                        }).toList(),
                        onChanged: _onSupervisorSelected,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Supervisor harus dipilih';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedSupervisorId != null) ...[
                const SizedBox(height: 16),

                // Edit Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Supervisor Name
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
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Departemen tidak boleh kosong';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Warning
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
                                  'Perubahan data supervisor akan mempengaruhi akses approval untuk bawahannya.',
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
                                  backgroundColor: Colors.purple,
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
      await SupabaseService.instance.client.from('supervisor').update({
        'nama': _supervisorNameController.text.trim(),
        'email': _supervisorEmailController.text.trim(),
        'telepon': _supervisorPhoneController.text.trim(),
        'departemen': _supervisorDepartmentController.text.trim(),
      }).eq('id', _selectedSupervisorId!);

      Get.snackbar(
        'Berhasil',
        'Data supervisor berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh the supervisors list
      await _loadSupervisors();
      // Clear form after successful update
      _clearForm();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui data supervisor: $e',
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
