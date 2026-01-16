import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class TambahPegawaiPage extends StatefulWidget {
  const TambahPegawaiPage({super.key});

  @override
  State<TambahPegawaiPage> createState() => _TambahPegawaiPageState();
}

class _TambahPegawaiPageState extends State<TambahPegawaiPage> {
  final _formKey = GlobalKey<FormState>();
  final _nrpController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGroup;
  String? _selectedJabatan;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _jabatan = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroupsAndJabatan();
  }

  @override
  void dispose() {
    _nrpController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupsAndJabatan() async {
    try {
      final groupsResponse = await SupabaseService.instance.client
          .from('group')
          .select('id, nama')
          .order('nama');
      final jabatanResponse = await SupabaseService.instance.client
          .from('jabatan')
          .select('id, nama')
          .order('nama');

      setState(() {
        _groups = List<Map<String, dynamic>>.from(groupsResponse);
        _jabatan = List<Map<String, dynamic>>.from(jabatanResponse);
      });
    } catch (e) {
      showTopToast(
        'Gagal memuat data grup dan jabatan: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/data-management'),
          tooltip: 'Kembali ke Data Management',
        ),
        title: const Text('Tambah Pegawai'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Pegawai Baru',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan data pegawai yang akan ditambahkan ke sistem',
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
                    children: [
                      // NRP Field
                      TextFormField(
                        controller: _nrpController,
                        decoration: const InputDecoration(
                          labelText: 'NRP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NRP tidak boleh kosong';
                          }
                          if (value.length < 3) {
                            return 'NRP minimal 3 karakter';
                          }
                          return null;
                        },
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

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Grup harus dipilih';
                          }
                          return null;
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jabatan harus dipilih';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Tambah Pegawai',
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.instance.client.from('users').insert({
        'nrp': _nrpController.text.trim(),
        'name': _nameController.text.trim(),
        'password': _passwordController.text,
        'jabatan': _selectedJabatan,
        'group': _selectedGroup,
      });

      showTopToast(
        'Pegawai berhasil ditambahkan',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear form
      _nrpController.clear();
      _nameController.clear();
      _passwordController.clear();
      setState(() {
        _selectedGroup = null;
        _selectedJabatan = null;
      });

      Get.back(); // Go back to previous page
    } catch (e) {
      showTopToast(
        'Gagal menambah pegawai: $e',
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
