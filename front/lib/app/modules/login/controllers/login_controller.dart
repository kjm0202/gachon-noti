import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthService _authProvider = Get.find<AuthService>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 초기화 시 로딩 상태 해제
    isLoading.value = false;
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
