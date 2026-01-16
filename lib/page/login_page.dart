import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo/logo_mti.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // Welcome Text
              const Text(
                'MTI PTK',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan login untuk melanjutkan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Login Form Card
              Card(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: controller.loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: controller.nrpController,
                          decoration: InputDecoration(
                            labelText: 'NRP',
                            hintText: 'Masukkan NRP Anda',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: controller.validateNrp,
                        ),
                        const SizedBox(height: 20),
                        Obx(() => TextFormField(
                              controller: controller.passwordController,
                              obscureText: controller.isPasswordHidden.value,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Masukkan Password Anda',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordHidden.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed:
                                      controller.togglePasswordVisibility,
                                ),
                              ),
                              validator: controller.validatePassword,
                            )),
                        const SizedBox(height: 32),
                        Obx(() => SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Versi 1.0.0',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
