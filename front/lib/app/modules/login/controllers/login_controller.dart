import 'package:get/get.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 앱 시작 시 세션 확인
    checkExistingSession();
  }

  Future<void> checkExistingSession() async {
    isLoading.value = true;
    try {
      final isLoggedIn = await _authProvider.checkCurrentSession();
      if (isLoggedIn) {
        Get.offAllNamed(Routes.HOME);
      }
    } catch (e) {
      print('세션 확인 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading.value = true;

    try {
      await _authProvider.loginWithGoogle(
        onLoginSuccess: () {
          isLoading.value = false;
          Get.offAllNamed(Routes.HOME); // 상수 사용
        },
        onLoginFailed: () {
          isLoading.value = false;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '로그인 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
