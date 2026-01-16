import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class EditPegawaiPage extends StatefulWidget {
  const EditPegawaiPage({super.key});

  @override
  State<EditPegawaiPage> createState() => _EditPegawaiPageState();
}

class _EditPegawaiPageState extends State<EditPegawaiPage> {
  final _nrpController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedEmployeeId;
  String? _selectedGroup;
  String? _selectedJabatan;
  String? _phoneColumn;
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
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchEmployeesWithOptionalPhone() async {
    const baseColumns = 'id, nrp, name, jabatan, "group"';
    const phoneCandidates = <String>[
      'kontak',
      'telepon',
      'no_hp',
      'nomor_hp',
      'phone',
    ];

    for (final col in phoneCandidates) {
      try {
        final resp = await SupabaseService.instance.client
            .from('users')
            .select('$baseColumns, $col')
            .order('name');
        _phoneColumn = col;
        return List<Map<String, dynamic>>.from(resp);
      } catch (_) {}
    }

    _phoneColumn = null;
    final resp = await SupabaseService.instance.client
        .from('users')
        .select(baseColumns)
        .order('name');
    return List<Map<String, dynamic>>.from(resp);
  }

  Future<void> _loadInitialData() async {
    try {
      // Load employees, groups, and jabatan
      final employeesResponse = await _fetchEmployeesWithOptionalPhone();

      final groupsResponse = await SupabaseService.instance.client
          .from('group')
          .select('id, nama')
          .order('nama');

      final jabatanResponse = await SupabaseService.instance.client
          .from('jabatan')
          .select('id, nama')
          .order('nama');

      final employees = List<Map<String, dynamic>>.from(employeesResponse);
      employees.sort((a, b) {
        final an = (a['name'] ?? '').toString().toLowerCase();
        final bn = (b['name'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });

      setState(() {
        _employees = employees;
        _groups = List<Map<String, dynamic>>.from(groupsResponse);
        _jabatan = List<Map<String, dynamic>>.from(jabatanResponse);
        _isInitialLoading = false;
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat data: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  String? _normalizeIdFromList({
    required dynamic rawValue,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String labelKey,
  }) {
    final raw = (rawValue ?? '').toString().trim();
    if (raw.isEmpty) return null;

    for (final item in items) {
      if (item[idKey]?.toString() == raw) {
        return raw;
      }
    }

    for (final item in items) {
      final label = (item[labelKey] ?? '').toString().trim();
      if (label.isNotEmpty && label.toLowerCase() == raw.toLowerCase()) {
        return item[idKey]?.toString();
      }
    }

    return null;
  }

  void _onEmployeeTapped(Map<String, dynamic> employee) {
    FocusScope.of(context).unfocus();
    final selectedId = (employee['id'] ?? '').toString();
    final normalizedGroup = _normalizeIdFromList(
      rawValue: employee['group'],
      items: _groups,
      idKey: 'id',
      labelKey: 'nama',
    );
    final normalizedJabatan = _normalizeIdFromList(
      rawValue: employee['jabatan'],
      items: _jabatan,
      idKey: 'id',
      labelKey: 'nama',
    );
    final phoneValue = _phoneColumn == null
        ? null
        : (employee[_phoneColumn] ?? employee[_phoneColumn!])?.toString();
    setState(() {
      _selectedEmployeeId = selectedId;
      _nrpController.text = employee['nrp'] ?? '';
      _nameController.text = employee['name'] ?? '';
      _passwordController.clear();
      _phoneController.text = phoneValue ?? '';
      _selectedGroup = normalizedGroup;
      _selectedJabatan = normalizedJabatan;
    });
    _openEditSheet(employeeId: selectedId);
  }

  void _clearForm() {
    setState(() {
      _selectedEmployeeId = null;
      _nrpController.clear();
      _nameController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _selectedGroup = null;
      _selectedJabatan = null;
    });
  }

  String _resolveGroupLabel(dynamic groupId) {
    final id = (groupId ?? '').toString();
    if (id.isEmpty) return '-';
    for (final g in _groups) {
      if (g['id']?.toString() == id) {
        return (g['nama'] ?? id).toString();
      }
    }
    return id;
  }

  String _resolveJabatanLabel(dynamic jabatanId) {
    final id = (jabatanId ?? '').toString();
    if (id.isEmpty) return '-';
    for (final j in _jabatan) {
      if (j['id']?.toString() == id) {
        return (j['nama'] ?? id).toString();
      }
    }
    return id;
  }

  Future<void> _openEditSheet({required String employeeId}) async {
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
                      'Edit Data Pegawai',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nrpController,
                      decoration: const InputDecoration(
                        labelText: 'NRP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password Baru (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        hintText:
                            'Kosongkan jika tidak ingin mengubah password',
                      ),
                      obscureText: true,
                    ),
                    if (_phoneColumn != null) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP / WA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 12),
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
                        _selectedGroup = value;
                      },
                    ),
                    const SizedBox(height: 12),
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
                        _selectedJabatan = value;
                      },
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
                                      employeeId: employeeId,
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

    final filteredEmployees = _employees.where((employee) {
      final name = (employee['name'] ?? '').toString().toLowerCase();
      final nrp = (employee['nrp'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return name.contains(q) || nrp.contains(q);
    }).toList();

    filteredEmployees.sort((a, b) {
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
        title: const Text('Edit Pegawai'),
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
                    'Edit Data Pegawai',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cari pegawai berdasarkan nama, lalu tap untuk edit',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari berdasarkan nama',
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
          if (filteredEmployees.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Pegawai tidak ditemukan')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              sliver: SliverList.separated(
                itemCount: filteredEmployees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final employee = filteredEmployees[index];
                  final id = (employee['id'] ?? '').toString();
                  final isSelected = id == _selectedEmployeeId;
                  final name = (employee['name'] ?? '-').toString();
                  final nrp = (employee['nrp'] ?? '-').toString();
                  final groupLabel =
                      _resolveGroupLabel(employee['group'] ?? '-');
                  final jabatanLabel =
                      _resolveJabatanLabel(employee['jabatan'] ?? '-');

                  return Material(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _onEmployeeTapped(employee),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 20),
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
                                    'NRP: $nrp • Grup: $groupLabel • Jabatan: $jabatanLabel',
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
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              child: Icon(Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitForm({
    required String employeeId,
    required GlobalKey<FormState> formKey,
  }) async {
    if (employeeId.isEmpty) {
      showTopToast(
        'Pegawai tidak valid',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (!formKey.currentState!.validate()) {
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

      if (_phoneColumn != null) {
        updateData[_phoneColumn!] = _phoneController.text.trim();
      }

      await SupabaseService.instance.client
          .from('users')
          .update(updateData)
          .eq('id', employeeId);

      setState(() {
        final idx =
            _employees.indexWhere((e) => e['id'].toString() == employeeId);
        if (idx >= 0) {
          _employees[idx] = {
            ..._employees[idx],
            'name': updateData['name'],
            'jabatan': updateData['jabatan'],
            'group': updateData['group'],
            if (_phoneColumn != null) _phoneColumn!: updateData[_phoneColumn!],
          };
        }
      });

      showTopToast(
        'Data pegawai berhasil diperbarui',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Clear form after successful update
      _clearForm();
    } catch (e) {
      showTopToast(
        'Gagal memperbarui data pegawai: $e',
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
