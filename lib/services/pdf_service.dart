import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';

class PdfService {
  static Future<Uint8List> generateLeavePdf({
    required String employeeName,
    required String leaveType,
    required List<DateTime> selectedDates,
    required String reason,
    required int remainingLeave,
    required String employeeId,
    required String position,
  }) async {
    final pdf = pw.Document();

    // Sort dates
    final sortedDates = selectedDates.toList()..sort();

    // Calculate date range
    final dateRange = sortedDates.length == 1
        ? DateFormat('dd/MM/yyyy').format(sortedDates.first)
        : '${DateFormat('dd/MM/yyyy').format(sortedDates.first)} s/d ${DateFormat('dd/MM/yyyy').format(sortedDates.last)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header (without text beside logo)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PT Multi Terminal Indonesia',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'PONTIANAK',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 2),
                      ),
                      child: pw.Text(
                        'FORMULIR PERMOHONAN CUTI',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Employee Information
              pw.Text(
                'Kepada Yth.',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'HR Manager',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'PT Multi Terminal Indonesia',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Dengan hormat,',
                style: const pw.TextStyle(fontSize: 12),
              ),

              pw.SizedBox(height: 20),

              // Personal Information Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.3),
                  1: const pw.FlexColumnWidth(0.05),
                  2: const pw.FlexColumnWidth(0.65),
                },
                children: [
                  _buildTableRow('Nama', ':', employeeName),
                  _buildTableRow('NRP', ':', employeeId),
                  _buildTableRow('Jabatan', ':', position),
                  _buildTableRow('Departemen', ':', 'IT Development'),
                  _buildTableRow('Jenis Cuti', ':', leaveType),
                  _buildTableRow(
                      'Lama Cuti', ':', '${selectedDates.length} hari'),
                  _buildTableRow('Tanggal Cuti', ':', dateRange),
                  _buildTableRow('Sisa Cuti', ':', '$remainingLeave hari'),
                ],
              ),

              pw.SizedBox(height: 20),

              // Reason Section
              pw.Text(
                'Alasan Cuti:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                height: 60,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Text(
                  reason.isNotEmpty ? reason : '-',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 30),

              // Closing
              pw.Text(
                'Demikian permohonan cuti ini saya ajukan, atas perhatian dan persetujuannya saya ucapkan terima kasih.',
                style: const pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.justify,
              ),

              pw.SizedBox(height: 40),

              // Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Pontianak, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 60),
                      pw.Text(
                        'Hormat saya,',
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        employeeName,
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'NRP: $employeeId',
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Approval Section
              pw.Text(
                'Persetujuan:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Mengetahui,',
                          style: const pw.TextStyle(fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Atasan Langsung',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 80,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.Text(
                          '(Nama & Tanda Tangan)',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Menyetujui,',
                          style: const pw.TextStyle(fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'HR Manager',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 80,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.Text(
                          '(Nama & Tanda Tangan)',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer Note
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Text(
                  'Catatan: Formulir cuti harus disetujui minimal 7 hari kerja sebelum tanggal cuti dimulai.',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateExceptionPdf({
    required String employeeName,
    required String exceptionType,
    required List<DateTime> selectedDates,
    required String reason,
    required String employeeId,
    required String position,
  }) async {
    final pdf = pw.Document();

    // Sort dates
    final sortedDates = selectedDates.toList()..sort();

    // Calculate date range
    final dateRange = sortedDates.length == 1
        ? DateFormat('dd/MM/yyyy').format(sortedDates.first)
        : '${DateFormat('dd/MM/yyyy').format(sortedDates.first)} - ${DateFormat('dd/MM/yyyy').format(sortedDates.last)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PT. MITRA TEKNOLOGI INDONESIA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'PONTIANAK',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        'FORMULIR PENGAJUAN EKSEPSI',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Employee Information
              pw.Text(
                'Data Pegawai:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 10),

              _buildInfoRow('Nama', employeeName),
              _buildInfoRow('NRP', employeeId),
              _buildInfoRow('Jabatan', position),

              pw.SizedBox(height: 20),

              // Exception Information
              pw.Text(
                'Detail Eksepsi:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 10),

              _buildInfoRow('Jenis Eksepsi', exceptionType),
              _buildInfoRow('Total Hari', '${selectedDates.length} hari'),
              _buildInfoRow('Tanggal Eksepsi', dateRange),

              pw.SizedBox(height: 15),

              // Reason
              pw.Text(
                'Alasan:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  reason.isNotEmpty ? reason : 'Tidak ada alasan',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 30),

              // Date and Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Pontianak, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        'Yang Mengajukan',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.Text(
                        employeeName,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Disetujui Oleh',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        'Manager/Supervisor',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Dokumen ini dihasilkan secara otomatis oleh sistem MTI PTK',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateEksepsiPdf({
    required Map<String, dynamic> eksepsiData,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? supervisorData,
    Map<String, dynamic>? managerData,
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document();

    await initializeDateFormatting('id_ID', null);

    final ByteData logoData = await rootBundle.load('assets/logo/logo_mti.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final rawTanggalPengajuan = (eksepsiData['tanggal_pengajuan'] ??
            eksepsiData['created_at'] ??
            DateTime.now().toIso8601String())
        .toString();
    final tanggalPengajuan =
        DateTime.tryParse(rawTanggalPengajuan) ?? DateTime.now();
    final formattedDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalPengajuan);

    final nama = (userData['name'] ?? 'Nama Pegawai').toString();
    final nrp =
        (userData['nrp'] ?? userData['nip'] ?? 'NRP Pegawai').toString();
    final kontak = (userData['kontak'] ?? '-').toString();
    final jabatan = (userData['jabatan'] ?? 'Jabatan Pegawai').toString();
    final group = (userData['group'] ?? '-').toString();
    final userStatus = (userData['status'] ?? 'Operasional').toString();

    final supervisorJenis =
        userStatus == 'Non Operasional' ? 'PENUNJANG' : 'LOGISTIK';

    final supervisorNama =
        (supervisorData?['nama'] ?? 'SUPERVISOR $supervisorJenis').toString();
    final supervisorJabatan =
        (supervisorData?['jabatan'] ?? 'SUPERVISOR $supervisorJenis')
            .toString();

    final managerNama = (managerData?['nama'] ?? 'REGIONAL MANAGER').toString();
    final managerJabatan =
        (managerData?['jabatan'] ?? 'REGIONAL MANAGER JAKARTA').toString();

    final jenisEksepsi =
        (eksepsiData['jenis_eksepsi'] ?? 'Jam Masuk & Pulang').toString();

    pw.ImageProvider? ttdImageProvider;
    final ttdUrl = (eksepsiData['url_ttd_eksepsi'] ?? '').toString();
    if (ttdUrl.isNotEmpty) {
      try {
        ttdImageProvider = await networkImage(ttdUrl);
      } catch (_) {
        ttdImageProvider = null;
      }
    }
    if (ttdImageProvider == null && signatureBytes != null) {
      try {
        ttdImageProvider = pw.MemoryImage(signatureBytes);
      } catch (_) {
        ttdImageProvider = null;
      }
    }

    final eksepsiTanggalRaw = eksepsiData['eksepsi_tanggal'];
    final List<Map<String, dynamic>> eksepsiTanggalList =
        eksepsiTanggalRaw is List
            ? eksepsiTanggalRaw
                .whereType<Map>()
                .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                .toList()
            : <Map<String, dynamic>>[];

    if (eksepsiTanggalList.isEmpty) {
      final tanggalEksepsi = eksepsiData['tanggal_eksepsi'];
      if (tanggalEksepsi != null && tanggalEksepsi.toString().isNotEmpty) {
        eksepsiTanggalList.add({
          'urutan': 1,
          'tanggal_eksepsi': tanggalEksepsi.toString(),
          'alasan_eksepsi':
              (eksepsiData['alasan_eksepsi'] ?? eksepsiData['alasan'] ?? '-')
                  .toString(),
        });
      }
    }

    eksepsiTanggalList.sort((a, b) {
      final urutanA = a['urutan'] is num ? (a['urutan'] as num).toInt() : 0;
      final urutanB = b['urutan'] is num ? (b['urutan'] as num).toInt() : 0;
      if (urutanA != urutanB) return urutanA.compareTo(urutanB);

      final tanggalA =
          DateTime.tryParse((a['tanggal_eksepsi'] ?? '').toString());
      final tanggalB =
          DateTime.tryParse((b['tanggal_eksepsi'] ?? '').toString());
      if (tanggalA == null && tanggalB == null) return 0;
      if (tanggalA == null) return 1;
      if (tanggalB == null) return -1;
      return tanggalA.compareTo(tanggalB);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (_) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, width: 120),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Pontianak, $formattedDate',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Yth. REGIONAL MANAGER JAKARTA',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('PT PELINDO DAYA SEJAHTERA',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('JAKARTA', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context _) {
          return [
            pw.SizedBox(height: 12),
            pw.Text(
              'Perihal: Permohonan Ijin Perubahan Sistem Presensi',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Yang bertanda tangan dibawah ini:',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(100),
                1: const pw.FixedColumnWidth(10),
                2: const pw.FlexColumnWidth(),
              },
              children: [
                _buildEksepsiRow('Nama', ':', nama),
                _buildEksepsiRow('NIP', ':', nrp),
                _buildEksepsiRow('Kontak HP / WA', ':', kontak),
                _buildEksepsiRow('Jabatan', ':', jabatan),
                _buildEksepsiRow('Group', ':', group),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Dengan ini mengajukan permohonan perubahan eksepsi presensi dengan rincian sebagai berikut:',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 1),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FixedColumnWidth(140),
                2: const pw.FixedColumnWidth(180),
                3: const pw.FixedColumnWidth(120),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'No',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Tanggal',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Jenis Eksepsi',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Keterangan',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                ...List.generate(eksepsiTanggalList.length, (index) {
                  final tanggalData = eksepsiTanggalList[index];
                  final tanggalEksepsi =
                      (tanggalData['tanggal_eksepsi'] ?? '').toString();
                  final alasanEksepsi =
                      (tanggalData['alasan_eksepsi'] ?? '-').toString();

                  if (tanggalEksepsi.isEmpty) {
                    return pw.TableRow(
                      children: [
                        pw.SizedBox(),
                        pw.SizedBox(),
                        pw.SizedBox(),
                        pw.SizedBox(),
                      ],
                    );
                  }

                  String formattedTanggal = tanggalEksepsi;
                  final parsed = DateTime.tryParse(tanggalEksepsi);
                  if (parsed != null) {
                    formattedTanggal =
                        DateFormat('dd MMMM yyyy', 'id_ID').format(parsed);
                  }

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${index + 1}',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          formattedTanggal,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          jenisEksepsi,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          alasanEksepsi,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Demikian surat permohonan ini saya buat untuk dapat dipertimbangkan sebagaimana mestinya.',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Hormat Saya,',
                        style: const pw.TextStyle(fontSize: 11)),
                    if (ttdImageProvider != null)
                      pw.Container(
                        height: 80,
                        width: 140,
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Image(
                          ttdImageProvider,
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    else
                      pw.SizedBox(height: 80),
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
                          margin: const pw.EdgeInsets.only(top: 2),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(width: 50),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'SETUJU / TIDAK SETUJU MEMBERIKAN EKSEPSI PRESENSI',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
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
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'MENGETAHUI',
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
                      height: 60,
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Row(
                            children: [
                              pw.Stack(
                                alignment: pw.Alignment.center,
                                children: [
                                  pw.Container(
                                    width: 10,
                                    height: 10,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(width: 1),
                                    ),
                                  ),
                                  pw.Text(
                                    'X',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 5),
                              pw.Text(
                                'Hadir / Pulang sesuai jam kerja',
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 10,
                                height: 10,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(width: 1),
                                ),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(
                                child: pw.Text(
                                  'Terlambat / Pulang Cepat / Kurang Absen dengan persetujuan',
                                  style: const pw.TextStyle(fontSize: 7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      height: 60,
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            supervisorJabatan.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 15),
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
                                margin: const pw.EdgeInsets.only(top: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      height: 60,
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            managerJabatan.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 15),
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
                                margin: const pw.EdgeInsets.only(top: 1),
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
            pw.SizedBox(height: 12),
            pw.Container(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'ID: ${(eksepsiData['id'] ?? '-').toString()}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(
      String label, String separator, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            separator,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildEksepsiRow(
    String label,
    String separator,
    String value,
  ) {
    return pw.TableRow(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(separator, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
