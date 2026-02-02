// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/page_colors.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
        title: const Text('Tambah Jabatan'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark
                    ? PageColors.dataManagementDark
                    : PageColors.dataManagementLight,
                (isDark
                        ? PageColors.dataManagementDark
                        : PageColors.dataManagementLight)
                    .withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                            'Akses Menu Cuti',
                            _canApproveLeave,
                            (value) => setState(
                                () => _canApproveLeave = value ?? false),
                          ),
                          _buildCheckbox(
                            'Akses Menu Eksepsi',
                            _canApproveException,
                            (value) => setState(
                                () => _canApproveException = value ?? false),
                          ),
                          _buildCheckbox(
                            'Lihat Semua Data Cuti',
                            _canViewAllLeave,
                            (value) => setState(
                                () => _canViewAllLeave = value ?? false),
                          ),
                          _buildCheckbox(
                            'Lihat Semua Data Eksepsi',
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
                            'Kelola Data Insentif',
                            _canManageIncentives,
                            (value) => setState(
                                () => _canManageIncentives = value ?? false),
                          ),
                          _buildCheckbox(
                            'Lihat Semua Data Insentif',
                            _canViewAllIncentives,
                            (value) => setState(
                                () => _canViewAllIncentives = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Other Permissions
                      _buildPermissionSection(
                        'Administrasi & Sistem',
                        [
                          _buildCheckbox(
                            'Kelola ATK',
                            _canManageATK,
                            (value) =>
                                setState(() => _canManageATK = value ?? false),
                          ),
                          _buildCheckbox(
                            'Kelola Surat Keluar',
                            _canManageOutgoingLetters,
                            (value) => setState(() =>
                                _canManageOutgoingLetters = value ?? false),
                          ),
                          _buildCheckbox(
                            'Kelola Data Master (Pegawai/Jabatan)',
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
                              borderRadius: BorderRadius.circular(12),
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

      showTopToast(
        'Jabatan berhasil ditambahkan',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
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
      showTopToast(
        'Gagal menambah jabatan: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
