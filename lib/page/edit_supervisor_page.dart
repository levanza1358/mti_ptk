// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class EditSupervisorPage extends StatefulWidget {
  const EditSupervisorPage({super.key});

  @override
  State<EditSupervisorPage> createState() => _EditSupervisorPageState();
}

class _EditSupervisorPageState extends State<EditSupervisorPage> {
  final _supervisorNameController = TextEditingController();
  final _supervisorJabatanController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedJenis;

  String? _selectedSupervisorId;
  List<Map<String, dynamic>> _supervisors = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  static const List<String> _jenisOptions = [
    'Penunjang',
    'Logistik',
    'Manager_PDS',
  ];

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  @override
  void dispose() {
    _supervisorNameController.dispose();
    _supervisorJabatanController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSupervisors() async {
    try {
      final response = await SupabaseService.instance.client
          .from('supervisor')
          .select('id, nama, jabatan, jenis')
          .order('nama');

      final supervisors = List<Map<String, dynamic>>.from(response);
      supervisors.sort((a, b) {
        final an = (a['nama'] ?? '').toString().toLowerCase();
        final bn = (b['nama'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });

      setState(() {
        _supervisors = supervisors;
        _isInitialLoading = false;
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat data supervisor: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _onSupervisorTapped(Map<String, dynamic> supervisor) async {
    FocusScope.of(context).unfocus();
    final supervisorId = (supervisor['id'] ?? '').toString();
    setState(() {
      _selectedSupervisorId = supervisorId;
      _supervisorNameController.text = supervisor['nama'] ?? '';
      _supervisorJabatanController.text = supervisor['jabatan'] ?? '';
      _selectedJenis = supervisor['jenis']?.toString();
    });
    await _openEditSheet(supervisorId: supervisorId);
  }

  void _clearForm() {
    setState(() {
      _selectedSupervisorId = null;
      _supervisorNameController.clear();
      _supervisorJabatanController.clear();
      _selectedJenis = null;
    });
  }

  Future<void> _openEditSheet({required String supervisorId}) async {
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
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
                      'Edit Data Supervisor',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _supervisorJabatanController,
                      decoration: const InputDecoration(
                        labelText: 'Jabatan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jabatan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedJenis,
                      decoration: const InputDecoration(
                        labelText: 'Jenis',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _jenisOptions
                          .map((j) => DropdownMenuItem<String>(
                                value: j,
                                child: Text(j),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedJenis = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jenis tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
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
                                      supervisorId: supervisorId,
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Data Supervisor',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cari supervisor, lalu tap untuk edit',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari berdasarkan nama/jabatan/jenis',
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
              final filtered = _supervisors.where((s) {
                final name = (s['nama'] ?? '').toString().toLowerCase();
                final jabatan = (s['jabatan'] ?? '').toString().toLowerCase();
                final jenis = (s['jenis'] ?? '').toString().toLowerCase();
                if (q.isEmpty) return true;
                return name.contains(q) ||
                    jabatan.contains(q) ||
                    jenis.contains(q);
              }).toList()
                ..sort((a, b) {
                  final an = (a['nama'] ?? '').toString().toLowerCase();
                  final bn = (b['nama'] ?? '').toString().toLowerCase();
                  return an.compareTo(bn);
                });

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Supervisor tidak ditemukan')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final supervisor = filtered[index];
                    final id = (supervisor['id'] ?? '').toString();
                    final isSelected = id == _selectedSupervisorId;
                    final name = (supervisor['nama'] ?? '-').toString();
                    final jabatan = (supervisor['jabatan'] ?? '-').toString();
                    final jenis = (supervisor['jenis'] ?? '-').toString();
                    return Material(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _onSupervisorTapped(supervisor),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.supervisor_account, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$jabatan • $jenis',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
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

  Future<void> _submitForm({
    required String supervisorId,
    required GlobalKey<FormState> formKey,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supervisorIdInt = int.tryParse(supervisorId);
      final updateData = {
        'nama': _supervisorNameController.text.trim(),
        'jabatan': _supervisorJabatanController.text.trim(),
        'jenis': _selectedJenis,
      };

      final query =
          SupabaseService.instance.client.from('supervisor').update(updateData);
      if (supervisorIdInt != null) {
        await query.eq('id', supervisorIdInt);
      } else {
        await query.eq('id', supervisorId);
      }

      setState(() {
        final idx =
            _supervisors.indexWhere((s) => s['id'].toString() == supervisorId);
        if (idx >= 0) {
          _supervisors[idx] = {
            ..._supervisors[idx],
            ...updateData,
          };
          _supervisors.sort((a, b) {
            final an = (a['nama'] ?? '').toString().toLowerCase();
            final bn = (b['nama'] ?? '').toString().toLowerCase();
            return an.compareTo(bn);
          });
        }
      });

      showTopToast(
        'Data supervisor berhasil diperbarui',
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
        'Gagal memperbarui data supervisor: $e',
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
