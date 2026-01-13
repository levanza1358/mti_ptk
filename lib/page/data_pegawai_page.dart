import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class DataPegawaiPage extends StatelessWidget {
  const DataPegawaiPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
          tooltip: 'Kembali ke Beranda',
        ),
        title: const Text('Data Pegawai'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final employees = snapshot.data ?? [];
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                title: Text(employee['name'] ?? 'Unknown'),
                subtitle: Text('NRP: ${employee['nrp']}'),
                trailing: Text(employee['jabatan'] ?? 'No Position'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new employee
          Get.snackbar('Info', 'Fitur tambah pegawai akan segera hadir');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchEmployees() async {
    try {
      final response = await SupabaseService.instance.client
          .from('users')
          .select('nrp, name, jabatan')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to fetch employees: $e';
    }
  }
}