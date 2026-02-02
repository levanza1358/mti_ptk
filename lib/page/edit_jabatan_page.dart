import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/page_colors.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class EditJabatanPage extends StatefulWidget {
  const EditJabatanPage({super.key});

  @override
  State<EditJabatanPage> createState() => _EditJabatanPageState();
}

class _EditJabatanPageState extends State<EditJabatanPage> {
  final _jabatanNameController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJabatan() async {
    try {
      final response = await SupabaseService.instance.client
          .from('jabatan')
          .select(
              'id, nama, permissionCuti, permissionEksepsi, permissionAllCuti, permissionAllEksepsi, permissionInsentif, permissionAtk, permissionAllInsentif, permissionSuratKeluar, permissionManagementData')
          .order('nama');

      final jabatan = List<Map<String, dynamic>>.from(response);
      jabatan.sort((a, b) {
        final an = (a['nama'] ?? '').toString().toLowerCase();
        final bn = (b['nama'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });

      setState(() {
        _jabatan = jabatan;
        _isInitialLoading = false;
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat data jabatan: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _onJabatanTapped(Map<String, dynamic> jabatan) async {
    FocusScope.of(context).unfocus();
    final jabatanId = (jabatan['id'] ?? '').toString();
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
    await _openEditSheet(jabatanId: jabatanId);
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

  Future<void> _openEditSheet({required String jabatanId}) async {
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Data Jabatan',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 16),
                        const Text(
                          'Permissions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionSection(
                          'Cuti & Eksepsi',
                          [
                            _buildCheckbox(
                              'Akses Menu Cuti',
                              _canApproveLeave,
                              (value) => setModalState(
                                  () => _canApproveLeave = value ?? false),
                            ),
                            _buildCheckbox(
                              'Akses Menu Eksepsi',
                              _canApproveException,
                              (value) => setModalState(
                                  () => _canApproveException = value ?? false),
                            ),
                            _buildCheckbox(
                              'Lihat Semua Data Cuti',
                              _canViewAllLeave,
                              (value) => setModalState(
                                  () => _canViewAllLeave = value ?? false),
                            ),
                            _buildCheckbox(
                              'Lihat Semua Data Eksepsi',
                              _canViewAllException,
                              (value) => setModalState(
                                  () => _canViewAllException = value ?? false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionSection(
                          'Insentif',
                          [
                            _buildCheckbox(
                              'Kelola Data Insentif',
                              _canManageIncentives,
                              (value) => setModalState(
                                  () => _canManageIncentives = value ?? false),
                            ),
                            _buildCheckbox(
                              'Lihat Semua Data Insentif',
                              _canViewAllIncentives,
                              (value) => setModalState(
                                  () => _canViewAllIncentives = value ?? false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionSection(
                          'Administrasi & Sistem',
                          [
                            _buildCheckbox(
                              'Kelola ATK',
                              _canManageATK,
                              (value) => setModalState(
                                  () => _canManageATK = value ?? false),
                            ),
                            _buildCheckbox(
                              'Kelola Surat Keluar',
                              _canManageOutgoingLetters,
                              (value) => setModalState(() =>
                                  _canManageOutgoingLetters = value ?? false),
                            ),
                            _buildCheckbox(
                              'Kelola Data Master (Pegawai/Jabatan)',
                              _canManageData,
                              (value) => setModalState(
                                  () => _canManageData = value ?? false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _submitForm(
                                          jabatanId: jabatanId,
                                          formKey: formKey,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan',
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
        title: const Text('Edit Jabatan'),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Data Jabatan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cari jabatan, lalu tap untuk edit',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari berdasarkan nama jabatan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final q = _searchQuery.toLowerCase().trim();
              final filtered = _jabatan.where((j) {
                final name = (j['nama'] ?? '').toString().toLowerCase();
                if (q.isEmpty) return true;
                return name.contains(q);
              }).toList()
                ..sort((a, b) {
                  final an = (a['nama'] ?? '').toString().toLowerCase();
                  final bn = (b['nama'] ?? '').toString().toLowerCase();
                  return an.compareTo(bn);
                });

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Jabatan tidak ditemukan')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final jabatan = filtered[index];
                    final id = (jabatan['id'] ?? '').toString();
                    final isSelected = id == _selectedJabatanId;
                    final name = (jabatan['nama'] ?? '-').toString();
                    return Material(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _onJabatanTapped(jabatan),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.work, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.tune,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(String title, List<Widget> checkboxes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5)
            : Colors.grey.withValues(alpha: 0.1),
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

  Future<void> _submitForm({
    required String jabatanId,
    required GlobalKey<FormState> formKey,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
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
      };

      await SupabaseService.instance.client
          .from('jabatan')
          .update(updateData)
          .eq('id', jabatanId);

      setState(() {
        final idx = _jabatan.indexWhere((j) => j['id'].toString() == jabatanId);
        if (idx >= 0) {
          _jabatan[idx] = {
            ..._jabatan[idx],
            ...updateData,
          };
          _jabatan.sort((a, b) {
            final an = (a['nama'] ?? '').toString().toLowerCase();
            final bn = (b['nama'] ?? '').toString().toLowerCase();
            return an.compareTo(bn);
          });
        }
      });

      showTopToast(
        'Data jabatan berhasil diperbarui',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _clearForm();
    } catch (e) {
      showTopToast(
        'Gagal memperbarui data jabatan: $e',
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
