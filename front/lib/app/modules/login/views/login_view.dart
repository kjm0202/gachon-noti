import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../utils/platform_utils.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/app_icon_transparent.webp',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                '가천 알림이',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                '가천대학교 공지사항 알림 서비스',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Color(0xffb8d6f4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      elevation: 2,
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.loginWithGoogle(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/google.webp',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        controller.isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '구글 계정으로 로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  // color: Colors.white,
                                ),
                              ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    WebUtils.openUrl('https://gachon-noti-privacy.ven0m.kr/'),
                child: const Text(
                  '개인정보 처리방침',
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
