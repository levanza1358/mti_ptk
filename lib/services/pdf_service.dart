import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

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
              // Company Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PT. MITRA TEKNOLOGI INDONESIA',
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
                'PT. Mitra Teknologi Indonesia',
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
                  _buildTableRow('Lama Cuti', ':', '${selectedDates.length} hari'),
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

  static pw.TableRow _buildTableRow(String label, String separator, String value) {
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
