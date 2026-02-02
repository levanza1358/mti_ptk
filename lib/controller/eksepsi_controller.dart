import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class EksepsiController extends GetxController {
  // Signature controller
  late SignatureController signatureController;

  // Observable variables
  final Rx<Uint8List?> signatureData = Rx<Uint8List?>(null);
  final RxBool hasSignature = false.obs;
  final RxString signatureUrl = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void onClose() {
    signatureController.dispose();
    super.onClose();
  }

  /// Clear signature data and reset state
  void clearSignature() {
    signatureController.clear();
    signatureData.value = null;
    hasSignature.value = false;
    signatureUrl.value = '';
  }

  /// Save signature to memory (convert to PNG bytes)
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

  /// Upload signature to Supabase Storage bucket 'ttd_eksepsi'
  Future<void> uploadSignature() async {
    if (signatureData.value == null) return;

    try {
      isLoading.value = true;
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = signatureData.value!;

      final response = await SupabaseService.instance.client.storage
          .from('ttd_eksepsi')
          .uploadBinary(fileName, bytes);

      if (response.isNotEmpty) {
        final String publicUrl = SupabaseService.instance.client.storage
            .from('ttd_eksepsi')
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

  /// Show signature dialog for user to create signature
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
                            if (dialogCtx.mounted) {
                              FocusScope.of(dialogCtx).unfocus();
                            }
                          } catch (_) {}

                          // Close dialog after saving
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
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
}
