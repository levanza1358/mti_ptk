import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/supabase_service.dart';

class LoginController extends GetxController {
  final TextEditingController nrpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentUser = Rxn<Map<String, dynamic>>();
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

        // Save to shared preferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', json.encode(user));

        Get.offAllNamed('/home');

        Get.snackbar(
          'Berhasil',
          'Login berhasil! Selamat datang ${user['name']}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Error',
          'NRP atau password salah',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      currentUser.value = null;
      isLoggedIn.value = false;

      nrpController.clear();
      passwordController.clear();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');

      Get.offAllNamed('/login');

      Get.snackbar(
        'Berhasil',
        'Logout berhasil',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout gagal: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
