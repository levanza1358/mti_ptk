import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/login_controller.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class DataPribadiPage extends StatefulWidget {
  const DataPribadiPage({super.key});

  @override
  State<DataPribadiPage> createState() => _DataPribadiPageState();
}

class _DataPribadiPageState extends State<DataPribadiPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _ukuranBajuController = TextEditingController();
  final _ukuranCelanaController = TextEditingController();
  final _ukuranSepatuController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFromCurrentUser();
    _fetchFromSupabase();
  }

  void _initFromCurrentUser() {
    if (!Get.isRegistered<LoginController>()) {
      return;
    }
    final loginController = Get.find<LoginController>();
    final user = loginController.currentUser.value;
    if (user == null) {
      return;
    }
    _phoneController.text = (user['kontak'] ?? '').toString();
    _ukuranBajuController.text = (user['ukuran_baju'] ?? '').toString();
    _ukuranCelanaController.text = (user['ukuran_celana'] ?? '').toString();
    _ukuranSepatuController.text = (user['ukuran_sepatu'] ?? '').toString();
  }

  Future<void> _fetchFromSupabase() async {
    if (!Get.isRegistered<LoginController>()) {
      return;
    }
    final loginController = Get.find<LoginController>();
    final user = loginController.currentUser.value;
    if (user == null) {
      return;
    }
    final userId = user['id'];
    if (userId == null || userId.toString().isEmpty) {
      return;
    }

    try {
      final result = await SupabaseService.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final data = Map<String, dynamic>.from(result as Map);

      if (!mounted) {
        return;
      }

      setState(() {
        _phoneController.text = (data['kontak'] ?? '').toString();
        _ukuranBajuController.text = (data['ukuran_baju'] ?? '').toString();
        _ukuranCelanaController.text = (data['ukuran_celana'] ?? '').toString();
        _ukuranSepatuController.text = (data['ukuran_sepatu'] ?? '').toString();
      });

      loginController.currentUser.value = data;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(data));
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _ukuranBajuController.dispose();
    _ukuranCelanaController.dispose();
    _ukuranSepatuController.dispose();
    super.dispose();
  }

  Future<void> _saveDataPribadi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!Get.isRegistered<LoginController>()) {
      showTopToast(
        'User tidak ditemukan',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final loginController = Get.find<LoginController>();
    final currentUser = loginController.currentUser.value;
    if (currentUser == null) {
      showTopToast(
        'User tidak ditemukan',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final userId = currentUser['id'];
    if (userId == null || userId.toString().isEmpty) {
      showTopToast(
        'ID user tidak valid',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final kontakRaw = _phoneController.text.trim();
      final kontak = _normalizePhone(kontakRaw);

      final updateData = <String, dynamic>{
        'kontak': kontak,
        'ukuran_baju': _ukuranBajuController.text.trim(),
        'ukuran_celana': _ukuranCelanaController.text.trim(),
        'ukuran_sepatu': _ukuranSepatuController.text.trim(),
      };

      final updated = await SupabaseService.instance.client
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      loginController.currentUser.value =
          Map<String, dynamic>.from(updated as Map);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(updated));

      showTopToast(
        'Data pribadi berhasil disimpan',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal menyimpan data: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _normalizePhone(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^0-9]'), '');

    if (s.startsWith('00')) {
      s = s.substring(2);
    }

    if (s.startsWith('62')) {
      return s;
    }

    if (s.startsWith('0') && s.length > 1) {
      return '62${s.substring(1)}';
    }

    if (s.startsWith('8')) {
      return '62$s';
    }

    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Get.previousRoute.isNotEmpty) {
              Get.back();
            } else {
              Get.offAllNamed('/home');
            }
          },
          tooltip: 'Kembali',
        ),
        title: const Text('Data Pribadi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Kontak',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP / WA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ukuran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ukuranBajuController,
                        decoration: const InputDecoration(
                          labelText: 'Ukuran Baju',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.checkroom),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ukuranCelanaController,
                        decoration: const InputDecoration(
                          labelText: 'Ukuran Celana',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ukuranSepatuController,
                        decoration: const InputDecoration(
                          labelText: 'Ukuran Sepatu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_walk),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDataPribadi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
