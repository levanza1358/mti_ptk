// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class EditGroupPage extends StatefulWidget {
  const EditGroupPage({super.key});

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final response = await SupabaseService.instance.client
          .from('group')
          .select('id, nama')
          .order('nama');

      final groups = List<Map<String, dynamic>>.from(response);
      groups.sort((a, b) {
        final an = (a['nama'] ?? '').toString().toLowerCase();
        final bn = (b['nama'] ?? '').toString().toLowerCase();
        return an.compareTo(bn);
      });

      setState(() {
        _groups = groups;
        _isInitialLoading = false;
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat data grup: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _onGroupTapped(Map<String, dynamic> group) async {
    FocusScope.of(context).unfocus();
    final groupId = (group['id'] ?? '').toString();
    setState(() {
      _selectedGroupId = groupId;
      _groupNameController.text = group['nama'] ?? '';
    });
    await _openEditSheet(groupId: groupId);
  }

  void _clearForm() {
    setState(() {
      _selectedGroupId = null;
      _groupNameController.clear();
    });
  }

  Future<void> _openEditSheet({required String groupId}) async {
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
                      'Edit Data Grup',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
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
                              'Perubahan nama grup akan mempengaruhi semua pengguna yang terkait dengan grup ini.',
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
                                      groupId: groupId,
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
        title: const Text('Edit Grup'),
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
                    'Edit Data Grup',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cari grup, lalu tap untuk edit',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari berdasarkan nama grup',
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
              final filtered = _groups.where((g) {
                final name = (g['nama'] ?? '').toString().toLowerCase();
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
                  child: Center(child: Text('Grup tidak ditemukan')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = filtered[index];
                    final id = (group['id'] ?? '').toString();
                    final isSelected = id == _selectedGroupId;
                    final name = (group['nama'] ?? '-').toString();
                    return Material(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onGroupTapped(group),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.group, size: 20),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                child: Icon(Icons.chevron_right,
                                    color:
                                        Theme.of(context).colorScheme.primary),
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
    required String groupId,
    required GlobalKey<FormState> formKey,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.instance.client
          .from('group')
          .update({'nama': _groupNameController.text.trim()}).eq('id', groupId);

      setState(() {
        final idx = _groups.indexWhere((g) => g['id'].toString() == groupId);
        if (idx >= 0) {
          _groups[idx] = {
            ..._groups[idx],
            'nama': _groupNameController.text.trim(),
          };
          _groups.sort((a, b) {
            final an = (a['nama'] ?? '').toString().toLowerCase();
            final bn = (b['nama'] ?? '').toString().toLowerCase();
            return an.compareTo(bn);
          });
        }
      });

      showTopToast(
        'Nama grup berhasil diperbarui',
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
        'Gagal memperbarui nama grup: $e',
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
