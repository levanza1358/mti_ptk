import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class EditJabatanPage extends StatefulWidget {
  const EditJabatanPage({super.key});

  @override
  State<EditJabatanPage> createState() => _EditJabatanPageState();
}

class _EditJabatanPageState extends State<EditJabatanPage> {
  final _formKey = GlobalKey<FormState>();
  final _jabatanNameController = TextEditingController();

  String? _selectedJabatanId;
  List<Map<String, dynamic>> _jabatan = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  // Permissions
  bool _canApproveLeave = false;
  bool _canApproveException = false;
  bool _canViewAllLeave = false;
  bool _canViewAllException = false;
  bool _canManageIncentives = false;
  bool _canManageATK = false;
  bool _canViewAllIncentives = false;
  bool _canManageOutgoingLetters = false;
  bool _canManageData = false;

  @override
  void initState() {
    super.initState();
    _loadJabatan();
  }

  @override
  void dispose() {
    _jabatanNameController.dispose();
    super.dispose();
  }

  Future<void> _loadJabatan() async {
    try {
      final response = await SupabaseService.instance.client
          .from('jabatan')
          .select('id, nama, permissionCuti, permissionEksepsi, permissionAllCuti, permissionAllEksepsi, permissionInsentif, permissionAtk, permissionAllInsentif, permissionSuratKeluar, permissionManagementData')
          .order('nama');

      setState(() {
        _jabatan = List<Map<String, dynamic>>.from(response);
        _isInitialLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data jabatan: $e');
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _onJabatanSelected(String? jabatanId) {
    if (jabatanId == null) {
      _clearForm();
      return;
    }

    final jabatan = _jabatan.firstWhere((j) => j['id'].toString() == jabatanId);
    setState(() {
      _selectedJabatanId = jabatanId;
      _jabatanNameController.text = jabatan['nama'] ?? '';
      _canApproveLeave = jabatan['permissionCuti'] ?? false;
      _canApproveException = jabatan['permissionEksepsi'] ?? false;
      _canViewAllLeave = jabatan['permissionAllCuti'] ?? false;
      _canViewAllException = jabatan['permissionAllEksepsi'] ?? false;
      _canManageIncentives = jabatan['permissionInsentif'] ?? false;
      _canManageATK = jabatan['permissionAtk'] ?? false;
      _canViewAllIncentives = jabatan['permissionAllInsentif'] ?? false;
      _canManageOutgoingLetters = jabatan['permissionSuratKeluar'] ?? false;
      _canManageData = jabatan['permissionManagementData'] ?? false;
    });
  }

  void _clearForm() {
    setState(() {
      _selectedJabatanId = null;
      _jabatanNameController.clear();
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
        title: const Text('Edit Jabatan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Data Jabatan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih jabatan yang ingin diedit dan perbarui datanya',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Jabatan Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Jabatan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedJabatanId,
                        decoration: const InputDecoration(
                          labelText: 'Cari Jabatan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        items: _jabatan.map((jabatan) {
                          return DropdownMenuItem<String>(
                            value: jabatan['id'].toString(),
                            child: Text(jabatan['nama'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: _onJabatanSelected,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jabatan harus dipilih';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedJabatanId != null) ...[
                const SizedBox(height: 16),

                // Edit Form
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Leave Permissions
                        _buildPermissionSection(
                          'Cuti & Eksepsi',
                          [
                            _buildCheckbox(
                              'Bisa approve cuti',
                              _canApproveLeave,
                              (value) => setState(() => _canApproveLeave = value ?? false),
                            ),
                            _buildCheckbox(
                              'Bisa approve eksepsi',
                              _canApproveException,
                              (value) => setState(() => _canApproveException = value ?? false),
                            ),
                            _buildCheckbox(
                              'Bisa lihat semua cuti',
                              _canViewAllLeave,
                              (value) => setState(() => _canViewAllLeave = value ?? false),
                            ),
                            _buildCheckbox(
                              'Bisa lihat semua eksepsi',
                              _canViewAllException,
                              (value) => setState(() => _canViewAllException = value ?? false),
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
                              (value) => setState(() => _canManageIncentives = value ?? false),
                            ),
                            _buildCheckbox(
                              'Bisa lihat semua insentif',
                              _canViewAllIncentives,
                              (value) => setState(() => _canViewAllIncentives = value ?? false),
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
                              (value) => setState(() => _canManageATK = value ?? false),
                            ),
                            _buildCheckbox(
                              'Bisa kelola surat keluar',
                              _canManageOutgoingLetters,
                              (value) => setState(() => _canManageOutgoingLetters = value ?? false),
                            ),
                            _buildCheckbox(
                              'Bisa kelola data sistem',
                              _canManageData,
                              (value) => setState(() => _canManageData = value ?? false),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Warning
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Perubahan permissions akan mempengaruhi semua pengguna dengan jabatan ini.',
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
                                  backgroundColor: Colors.orange,
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

  Widget _buildPermissionSection(String title, List<Widget> checkboxes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
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

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
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
      await SupabaseService.instance.client
          .from('jabatan')
          .update({
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
          })
          .eq('id', _selectedJabatanId!);

      Get.snackbar(
        'Berhasil',
        'Data jabatan berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh the jabatan list
      await _loadJabatan();
      // Clear form after successful update
      _clearForm();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui data jabatan: $e',
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