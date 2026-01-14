// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class TambahJabatanPage extends StatefulWidget {
  const TambahJabatanPage({super.key});

  @override
  State<TambahJabatanPage> createState() => _TambahJabatanPageState();
}

class _TambahJabatanPageState extends State<TambahJabatanPage> {
  final _formKey = GlobalKey<FormState>();
  final _jabatanNameController = TextEditingController();

  // Permissions checkboxes
  bool _canApproveLeave = false;
  bool _canApproveException = false;
  bool _canViewAllLeave = false;
  bool _canViewAllException = false;
  bool _canManageIncentives = false;
  bool _canManageATK = false;
  bool _canViewAllIncentives = false;
  bool _canManageOutgoingLetters = false;
  bool _canManageData = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _jabatanNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
        title: const Text('Tambah Jabatan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Jabatan Baru',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Buat jabatan baru dengan permission yang sesuai',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Jabatan Name
                      TextFormField(
                        controller: _jabatanNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Jabatan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                          hintText: 'Contoh: Manager, Staff, Supervisor',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama jabatan tidak boleh kosong';
                          }
                          if (value.length < 2) {
                            return 'Nama jabatan minimal 2 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Permissions Section
                      const Text(
                        'Permissions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Leave Permissions
                      _buildPermissionSection(
                        'Cuti & Eksepsi',
                        [
                          _buildCheckbox(
                            'Bisa approve cuti',
                            _canApproveLeave,
                            (value) => setState(
                                () => _canApproveLeave = value ?? false),
                          ),
                          _buildCheckbox(
                            'Bisa approve eksepsi',
                            _canApproveException,
                            (value) => setState(
                                () => _canApproveException = value ?? false),
                          ),
                          _buildCheckbox(
                            'Bisa lihat semua cuti',
                            _canViewAllLeave,
                            (value) => setState(
                                () => _canViewAllLeave = value ?? false),
                          ),
                          _buildCheckbox(
                            'Bisa lihat semua eksepsi',
                            _canViewAllException,
                            (value) => setState(
                                () => _canViewAllException = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Incentive Permissions
                      _buildPermissionSection(
                        'Insentif',
                        [
                          _buildCheckbox(
                            'Bisa kelola insentif',
                            _canManageIncentives,
                            (value) => setState(
                                () => _canManageIncentives = value ?? false),
                          ),
                          _buildCheckbox(
                            'Bisa lihat semua insentif',
                            _canViewAllIncentives,
                            (value) => setState(
                                () => _canViewAllIncentives = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Other Permissions
                      _buildPermissionSection(
                        'Lainnya',
                        [
                          _buildCheckbox(
                            'Bisa kelola ATK',
                            _canManageATK,
                            (value) =>
                                setState(() => _canManageATK = value ?? false),
                          ),
                          _buildCheckbox(
                            'Bisa kelola surat keluar',
                            _canManageOutgoingLetters,
                            (value) => setState(() =>
                                _canManageOutgoingLetters = value ?? false),
                          ),
                          _buildCheckbox(
                            'Bisa kelola data sistem',
                            _canManageData,
                            (value) =>
                                setState(() => _canManageData = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Tambah Jabatan',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSection(String title, List<Widget> checkboxes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...checkboxes,
        ],
      ),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
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
      await SupabaseService.instance.client.from('jabatan').insert({
        'nama': _jabatanNameController.text.trim(),
        'permissionCuti': _canApproveLeave,
        'permissionEksepsi': _canApproveException,
        'permissionAllCuti': _canViewAllLeave,
        'permissionAllEksepsi': _canViewAllException,
        'permissionInsentif': _canManageIncentives,
        'permissionAtk': _canManageATK,
        'permissionAllInsentif': _canViewAllIncentives,
        'permissionSuratKeluar': _canManageOutgoingLetters,
        'permissionManagementData': _canManageData,
      });

      Get.snackbar(
        'Berhasil',
        'Jabatan berhasil ditambahkan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear form
      _jabatanNameController.clear();
      setState(() {
        _canApproveLeave = false;
        _canApproveException = false;
        _canViewAllLeave = false;
        _canViewAllException = false;
        _canManageIncentives = false;
        _canManageATK = false;
        _canViewAllIncentives = false;
        _canManageOutgoingLetters = false;
        _canManageData = false;
      });

      Get.back(); // Go back to previous page
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menambah jabatan: $e',
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
