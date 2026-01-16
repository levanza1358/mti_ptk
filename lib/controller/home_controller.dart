import 'package:get/get.dart';
import '../services/supabase_service.dart';
import 'login_controller.dart';

class HomeController extends GetxController {
  final RxInt totalLembur = 0.obs;
  final RxInt totalPremi = 0.obs;
  final RxBool isLoading = false.obs;
  final Rxn<Map<String, dynamic>> userDetail = Rxn<Map<String, dynamic>>();
  final RxBool isUserDetailLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnualSummary();
    fetchUserDetail();
  }

  Future<void> fetchUserDetail() async {
    try {
      isUserDetailLoading.value = true;

      if (!Get.isRegistered<LoginController>()) {
        return;
      }

      final loginController = Get.find<LoginController>();
      final user = loginController.currentUser.value;

      if (user == null) {
        return;
      }

      final userId = user['id'];
      if (userId == null) {
        return;
      }

      final result = await SupabaseService.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      userDetail.value = Map<String, dynamic>.from(result as Map);
    } catch (_) {
      // ignore errors here, keep UI with basic info
    } finally {
      isUserDetailLoading.value = false;
    }
  }

  Future<void> fetchAnnualSummary() async {
    try {
      isLoading.value = true;

      if (!Get.isRegistered<LoginController>()) {
        return;
      }

      final loginController = Get.find<LoginController>();
      final user = loginController.currentUser.value;

      if (user == null) {
        // Wait for user to be loaded if not yet available
        // But usually LoginController should have it if we are at HomePage
        return;
      }

      final userId = user['id'];
      final nrp = user['nrp']?.toString() ?? '';
      final currentYear = DateTime.now().year;

      // Reset values
      totalLembur.value = 0;
      totalPremi.value = 0;

      // Helper to fetch total
      Future<int> fetchTotal(String table) async {
        dynamic query = SupabaseService.instance.client
            .from(table)
            .select('nominal')
            .eq('tahun', currentYear);

        // Filter by user
        if (userId != null) {
          // We try both users_id and user_id as seen in other files
          // But since we can't do OR easily in one go for column names,
          // and previous code did try-catch blocks or separate queries.
          // Let's rely on the schema which says 'users_id'.
          // However, to be safe and consistent with existing code (insentif_page.dart),
          // we might need to handle potential schema inconsistencies if any.
          // Schema says 'users_id'. Let's stick to that first.
          query = query.eq('users_id', userId);
        } else {
          query = query.eq('nrp', nrp);
        }

        final response = await query;
        final List data = response as List;

        return data.fold<int>(0, (sum, item) {
          final nominal = item['nominal'];
          if (nominal is int) return sum + nominal;
          if (nominal is String) return sum + (int.tryParse(nominal) ?? 0);
          return sum;
        });
      }

      // Fetch concurrently
      final results = await Future.wait([
        fetchTotal('insentif_lembur'),
        fetchTotal('insentif_premi'),
      ]);

      totalLembur.value = results[0];
      totalPremi.value = results[1];
    } catch (e) {
      // print('Error fetching annual summary: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
