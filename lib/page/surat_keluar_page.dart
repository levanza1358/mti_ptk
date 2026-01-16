import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/cuti_controller.dart';
import '../controller/login_controller.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class SuratKeluarPage extends StatefulWidget {
  const SuratKeluarPage({super.key});

  @override
  State<SuratKeluarPage> createState() => _SuratKeluarPageState();
}

class _SuratKeluarPageState extends State<SuratKeluarPage> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _letterTitleController = TextEditingController();
  final TextEditingController _letterNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _showForm = false;
  late final CutiController _cutiController;
  late final LoginController _loginController;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _cutiController = Get.isRegistered<CutiController>()
        ? Get.find<CutiController>()
        : Get.put(CutiController());
    _loginController = Get.find<LoginController>();
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _letterTitleController.dispose();
    _letterNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: const Text('Surat Keluar'),
      ),
      body: _showForm ? _buildAddForm() : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showForm = !_showForm;
          });
        },
        child: Icon(_showForm ? Icons.list : Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(dynamic id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Surat'),
        content:
            const Text('Apakah Anda yakin ingin menghapus surat keluar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await SupabaseService.instance.client
          .from('surat_keluar')
          .delete()
          .eq('id', id);
      showTopToast(
        'Surat keluar berhasil dihapus',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      setState(() {});
    } catch (e) {
      showTopToast(
        'Gagal menghapus surat keluar',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: theme.cardColor,
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedYear -= 1;
                  });
                },
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Tahun sebelumnya',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _selectedYear.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Daftar surat keluar per tahun',
                      style: TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedYear += 1;
                  });
                },
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Tahun berikutnya',
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchOutgoingLetters(year: _selectedYear),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final letters = snapshot.data ?? [];
              if (letters.isEmpty) {
                return const Center(child: Text('Belum ada data surat keluar'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: letters.length,
                itemBuilder: (context, index) {
                  final letter = letters[index];
                  final createdAtRaw = letter['created_at'];
                  final urlTtd = (letter['url_ttd'] ?? '').toString();
                  DateTime? createdAt;
                  if (createdAtRaw is String) {
                    createdAt = DateTime.tryParse(createdAtRaw);
                  } else if (createdAtRaw is DateTime) {
                    createdAt = createdAtRaw;
                  }
                  final tanggalStr = createdAt != null
                      ? DateFormat('dd MMM yyyy', 'id_ID')
                          .format(createdAt.toLocal())
                      : '-';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (letter['judul_surat'] ?? 'Tanpa Judul')
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No: ${(letter['nomor_surat'] ?? '-').toString()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kepada: ${(letter['nama_perusahaan'] ?? '-').toString()}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (letter['deskripsi_surat'] ?? '-').toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (urlTtd.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      _showSignatureDialog(urlTtd, createdAt);
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: 60,
                                        child: Image.network(
                                          urlTtd,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tanggalStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            showTopToast(
                                                'Fitur lihat PDF akan segera hadir');
                                          },
                                          icon:
                                              const Icon(Icons.picture_as_pdf),
                                          label: const Text('Lihat PDF'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            final id = letter['id'];
                                            if (id != null) {
                                              _confirmDelete(id);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Hapus',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Surat Keluar Baru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama perusahaan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _letterTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Surat',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul surat tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _letterNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Surat',
                      border: OutlineInputBorder(),
                      hintText: 'Contoh: 001/SK/MTI-PTK/2024',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Surat',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan deskripsi atau isi surat...',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi surat tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Obx(() {
                          final hasSignature =
                              _cutiController.hasSignature.value;
                          final url = _cutiController.signatureUrl.value;

                          if (!hasSignature || url.isEmpty) {
                            return Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.grey[800] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.draw,
                                      color: Colors.grey, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada tanda tangan',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 80,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tanda Tangan Terverifikasi',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.green),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cutiController.showSignatureDialog,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Buat / Ubah Tanda Tangan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showForm = false;
                              _clearForm();
                            });
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitLetter,
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitLetter() async {
    if (_companyController.text.isEmpty ||
        _letterTitleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      showTopToast(
        'Harap isi semua field yang wajib',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      final nomor = _letterNumberController.text.trim();
      String? urlTtd;
      final sigUrl = _cutiController.signatureUrl.value;
      if (sigUrl.isNotEmpty) {
        urlTtd = sigUrl;
      } else {
        final user = _loginController.currentUser.value;
        final raw = user?['ttd_url'];
        if (raw != null && raw.toString().isNotEmpty) {
          urlTtd = raw.toString();
        }
      }
      await SupabaseService.instance.client.from('surat_keluar').insert({
        'nama_perusahaan': _companyController.text.trim(),
        'judul_surat': _letterTitleController.text.trim(),
        'nomor_surat': nomor.isEmpty ? null : nomor,
        'deskripsi_surat': _descriptionController.text.trim(),
        'url_ttd': urlTtd,
      });

      showTopToast(
        'Surat keluar berhasil ditambahkan',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      setState(() {
        _showForm = false;
        _clearForm();
      });
    } catch (e) {
      showTopToast(
        'Gagal menyimpan surat keluar',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _clearForm() {
    _companyController.clear();
    _letterTitleController.clear();
    _letterNumberController.clear();
    _descriptionController.clear();
  }

  Future<List<Map<String, dynamic>>> _fetchOutgoingLetters(
      {required int year}) async {
    try {
      final start = DateTime(year, 1, 1);
      final end = DateTime(year, 12, 31, 23, 59, 59);
      final response = await SupabaseService.instance.client
          .from('surat_keluar')
          .select(
              'id, nama_perusahaan, judul_surat, nomor_surat, deskripsi_surat, url_ttd, created_at')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to fetch outgoing letters: $e';
    }
  }

  void _showSignatureDialog(String urlTtd, DateTime? createdAt) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final DateTime? signatureTime =
            _parseSignatureTimeFromUrl(urlTtd) ?? createdAt;
        final String timestampText = signatureTime != null
            ? DateFormat('dd MMM yyyy HH:mm', 'id_ID')
                .format(signatureTime.toLocal())
            : 'Tidak diketahui';
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    urlTtd,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tanda tangan pada $timestampText',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime? _parseSignatureTimeFromUrl(String urlTtd) {
    try {
      String fileName;
      final uri = Uri.tryParse(urlTtd);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        fileName = uri.pathSegments.last;
      } else {
        fileName = urlTtd.split('/').last;
      }

      fileName = fileName.split('?').first;

      final regex = RegExp(r'signature_(\d+)\.png', caseSensitive: false);
      final match = regex.firstMatch(fileName);
      if (match == null) {
        return null;
      }

      final millis = int.tryParse(match.group(1)!);
      if (millis == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }
}
