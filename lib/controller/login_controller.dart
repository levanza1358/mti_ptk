import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/supabase_service.dart';
import '../utils/top_toast.dart';

class LoginController extends GetxController {
  final TextEditingController nrpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentUser = Rxn<Map<String, dynamic>>();
  var currentJabatan = Rxn<Map<String, dynamic>>();
  var isPasswordHidden = true.obs;

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    nrpController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Check if user is already logged in from shared preferences
  Future<void> checkLoginStatus({bool shouldRedirect = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        final user = Map<String, dynamic>.from(json.decode(userJson));
        currentUser.value = user;
        isLoggedIn.value = true;

        // Fetch permissions
        await fetchJabatanPermissions();

        // Only redirect to home if we're on the login page and shouldRedirect is true
        final currentRoute = Get.currentRoute;
        if (shouldRedirect &&
            (currentRoute == '/login' || currentRoute == '/')) {
          Get.offAllNamed('/home');
        }
      } catch (e) {
        // If parsing fails, clear and stay on current page
        await prefs.remove('current_user');
      }
    }
  }

  Future<void> fetchJabatanPermissions() async {
    final user = currentUser.value;
    if (user == null || user['jabatan'] == null) {
      currentJabatan.value = null;
      return;
    }

    try {
      final jabatanName = user['jabatan'].toString();
      final response = await SupabaseService.instance.client
          .from('jabatan')
          .select()
          .eq('nama', jabatanName)
          .maybeSingle();

      currentJabatan.value = response;
    } catch (e) {
      debugPrint('Error fetching jabatan permissions: $e');
      currentJabatan.value = null;
    }
  }

  Future<void> login() async {
    if (loginFormKey.currentState?.validate() != true) {
      return;
    }

    isLoading.value = true;

    try {
      final user = await SupabaseService.instance.loginWithNRP(
        nrp: nrpController.text.trim(),
        password: passwordController.text,
      );

      if (user != null) {
        currentUser.value = user;
        isLoggedIn.value = true;

        // Fetch permissions
        await fetchJabatanPermissions();

        // Save to shared preferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', json.encode(user));

        Get.offAllNamed('/home');
        showTopToast(
          'Login berhasil! Selamat datang ${user['name']}',
          background: Colors.green,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        // Ensure UI update happens
        await Future.delayed(Duration.zero);
        showTopToast(
          'NRP atau password salah',
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      showTopToast(
        'Terjadi kesalahan: $e',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      currentUser.value = null;
      currentJabatan.value = null;
      isLoggedIn.value = false;

      nrpController.clear();
      passwordController.clear();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');

      Get.offAllNamed('/login');
      showTopToast(
        'Logout berhasil',
        background: Colors.blue,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      showTopToast(
        'Logout gagal: ${e.toString()}',
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  String? validateNrp(String? value) {
    if (value == null || value.isEmpty) {
      return 'NRP tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'NRP minimal 3 karakter';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }
}
