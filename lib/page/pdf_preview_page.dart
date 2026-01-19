import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/web_download.dart';
import '../controller/cuti_controller.dart';
import '../controller/login_controller.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class PdfPreviewPage extends StatefulWidget {
  final String title;
  final Future<Uint8List> Function() pdfGenerator;
  final String? fileName;

  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.pdfGenerator,
    this.fileName,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _isLoading = true;
  Uint8List? _pdfData;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final pdfData = await widget.pdfGenerator();
      if (pdfData.isEmpty) {
        if (mounted) {
          _isLoading = false;
          showTopToast(
            'PDF kosong atau gagal dibuat',
            background: Colors.red,
            foreground: Colors.white,
            duration: const Duration(seconds: 3),
          );
          Get.back();
        }
        return;
      }
      if (mounted) {
        setState(() {
          _pdfData = pdfData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showTopToast(
          'Gagal memuat PDF: $e',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    }
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
        title: Text('Preview ${widget.title}'),
        actions: [
          if (!_isLoading && _pdfData != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
              tooltip: 'Download PDF',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printPdf,
              tooltip: 'Print PDF',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: 'Share PDF',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat PDF...'),
                ],
              ),
            )
          : _pdfData == null
              ? const Center(
                  child: Text('Gagal memuat PDF'),
                )
              : PdfPreview(
                  build: (format) => Future.value(_pdfData!),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  scrollViewDecoration: const BoxDecoration(
                    color: Colors.grey,
                  ),
                  pdfFileName: _resolveFileName(),
                ),
    );
  }

  String _resolveFileName() {
    final base = widget.fileName ?? widget.title.replaceAll(' ', '_');
    return base.endsWith('.pdf') ? base : '$base.pdf';
  }

  void _downloadPdf() async {
    if (_pdfData == null) return;

    try {
      await Printing.sharePdf(
        bytes: _pdfData!,
        filename: _resolveFileName(),
      );
      showTopToast(
        'PDF berhasil didownload',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal download PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _printPdf() async {
    if (_pdfData == null) return;

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => _pdfData!,
        name: widget.title,
      );
    } catch (e) {
      showTopToast(
        'Gagal print PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _sharePdf() async {
    if (_pdfData == null) return;

    try {
      await Printing.sharePdf(
        bytes: _pdfData!,
        filename: _resolveFileName(),
      );
    } catch (e) {
      showTopToast(
        'Gagal share PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class PdfCutiController extends GetxController {
  final CutiController? cutiController =
      Get.isRegistered<CutiController>() ? Get.find<CutiController>() : null;
  final SupabaseService supabaseService = SupabaseService.instance;
  final isGenerating = false.obs;
  final pdfPath = Rxn<String>();

  String sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\.-]'), '');
  }

  String extractFirstName(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) return 'user';
    final parts = trimmed.split(' ');
    return parts.first;
  }

  int generateRandomFourDigits() {
    return 1000 + Random().nextInt(9000);
  }

  String generatePdfFileName(Map<String, dynamic> userData) {
    final nrp = sanitizeFilename((userData['nrp'] ?? '00000').toString());
    final firstName = sanitizeFilename(
      extractFirstName(userData['name']?.toString()),
    );
    final randomNumber = generateRandomFourDigits().toString();
    return 'surat_cuti_${firstName}_${nrp}_$randomNumber.pdf';
  }

  Future<String> generatePdfFileNameFromCuti(
      Map<String, dynamic> cutiData) async {
    String nrp = (cutiData['nrp'] ?? '').toString();
    if (nrp.isEmpty) {
      final recordUserId = cutiData['users_id'] ?? cutiData['user_id'];
      if (recordUserId != null) {
        try {
          final u = await supabaseService.client
              .from('users')
              .select('nrp')
              .eq('id', recordUserId)
              .single();
          nrp = (u['nrp'] ?? '').toString();
        } catch (_) {}
      }
    }
    if (nrp.isEmpty) {
      if (Get.isRegistered<LoginController>()) {
        final loginController = Get.find<LoginController>();
        nrp = (loginController.currentUser.value?['nrp'] ?? '00000').toString();
      } else {
        nrp = '00000';
      }
    }
    nrp = sanitizeFilename(nrp);
    final randomNumber =
        (10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString();
    return 'surat_cuti_${nrp}_$randomNumber.pdf';
  }

  String angkaKeKataIndonesia(int n) {
    if (n < 0) return n.toString();
    const units = [
      'Nol',
      'Satu',
      'Dua',
      'Tiga',
      'Empat',
      'Lima',
      'Enam',
      'Tujuh',
      'Delapan',
      'Sembilan',
      'Sepuluh',
      'Sebelas',
      'Dua Belas',
      'Tiga Belas',
      'Empat Belas',
      'Lima Belas',
      'Enam Belas',
      'Tujuh Belas',
      'Delapan Belas',
      'Sembilan Belas',
    ];
    const tens = [
      '',
      'Sepuluh',
      'Dua Puluh',
      'Tiga Puluh',
      'Empat Puluh',
      'Lima Puluh',
      'Enam Puluh',
      'Tujuh Puluh',
      'Delapan Puluh',
      'Sembilan Puluh',
    ];
    if (n < 20) return units[n];
    if (n < 100) {
      final d = n ~/ 10;
      final r = n % 10;
      if (r == 0) return tens[d];
      return '${tens[d]} ${units[r]}';
    }
    if (n < 1000) {
      final h = n ~/ 100;
      final r = n % 100;
      final hundredWord = h == 1 ? 'Seratus' : '${units[h]} Ratus';
      if (r == 0) return hundredWord;
      return '$hundredWord ${angkaKeKataIndonesia(r)}';
    }
    return n.toString();
  }

  Future<Map<String, dynamic>?> fetchSupervisorByJenis(String jenis) async {
    try {
      final response = await supabaseService.client
          .from('supervisor')
          .select('*')
          .eq('jenis', jenis)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentUserWithSisaCuti() async {
    try {
      if (!Get.isRegistered<LoginController>()) {
        return null;
      }

      final loginController = Get.find<LoginController>();
      final loginUser = loginController.currentUser.value;
      if (loginUser == null) {
        return null;
      }

      final result = await supabaseService.client
          .from('users')
          .select()
          .eq('id', loginUser['id'])
          .single();
      return result;
    } catch (e) {
      return null;
    }
  }

  String getSupervisorJenisByUserStatus(String? userStatus) {
    if (userStatus == 'Non Operasional') {
      return 'Penunjang';
    } else if (userStatus == 'Operasional') {
      return 'Logistik';
    }
    return 'Logistik';
  }

  // Generate PDF from current form data (for preview)
  Future<Uint8List> generateLeavePdfFromForm() async {
    isGenerating.value = true;
    final pdf = pw.Document();

    try {
      await initializeDateFormatting('id_ID', null);

      if (cutiController == null) {
        throw 'CutiController not available';
      }

      final loginController = Get.find<LoginController>();
      final currentUser = loginController.currentUser.value;

      if (currentUser == null) {
        throw 'User not logged in';
      }

      // Load logo from assets
      final logoImage = await networkImage('logo/logo_mti.png');

      final tanggalPengajuan = DateTime.now();
      final formattedDate = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(tanggalPengajuan);

      // Use current form data from controller
      final nama = currentUser['name'] ?? 'Nama Pegawai';
      final nip = currentUser['nrp'] ?? 'NRP Pegawai';
      final kontak = currentUser['kontak'] ?? '-';
      final jabatan = currentUser['jabatan'] ?? 'Jabatan Pegawai';
      final group = currentUser['group'] ?? '-';
      final userStatus = currentUser['status'] ?? 'Operasional';
      final sisaCutiUser = cutiController!.sisaCuti.value;

      final supervisorJenis = getSupervisorJenisByUserStatus(userStatus);
      final supervisorData = await fetchSupervisorByJenis(supervisorJenis);
      final managerData = await fetchSupervisorByJenis('Manager_PDS');

      final supervisorNama = supervisorData?['nama'] ??
          'SUPERVISOR ${supervisorJenis.toUpperCase()}';
      final supervisorJabatan = supervisorData?['jabatan'] ??
          'SUPERVISOR ${supervisorJenis.toUpperCase()}';
      final managerNama = managerData?['nama'] ?? 'REGIONAL MANAGER';
      final managerJabatan =
          managerData?['jabatan'] ?? 'REGIONAL MANAGER JAKARTA';

      final selectedDates = cutiController!.selectedDates;
      final leaveType = cutiController!.selectedLeaveType.value;
      final alasanCuti = cutiController!.alasanController.text;

      selectedDates
          .map((date) => DateFormat('yyyy-MM-dd').format(date))
          .toList();

      int sisaCutiTahunan = sisaCutiUser;
      if (leaveType == 'Cuti Tahunan') {
        sisaCutiTahunan = sisaCutiUser - selectedDates.length;
        if (sisaCutiTahunan < 0) {
          sisaCutiTahunan = 0;
        }
      }

      pw.ImageProvider? ttdImageProvider;
      // Use ttd_url from current user data (signature photo from database)
      final String? ttdUrl = currentUser['ttd_url']?.toString();
      if (ttdUrl != null && ttdUrl.isNotEmpty) {
        try {
          ttdImageProvider = await networkImage(ttdUrl);
        } catch (e) {
          // If network image fails, try controller signature data as fallback
          final signatureData = cutiController!.signatureData.value;
          if (signatureData != null) {
            ttdImageProvider = pw.MemoryImage(signatureData);
          }
        }
      } else {
        // Fallback to controller signature data if no ttd_url
        final signatureData = cutiController!.signatureData.value;
        if (signatureData != null) {
          ttdImageProvider = pw.MemoryImage(signatureData);
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(35),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(
                      logoImage,
                      width: 90,
                      height: 90,
                      fit: pw.BoxFit.contain,
                    ),
                    pw.SizedBox(height: 10),
                    // Date and Address
                    pw.Container(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Pontianak, $formattedDate',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Yth. REGIONAL MANAGER JAKARTA',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'PT PELINDO DAYA SEJAHTERA',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text('JAKARTA', style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  () {
                    if (leaveType == 'CUTI ALASAN PENTING') {
                      return 'Perihal: Permohonan Cuti Alasan Penting';
                    } else {
                      return 'Perihal: Permohonan Cuti Tahunan';
                    }
                  }(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Yang bertanda tangan dibawah ini:',
                  style: pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: pw.FixedColumnWidth(140),
                    1: pw.FixedColumnWidth(10),
                    2: pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Nama', ':', nama),
                    _buildTableRow('NRP', ':', nip),
                    _buildTableRow('Nomor HP / WA', ':', kontak),
                    _buildTableRow('Jabatan', ':', jabatan),
                    _buildTableRow('Group', ':', group),
                    _buildTableRow('Alasan Cuti', ':', alasanCuti),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(fontSize: 11),
                    children: [
                      pw.TextSpan(
                        text:
                            'Dengan ini mengajukan permintaan ijin cuti selama ',
                      ),
                      pw.TextSpan(
                        text:
                            '${selectedDates.length} (${angkaKeKataIndonesia(selectedDates.length)})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: ' hari kerja, pada tanggal '),
                      pw.TextSpan(
                        text: selectedDates.isNotEmpty
                            ? '${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDates.first)} s.d ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDates.last)}'
                            : '-',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text:
                            '. Selama menjalankan cuti alamat saya di Pontianak.',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  columnWidths: {
                    0: pw.FixedColumnWidth(80),
                    for (var i = 1; i <= selectedDates.length; i++)
                      i: pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Tanggal',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        ...List.generate(selectedDates.length, (index) {
                          return pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${index + 1}',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Ket.',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        ...List.generate(selectedDates.length, (_) {
                          return pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'C',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.SizedBox(height: 8),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Demikian surat permohonan ini saya buat untuk dapat dipertimbangkan sebagaimana mestinya.',
                  style: pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 30),
                pw.Padding(
                  padding: pw.EdgeInsets.only(right: 28),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Hormat Saya,',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                          pw.SizedBox(height: 8),
                          if (ttdImageProvider != null)
                            pw.Image(
                              ttdImageProvider,
                              width: 140,
                              height: 80,
                              fit: pw.BoxFit.contain,
                            )
                          else
                            pw.SizedBox(height: 60),
                          pw.SizedBox(height: 8),
                          pw.Column(
                            children: [
                              pw.Text(
                                nama.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Container(
                                width: nama.length * 6.0,
                                height: 1,
                                color: PdfColors.black,
                                margin: pw.EdgeInsets.only(top: 2),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.SizedBox(height: 30),
                          pw.Opacity(
                            opacity: 0.3,
                            child: pw.Stack(
                              children: [
                                // area tengah transparan 100% (tidak ada fill)
                                pw.SizedBox(width: 50, height: 50),
                                // border titik - sisi atas
                                pw.Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // border titik - sisi bawah
                                pw.Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // border titik - sisi kiri
                                pw.Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 0,
                                  child: pw.Column(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // border titik - sisi kanan
                                pw.Positioned(
                                  top: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: pw.Column(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Paraf Koord.',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'CATATAN PEJABAT PERSONALIA',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'CATATAN PERTIMBANGAN ATASAN LANGSUNG',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'KEPUTUSAN PEJABAT YANG BERWENANG MEMBERIKAN CUTI',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(
                          height: 80,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Cuti yang telah diambil dalam tahun yang bersangkutan:',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '1. Cuti Tahun : ${tanggalPengajuan.year}',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                              () {
                                if (leaveType == 'CUTI ALASAN PENTING') {
                                  return pw.Text(
                                    '2. Cuti Alasan Penting : ${selectedDates.length} Hari',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                } else {
                                  return pw.Text(
                                    '2. Cuti Alasan Penting : -',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                }
                              }(),
                              () {
                                if (leaveType == 'CUTI TAHUNAN') {
                                  return pw.Text(
                                    '3. Lama Cuti Tahunan : ${selectedDates.length} Hari',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                } else {
                                  return pw.Text(
                                    '3. Lama Cuti Tahunan : - Hari',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                }
                              }(),
                              pw.Text(
                                '4. Sisa Cuti Tahunan : $sisaCutiTahunan Hari',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          height: 60,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                supervisorJabatan.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Spacer(),
                              pw.SizedBox(height: 10),
                              pw.Column(
                                children: [
                                  pw.Text(
                                    supervisorNama.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.Container(
                                    width: supervisorNama.length * 4.5,
                                    height: 1,
                                    color: PdfColors.black,
                                    margin: pw.EdgeInsets.only(top: 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          height: 60,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                managerJabatan.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Spacer(),
                              pw.SizedBox(height: 10),
                              pw.Column(
                                children: [
                                  pw.Text(
                                    managerNama.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.Container(
                                    width: managerNama.length * 4.5,
                                    height: 1,
                                    color: PdfColors.black,
                                    margin: pw.EdgeInsets.only(top: 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final result = await pdf.save();

      return result;
    } catch (e) {
      showTopToast(
        'Gagal membuat PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return Uint8List(0);
    } finally {
      isGenerating.value = false;
    }
  }

  Future<Uint8List> generateCutiPdf(Map<String, dynamic> cutiData) async {
    isGenerating.value = true;
    final pdf = pw.Document();

    try {
      await initializeDateFormatting('id_ID', null);

      final tanggalPengajuan = cutiData['tanggal_pengajuan'] != null
          ? DateTime.parse(cutiData['tanggal_pengajuan'])
          : DateTime.now();

      final formattedDate = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(tanggalPengajuan);

      Map<String, dynamic>? userData;
      final recordUserId = cutiData['users_id'] ?? cutiData['user_id'];
      if (recordUserId != null) {
        try {
          final u = await supabaseService.client
              .from('users')
              .select()
              .eq('id', recordUserId)
              .single();
          userData = Map<String, dynamic>.from(u);
        } catch (_) {
          userData = null;
        }
      }

      userData ??= {
        'name': cutiData['nama'] ?? 'Nama Pegawai',
        'nrp': cutiData['nrp'] ?? 'NRP Pegawai',
        'kontak': cutiData['kontak'] ?? '-',
        'jabatan': cutiData['jabatan'] ?? 'Jabatan Pegawai',
        'group': cutiData['group'] ?? '-',
        'status': cutiData['status'] ?? 'Operasional',
        'sisa_cuti': cutiData['sisa_cuti'] ?? 0,
      };

      final nama = userData['name'] ?? 'Nama Pegawai';
      final nip = userData['nrp'] ?? 'NRP Pegawai';
      final kontak = userData['kontak'] ?? '-';
      final jabatan = userData['jabatan'] ?? 'Jabatan Pegawai';
      final group = userData['group'] ?? '-';
      final userStatus = userData['status'] ?? 'Operasional';
      final dynamic sisaCutiFromCuti = cutiData['sisa_cuti'];
      final sisaCutiUser =
          (sisaCutiFromCuti ?? userData['sisa_cuti'] ?? 0).toString();

      final supervisorJenis = getSupervisorJenisByUserStatus(userStatus);
      final supervisorData = await fetchSupervisorByJenis(supervisorJenis);
      final managerData = await fetchSupervisorByJenis('Manager_PDS');

      final supervisorNama = supervisorData?['nama'] ??
          'SUPERVISOR ${supervisorJenis.toUpperCase()}';
      final supervisorJabatan = supervisorData?['jabatan'] ??
          'SUPERVISOR ${supervisorJenis.toUpperCase()}';
      final managerNama = managerData?['nama'] ?? 'REGIONAL MANAGER';
      final managerJabatan =
          managerData?['jabatan'] ?? 'REGIONAL MANAGER JAKARTA';

      final lamaCuti = cutiData['lama_cuti'] ?? 0;
      final alasanCuti = cutiData['alasan_cuti'] ?? '-';
      final listTanggalCuti = cutiData['list_tanggal_cuti'] ?? '';

      final tanggalCutiList = listTanggalCuti.isNotEmpty
          ? listTanggalCuti.split(',').map((e) => e.trim()).toList()
          : <String>[];

      pw.ImageProvider? ttdImageProvider;
      final String recordTtdUrl = (cutiData['url_ttd'] ?? '').toString();
      if (recordTtdUrl.isNotEmpty) {
        try {
          ttdImageProvider = await networkImage(recordTtdUrl);
        } catch (_) {
          ttdImageProvider = null;
        }
      }
      // Note: Signature functionality not implemented in current system

      final logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/logo/logo_mti.png'))
            .buffer
            .asUint8List(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(35),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Align(
                        alignment: pw.Alignment.topLeft,
                        child: pw.Image(
                          logoImage,
                          width: 90,
                          height: 90,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        alignment: pw.Alignment.topRight,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Pontianak, $formattedDate',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Yth. REGIONAL MANAGER JAKARTA',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              'PT PELINDO DAYA SEJAHTERA',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              'JAKARTA',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  () {
                    final jenisCuti = cutiData['jenis_cuti'] ?? '';
                    if (jenisCuti == 'CUTI ALASAN PENTING') {
                      return 'Perihal: Permohonan Cuti Alasan Penting';
                    } else {
                      return 'Perihal: Permohonan Cuti Tahunan';
                    }
                  }(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 15),

                pw.Text(
                  'Yang bertanda tangan dibawah ini:',
                  style: pw.TextStyle(fontSize: 11),
                ),

                pw.SizedBox(height: 10),

                pw.Table(
                  columnWidths: {
                    0: pw.FixedColumnWidth(140),
                    1: pw.FixedColumnWidth(10),
                    2: pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Nama', ':', nama),
                    _buildTableRow('NRP', ':', nip),
                    _buildTableRow('Nomor HP / WA', ':', kontak),
                    _buildTableRow('Jabatan', ':', jabatan),
                    _buildTableRow('Group', ':', group),
                    _buildTableRow('Alasan Cuti', ':', alasanCuti),
                  ],
                ),

                pw.SizedBox(height: 15),

                pw.RichText(
                  text: () {
                    final hariCount = tanggalCutiList.isNotEmpty
                        ? tanggalCutiList.length
                        : (lamaCuti is int
                            ? lamaCuti
                            : int.tryParse(lamaCuti.toString()) ?? 0);
                    String rentang = '';
                    if (tanggalCutiList.isNotEmpty) {
                      try {
                        final first = DateTime.parse(tanggalCutiList.first);
                        final last = DateTime.parse(tanggalCutiList.last);
                        final firstStr = DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(first);
                        final lastStr = DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(last);
                        rentang = '$firstStr s.d $lastStr';
                      } catch (_) {}
                    }
                    return pw.TextSpan(
                      style: pw.TextStyle(fontSize: 11),
                      children: [
                        pw.TextSpan(
                          text:
                              'Dengan ini mengajukan permintaan ijin cuti selama ',
                        ),
                        pw.TextSpan(
                          text:
                              '$hariCount (${angkaKeKataIndonesia(hariCount)})',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.TextSpan(text: ' hari kerja, pada tanggal '),
                        pw.TextSpan(
                          text: rentang,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.TextSpan(
                          text:
                              '. Selama menjalankan cuti alamat saya di Pontianak.',
                        ),
                      ],
                    );
                  }(),
                ),

                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  columnWidths: {
                    0: pw.FixedColumnWidth(80),
                    for (var i = 1; i <= tanggalCutiList.length; i++)
                      i: pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Tanggal',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        ...tanggalCutiList.map((dateStr) {
                          // Parse date string and format as DD/MM
                          try {
                            final date = DateTime.parse(dateStr);
                            final formatted =
                                DateFormat('dd', 'id_ID').format(date);
                            return pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                formatted,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            );
                          } catch (e) {
                            return pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                dateStr,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Ket.',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        ...List.generate(tanggalCutiList.length, (_) {
                          return pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'C',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 15),

                pw.SizedBox(height: 8),

                pw.SizedBox(height: 15),

                pw.Text(
                  'Demikian surat permohonan ini saya buat untuk dapat dipertimbangkan sebagaimana mestinya.',
                  style: pw.TextStyle(fontSize: 11),
                ),

                pw.SizedBox(height: 30),

                pw.Padding(
                  padding: pw.EdgeInsets.only(right: 28),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Hormat Saya,',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                          pw.SizedBox(height: 8),
                          if (ttdImageProvider != null)
                            pw.Image(
                              ttdImageProvider,
                              width: 140,
                              height: 80,
                              fit: pw.BoxFit.contain,
                            )
                          else
                            pw.SizedBox(height: 60),
                          pw.SizedBox(height: 8),
                          pw.Column(
                            children: [
                              pw.Text(
                                nama.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Container(
                                width: nama.length * 6.0,
                                height: 1,
                                color: PdfColors.black,
                                margin: pw.EdgeInsets.only(top: 2),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.SizedBox(height: 30),
                          pw.Opacity(
                            opacity: 0.3,
                            child: pw.Stack(
                              children: [
                                // area tengah transparan 100% (tidak ada fill)
                                pw.SizedBox(width: 50, height: 50),
                                // border titik - sisi atas
                                pw.Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // border titik - sisi bawah
                                pw.Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // border titik - sisi kiri
                                pw.Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 0,
                                  child: pw.Column(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // border titik - sisi kanan
                                pw.Positioned(
                                  top: 0,
                                  bottom: 0,
                                  right: 0,
                                  child: pw.Column(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceEvenly,
                                    children: List.generate(14, (i) {
                                      return pw.Container(
                                        width: 2,
                                        height: 2,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey600,
                                          borderRadius:
                                              pw.BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Paraf Koord.',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'CATATAN PEJABAT PERSONALIA',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'CATATAN PERTIMBANGAN ATASAN LANGSUNG',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'KEPUTUSAN PEJABAT YANG BERWENANG MEMBERIKAN CUTI',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(
                          height: 80,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Cuti yang telah diambil dalam tahun yang bersangkutan:',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '1. Cuti Tahun : ${tanggalCutiList.isNotEmpty ? DateTime.tryParse(tanggalCutiList.first)?.year ?? tanggalPengajuan.year : tanggalPengajuan.year}',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                              () {
                                final jenisCuti = cutiData['jenis_cuti'] ?? '';
                                if (jenisCuti == 'CUTI ALASAN PENTING') {
                                  return pw.Text(
                                    '2. Cuti Alasan Penting : ${tanggalCutiList.length} Hari',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                } else {
                                  return pw.Text(
                                    '2. Cuti Alasan Penting : -',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                }
                              }(),
                              () {
                                final jenisCuti = cutiData['jenis_cuti'] ?? '';
                                if (jenisCuti == 'CUTI TAHUNAN') {
                                  return pw.Text(
                                    '3. Lama Cuti Tahunan : ${tanggalCutiList.length} Hari',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                } else {
                                  return pw.Text(
                                    '3. Lama Cuti Tahunan : - Hari',
                                    style: pw.TextStyle(fontSize: 7),
                                  );
                                }
                              }(),
                              pw.Text(
                                '4. Sisa Cuti Tahunan : $sisaCutiUser Hari',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          height: 60,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                supervisorJabatan.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Spacer(),
                              pw.SizedBox(height: 10),
                              pw.Column(
                                children: [
                                  pw.Text(
                                    supervisorNama.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.Container(
                                    width: supervisorNama.length * 4.5,
                                    height: 1,
                                    color: PdfColors.black,
                                    margin: pw.EdgeInsets.only(top: 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          height: 60,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                managerJabatan.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Spacer(),
                              pw.SizedBox(height: 10),
                              pw.Column(
                                children: [
                                  pw.Text(
                                    managerNama.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.Container(
                                    width: managerNama.length * 4.5,
                                    height: 1,
                                    color: PdfColors.black,
                                    margin: pw.EdgeInsets.only(top: 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Footer with ID
                pw.Container(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'ID: ${cutiData['id'] ?? '-'}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      showTopToast(
        'Gagal membuat PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return Uint8List(0);
    } finally {
      isGenerating.value = false;
    }
  }

  pw.TableRow _buildTableRow(String label, String separator, String value) {
    return pw.TableRow(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11)),
        pw.Text(separator, style: pw.TextStyle(fontSize: 11)),
        pw.Text(value, style: pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  Future<void> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final cleanName = sanitizeFilename(fileName);

      if (kIsWeb) {
        await triggerDownload(pdfBytes, cleanName);
        showTopToast(
          'PDF diunduh melalui browser',
          background: Colors.green,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      Directory? directory;
      if (Platform.isAndroid) {
        // Coba simpan di folder Downloads publik
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Fallback safety
      directory ??= await getApplicationDocumentsDirectory();

      File file = File('${directory.path}/$cleanName');

      try {
        await file.writeAsBytes(pdfBytes);
        pdfPath.value = file.path;
      } catch (e) {
        // Jika gagal tulis ke Download (Permission Denied), fallback ke internal
        final internalDir = await getApplicationDocumentsDirectory();
        file = File('${internalDir.path}/$cleanName');
        await file.writeAsBytes(pdfBytes);
        pdfPath.value = file.path;
      }

      // Coba buka file langsung agar user tidak bingung mencari file
      try {
        await OpenFilex.open(file.path);
      } catch (_) {}

      showTopToast(
        'PDF tersimpan di ${file.path}',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal menyimpan PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      // Di web, langsung gunakan Printing.sharePdf untuk memicu download/share
      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Dokumen Cuti');
    } catch (e) {
      showTopToast(
        'Gagal membagikan PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> printPdf(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      showTopToast(
        'Gagal mencetak PDF: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> savePdfAsImage(Uint8List pdfBytes, String fileName) async {
    try {
      final cleanBase = sanitizeFilename(fileName.replaceAll('.pdf', ''));
      final pngName = '$cleanBase.png';
      final rasterStream = Printing.raster(pdfBytes, pages: [0], dpi: 144);
      final firstPage = await rasterStream.first;
      final pngBytes = await firstPage.toPng();

      if (kIsWeb) {
        await triggerDownload(pngBytes, pngName);
        showTopToast(
          'Gambar diunduh melalui browser',
          background: Colors.green,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/$pngName');
      await file.writeAsBytes(pngBytes);

      try {
        await OpenFilex.open(file.path);
      } catch (_) {}

      showTopToast(
        'Gambar tersimpan di ${file.path}',
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal menyimpan gambar: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
