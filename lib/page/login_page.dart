import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MTI PTK',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: controller.nrpController,
                  decoration: const InputDecoration(
                    labelText: 'NRP',
                    border: OutlineInputBorder(),
                  ),
                  validator: controller.validateNrp,
                ),
                const SizedBox(height: 16),
                Obx(() => TextFormField(
                      controller: controller.passwordController,
                      obscureText: controller.isPasswordHidden.value,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordHidden.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                      validator: controller.validatePassword,
                    )),
                const SizedBox(height: 24),
                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value ? null : controller.login,
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
