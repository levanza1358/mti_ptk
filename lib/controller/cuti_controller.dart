// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'package:table_calendar/table_calendar.dart';
import '../services/supabase_service.dart';
import 'login_controller.dart';
import '../utils/top_toast.dart';

class CutiController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Form key
  final cutiFormKey = GlobalKey<FormState>();

  // Controllers
  final alasanController = TextEditingController();
  late TabController tabController;

  // Signature
  late SignatureController signatureController;
  final signatureData = Rx<Uint8List?>(null);
  final signatureUrl = RxString('');
  final hasSignature = false.obs;

  // Observable state variables
  final isLoading = false.obs;
  final isLoadingUser = false.obs;
  final isLoadingHistory = false.obs;
  final currentUser = Rxn<Map<String, dynamic>>();
  final sisaCuti = 0.obs;

  // Leave type selection
  final selectedLeaveType = 'Cuti Tahunan'.obs;
  final selectedReasonFromDb = ''.obs;

  // Important reasons loaded from database
  final importantReasonsFromDb = <String>[].obs;

  // Maximum days for important leave reasons
  final importantLeaveMaxDays = {
    'Keluarga inti meninggal': 2,
    'Keluarga tidak inti meninggal': 1,
    'Menikah': 3,
    'Menikahkan anak': 2,
    'Anak khitan / baptis anak / istri melahirkan / istri keguguran': 2,
    'Pengurusan dokumen penting': 1,
    'Umrah': 3,
    'Ibadah Haji': 45, // Maximum 45 days
  };

  // History data
  final cutiHistory = <Map<String, dynamic>>[].obs;
  final filteredCutiHistory = <Map<String, dynamic>>[].obs;

  // Year filtering for history
  final selectedYear = DateTime.now().year.obs;

  // Calendar variables
  final selectedDates = <DateTime>[].obs;
  final focusedDay = DateTime.now().obs;
  final calendarFormat = CalendarFormat.month.obs;

  // Login controller reference
  final LoginController loginController = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Listen to year changes and filter data
    ever(selectedYear, (_) => _filterCutiHistoryByYear());

    // Listen to date selection changes for real-time validation
    ever(selectedDates, (_) => _validateSelectedDates());

    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadCurrentUser();
    await loadCutiHistory();
    await loadImportantReasons();
  }

  @override
  void onClose() {
    alasanController.dispose();
    signatureController.dispose();
    tabController.dispose();
    super.onClose();
  }

  // Load current user data with sisa_cuti
  Future<void> loadCurrentUser() async {
    isLoadingUser.value = true;
    try {
      final user = loginController.currentUser.value;
      if (user != null) {
        // Get fresh user data with sisa_cuti
        final result = await SupabaseService.instance.client
            .from('users')
            .select()
            .eq('id', user['id'])
            .single();

        currentUser.value = result;
        sisaCuti.value =
            result['sisa_cuti'] ?? 12; // Default 12 hari cuti per tahun
      }
    } catch (e) {
      showTopToast(
        'Gagal memuat data pengguna: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingUser.value = false;
    }
  }

  // Toggle date selection
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDates.contains(selectedDay)) {
      selectedDates.remove(selectedDay);
    } else {
      if (selectedLeaveType.value == 'Cuti Tahunan') {
        final maxDays = sisaCuti.value;
        if (selectedDates.length >= maxDays) {
          showTopToast(
            'Tanggal cuti melebihi sisa cuti Anda (maksimal $maxDays hari)',
            background: Colors.red,
            foreground: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }
      if (selectedLeaveType.value == 'Cuti Alasan Penting' &&
          selectedReasonFromDb.value.isNotEmpty) {
        final maxDays =
            importantLeaveMaxDays[selectedReasonFromDb.value] ?? 999;
        if (selectedDates.length >= maxDays) {
          showTopToast(
            'Tanggal cuti melebihi dari yang ditentukan (maksimal $maxDays hari)',
            background: Colors.orange,
            foreground: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return; // Don't add the date
        }
      }

      selectedDates.add(selectedDay);
    }

    this.focusedDay.value = focusedDay;
    selectedDates.sort();
  }

  // Clear selected dates
  void clearSelectedDates() {
    selectedDates.clear();
  }

  // Real-time validation for selected dates
  void _validateSelectedDates() {
    if (selectedLeaveType.value == 'Cuti Alasan Penting' &&
        selectedReasonFromDb.value.isNotEmpty) {
      final maxDays = importantLeaveMaxDays[selectedReasonFromDb.value] ?? 999;
      if (selectedDates.length > maxDays) {
        showTopToast(
          'Tanggal cuti melebihi dari yang ditentukan (maksimal $maxDays hari). Silakan hapus beberapa tanggal.',
          background: Colors.orange,
          foreground: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
    if (selectedLeaveType.value == 'Cuti Tahunan' &&
        selectedDates.length > sisaCuti.value) {
      final maxDays = sisaCuti.value;
      showTopToast(
        'Tanggal cuti melebihi sisa cuti Anda (maksimal $maxDays hari). Silakan hapus beberapa tanggal.',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<bool> submitCutiApplication() async {
    if (cutiFormKey.currentState != null &&
        !cutiFormKey.currentState!.validate()) {
      return false;
    }

    if (selectedDates.isEmpty) {
      showTopToast(
        'Silakan pilih tanggal cuti terlebih dahulu',
        background: Colors.orange,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    if (!hasSignature.value || signatureUrl.isEmpty) {
      showTopToast(
        'Mohon buat tanda tangan terlebih dahulu',
        background: Colors.orange,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    // For now, no day limit validation for important leave
    // Can be configured later based on specific requirements
    if (selectedLeaveType.value == 'Cuti Alasan Penting' &&
        selectedReasonFromDb.value.isEmpty) {
      showTopToast(
        'Pilih alasan penting terlebih dahulu',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    if (selectedLeaveType.value == 'Cuti Tahunan' &&
        alasanController.text.trim().isEmpty) {
      showTopToast(
        'Alasan cuti tidak boleh kosong',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final lamaCuti = selectedDates.length;

    // Only validate annual leave balance for annual leave
    if (selectedLeaveType.value == 'Cuti Tahunan' &&
        lamaCuti > sisaCuti.value) {
      showTopToast(
        'Jumlah hari cuti ($lamaCuti) melebihi sisa cuti Anda (${sisaCuti.value})',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    isLoading.value = true;

    try {
      final user = currentUser.value!;

      // Format selected dates as comma-separated string
      final tanggalCutiList =
          selectedDates.map((date) => date.toString().split(' ')[0]).join(',');

      // Prepare cuti data with leave type information
      final cutiData = {
        'users_id': user['id'],
        'nama': user['name'],
        'jenis_cuti': selectedLeaveType.value == 'Cuti Tahunan'
            ? 'CUTI TAHUNAN'
            : 'CUTI ALASAN PENTING',
        'alasan_cuti': selectedLeaveType.value == 'Cuti Tahunan'
            ? alasanController.text.trim()
            : selectedReasonFromDb.value,
        'lama_cuti': lamaCuti,
        'list_tanggal_cuti': tanggalCutiList,
        'url_ttd': signatureUrl.value,
        'tanggal_pengajuan': DateTime.now().toIso8601String(),
      };

      // Only update sisa_cuti for annual leave
      if (selectedLeaveType.value == 'Cuti Tahunan') {
        cutiData['sisa_cuti'] = sisaCuti.value - lamaCuti;
        // Update user's sisa_cuti
        await SupabaseService.instance.client.from('users').update(
            {'sisa_cuti': sisaCuti.value - lamaCuti}).eq('id', user['id']);
      } else {
        // For important leave, sisa_cuti remains the same
        cutiData['sisa_cuti'] = sisaCuti.value;
      }

      // Insert cuti data
      await SupabaseService.instance.client.from('cuti').insert(cutiData);

      final message = selectedLeaveType.value == 'Cuti Tahunan'
          ? 'Pengajuan cuti berhasil disubmit!\nSisa cuti Anda: ${sisaCuti.value - lamaCuti} hari'
          : 'Pengajuan cuti alasan penting berhasil disubmit!\nSisa cuti tahunan tetap: ${sisaCuti.value} hari';

      showTopToast(
        message,
        background: Colors.green.withValues(alpha: 0.9),
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );

      clearSignature();
      clearForm();

      // Refresh user data and history
      await loadCurrentUser();
      await loadCutiHistory();

      // Switch to history tab to show the new submission
      tabController.animateTo(1);
      return true;
    } catch (e) {
      showTopToast(
        'Gagal mengajukan cuti: $e',
        background: Colors.red.withValues(alpha: 0.9),
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Signature helpers
  void clearSignature() {
    signatureController.clear();
    signatureData.value = null;
    hasSignature.value = false;
    signatureUrl.value = '';
  }

  Future<void> saveSignature() async {
    if (signatureController.isEmpty) {
      showTopToast(
        'Tanda tangan masih kosong',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      final signature = await signatureController.toPngBytes();
      if (signature != null) {
        signatureData.value = signature;
        hasSignature.value = true;
        await uploadSignature();
      }
    } catch (e) {
      showTopToast(
        'Gagal menyimpan tanda tangan: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> uploadSignature() async {
    if (signatureData.value == null) return;

    try {
      isLoading.value = true;
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = signatureData.value!;

      final response = await SupabaseService.instance.client.storage
          .from('ttd_cuti')
          .uploadBinary(fileName, bytes);

      if (response.isNotEmpty) {
        final String publicUrl = SupabaseService.instance.client.storage
            .from('ttd_cuti')
            .getPublicUrl(fileName);

        signatureUrl.value = publicUrl;
      }
    } catch (e) {
      showTopToast(
        'Gagal upload tanda tangan: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void showSignatureDialog() {
    final BuildContext? ctx = Get.context;
    if (ctx == null) return;

    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.maxFinite,
            height: Get.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tanda Tangan Digital',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Silakan buat tanda tangan Anda di area di bawah ini:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Signature(
                      controller: signatureController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          clearSignature();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (signatureController.isEmpty) {
                            showTopToast(
                              'Mohon buat tanda tangan terlebih dahulu',
                              background: Colors.orange,
                              foreground: Colors.white,
                              duration: const Duration(seconds: 3),
                            );
                            return;
                          }

                          // Save signature and upload; await to ensure state updated
                          await saveSignature();

                          // Remove focus to avoid any gesture/focus issues
                          try {
                            FocusScope.of(dialogCtx).unfocus();
                          } catch (_) {}

                          // Close dialog after saving
                          Navigator.of(dialogCtx).pop();
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Toggle kunci cuti (lock/unlock)
  Future<void> toggleKunciCuti(Map<String, dynamic> cutiData) async {
    try {
      final cutiId = cutiData['id'];
      final currentLockStatus = cutiData['kunci_cuti'] ?? false;
      final newLockStatus = !currentLockStatus;

      // Update lock status
      await SupabaseService.instance.client
          .from('cuti')
          .update({'kunci_cuti': newLockStatus}).eq('id', cutiId);

      // Refresh data
      await loadCutiHistory();

      showTopToast(
        newLockStatus
            ? 'Cuti berhasil dikunci. Data tidak dapat dihapus.'
            : 'Kunci cuti berhasil dibuka. Data dapat dihapus kembali.',
        background: (newLockStatus ? Colors.orange : Colors.green)
            .withValues(alpha: 0.9),
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal mengubah status kunci cuti: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Delete cuti and conditionally restore leave balance
  Future<void> deleteCuti(Map<String, dynamic> cutiData) async {
    try {
      final cutiId = cutiData['id'];
      final userId = cutiData['users_id'];
      final jenisCuti = cutiData['jenis_cuti'] ?? '';

      // Parse the leave dates to calculate days to restore
      final dateString = cutiData['list_tanggal_cuti'] ?? '';
      final dates = dateString.isNotEmpty
          ? dateString.split(',').map((e) => e.trim()).toList()
          : <String>[];
      final daysToRestore = dates.length;

      if (daysToRestore == 0) {
        showTopToast(
          'Tidak dapat menghitung hari cuti yang akan dikembalikan',
          background: Colors.red.withValues(alpha: 0.9),
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Attempt to delete the signature file from storage (non-blocking)
      final String? signatureUrlStr = cutiData['url_ttd'];
      if (signatureUrlStr != null && signatureUrlStr.isNotEmpty) {
        try {
          const bucketName = 'ttd_cuti';
          final marker = '/object/public/$bucketName/';
          final index = signatureUrlStr.indexOf(marker);
          if (index != -1) {
            final objectPath = signatureUrlStr.substring(index + marker.length);
            if (objectPath.isNotEmpty) {
              await SupabaseService.instance.client.storage
                  .from(bucketName)
                  .remove([objectPath]);
            }
          }
        } catch (e) {
          // Inform the user but continue with deletion
          showTopToast(
            'Gagal menghapus file tanda tangan dari penyimpanan: $e',
            background: Colors.orange.withValues(alpha: 0.9),
            foreground: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }

      // Start transaction-like operations
      // 1. Delete the cuti record
      await SupabaseService.instance.client
          .from('cuti')
          .delete()
          .eq('id', cutiId);

      // 2. Only restore leave balance for annual leave (CUTI TAHUNAN)
      if (jenisCuti == 'CUTI TAHUNAN') {
        // Get current user's leave balance
        final userResult = await SupabaseService.instance.client
            .from('users')
            .select('sisa_cuti')
            .eq('id', userId)
            .single();

        final currentBalance = userResult['sisa_cuti'] ?? 0;
        final newBalance = currentBalance + daysToRestore;

        // Update user's leave balance
        await SupabaseService.instance.client
            .from('users')
            .update({'sisa_cuti': newBalance}).eq('id', userId);
      }

      // 3. Refresh data
      await refreshData();

      // Show appropriate success message
      final isAnnualLeave = jenisCuti == 'CUTI TAHUNAN';
      final message = isAnnualLeave
          ? 'Cuti berhasil dihapus dan $daysToRestore hari cuti dikembalikan'
          : 'Cuti berhasil dihapus (kuota cuti tidak dikembalikan)';

      showTopToast(
        message,
        background: Colors.green.withValues(alpha: 0.9),
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Gagal menghapus cuti: $e',
        background: Colors.red.withValues(alpha: 0.9),
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Show delete confirmation dialog
  Future<void> showDeleteConfirmation(Map<String, dynamic> cutiData) async {
    // Check if cuti is locked
    final isLocked = cutiData['kunci_cuti'] ?? false;

    if (isLocked) {
      showTopToast(
        'Cuti ini sudah dikunci dan tidak dapat dihapus',
        background: Colors.orange.withValues(alpha: 0.9),
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final dateString = cutiData['list_tanggal_cuti'] ?? '';
    final dates = dateString.isNotEmpty
        ? dateString.split(',').map((e) => e.trim()).toList()
        : <String>[];
    final daysCount = dates.length;
    final jenisCuti = cutiData['jenis_cuti'] ?? '';
    final isAnnualLeave = jenisCuti == 'CUTI TAHUNAN';

    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus cuti ini?'),
            const SizedBox(height: 8),
            Text(
              '" Tanggal: ${dates.isNotEmpty ? "${dates.first} - ${dates.last}" : "-"}',
            ),
            Text('" Durasi: $daysCount hari'),
            Text('" Alasan: ${cutiData['alasan_cuti'] ?? "-"}'),
            const SizedBox(height: 8),
            Text(
              isAnnualLeave
                  ? '$daysCount hari cuti akan dikembalikan ke saldo Anda.'
                  : 'Kuota cuti tidak akan dikembalikan (cuti alasan penting).',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAnnualLeave ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              deleteCuti(cutiData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Show lock/unlock confirmation dialog
  Future<void> showLockConfirmation(Map<String, dynamic> cutiData) async {
    final isCurrentlyLocked = cutiData['kunci_cuti'] ?? false;
    final dateString = cutiData['list_tanggal_cuti'] ?? '';
    final dates = dateString.isNotEmpty
        ? dateString.split(',').map((e) => e.trim()).toList()
        : <String>[];

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isCurrentlyLocked ? Icons.lock_open : Icons.lock,
              color: isCurrentlyLocked ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(isCurrentlyLocked ? 'Buka Kunci Cuti' : 'Kunci Cuti'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentlyLocked
                  ? 'Apakah Anda yakin ingin membuka kunci cuti ini?'
                  : 'Apakah Anda yakin ingin mengunci cuti ini?',
            ),
            const SizedBox(height: 8),
            Text(
              '" Tanggal: ${dates.isNotEmpty ? "${dates.first} - ${dates.last}" : "-"}',
            ),
            Text('" Alasan: ${cutiData['alasan_cuti'] ?? "-"}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isCurrentlyLocked ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCurrentlyLocked
                    ? 'Setelah dibuka, cuti ini dapat dihapus kembali.'
                    : 'Setelah dikunci, cuti ini tidak dapat dihapus.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentlyLocked ? Colors.green : Colors.orange,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              toggleKunciCuti(cutiData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyLocked ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(isCurrentlyLocked ? 'Buka Kunci' : 'Kunci'),
          ),
        ],
      ),
    );
  }

  // Refresh all data
  Future<void> refreshData() async {
    await loadCurrentUser();
    await loadCutiHistory();
  }

  // Clear form
  void clearForm() {
    selectedLeaveType.value = 'Cuti Tahunan'; // Reset to default
    selectedReasonFromDb.value = '';
    alasanController.clear();
    selectedDates.clear();
    focusedDay.value = DateTime.now();
  }

  // Load important reasons from database
  Future<void> loadImportantReasons() async {
    try {
      final result = await SupabaseService.instance.client
          .from('cuti')
          .select('alasan_cuti')
          .eq('jenis_cuti', 'CUTI ALASAN PENTING')
          .not('alasan_cuti', 'is', null)
          .not('alasan_cuti', 'eq', '');

      final reasons = result
          .map((item) => item['alasan_cuti'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically

      // If no data from database, provide default important reasons
      if (reasons.isEmpty) {
        importantReasonsFromDb.value = [
          'Keluarga inti meninggal',
          'Keluarga tidak inti meninggal',
          'Menikah',
          'Menikahkan anak',
          'Anak khitan / baptis anak / istri melahirkan / istri keguguran',
          'Pengurusan dokumen penting',
          'Umrah',
          'Ibadah Haji',
        ];
      } else {
        importantReasonsFromDb.value = reasons;
      }
    } catch (e) {
      // Provide fallback data on error
      importantReasonsFromDb.value = [
        'Keluarga inti meninggal',
        'Keluarga tidak inti meninggal',
        'Menikah',
        'Menikahkan anak',
        'Anak khitan / baptis anak / istri melahirkan / istri keguguran',
        'Pengurusan dokumen penting',
        'Umrah',
        'Ibadah Haji',
      ];
    }
  }

  // Form validators
  String? validateAlasan(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alasan cuti tidak boleh kosong';
    }
    return null;
  }

  // Calendar helpers
  bool isSelectedDay(DateTime day) {
    return selectedDates.any((selected) => isSameDay(selected, day));
  }

  // Change calendar format
  void changeCalendarFormat() {
    calendarFormat.value = calendarFormat.value == CalendarFormat.month
        ? CalendarFormat.twoWeeks
        : CalendarFormat.month;
  }

  // Year filtering methods
  void _filterCutiHistoryByYear() {
    final year = selectedYear.value;
    filteredCutiHistory.value = cutiHistory.where((cuti) {
      try {
        final tanggalPengajuan = cuti['tanggal_pengajuan'];
        if (tanggalPengajuan == null) return false;

        final date = DateTime.parse(tanggalPengajuan);
        return date.year == year;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Navigate to previous year
  void previousYear() {
    selectedYear.value = selectedYear.value - 1;
  }

  // Navigate to next year
  void nextYear() {
    selectedYear.value = selectedYear.value + 1;
  }

  // Reset to current year
  void resetToCurrentYear() {
    selectedYear.value = DateTime.now().year;
  }

  Future<void> loadCutiHistory() async {
    isLoadingHistory.value = true;
    try {
      final user = currentUser.value;

      if (user != null) {
        final int year = selectedYear.value;
        final DateTime start = DateTime(year, 1, 1);
        final DateTime end = DateTime(year, 12, 31, 23, 59, 59);

        final result = await SupabaseService.instance.client
            .from('cuti')
            .select(
                'id, users_id, nama, jenis_cuti, lama_cuti, list_tanggal_cuti, tanggal_pengajuan, alasan_cuti, sisa_cuti, url_ttd, kunci_cuti')
            .eq('users_id', user['id']) // Use foreign key instead of nama
            .gte('tanggal_pengajuan', start.toIso8601String())
            .lte('tanggal_pengajuan', end.toIso8601String())
            .order('tanggal_pengajuan', ascending: false);

        cutiHistory.value = List<Map<String, dynamic>>.from(result);

        // Filter by current selected year
        _filterCutiHistoryByYear();
      }
    } catch (e) {
      showTopToast(
        'Gagal memuat history cuti: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }
}
