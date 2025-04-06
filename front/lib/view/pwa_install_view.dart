import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pwa_install/pwa_install.dart';
import '../theme.dart';

// PWA 모드가 아닐 때 표시되는 화면
class PwaInstallView extends StatelessWidget {
  const PwaInstallView({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: '가천대학교 공지사항',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _PwaInstallScreenContent(),
    );
  }
}

class _PwaInstallScreenContent extends StatelessWidget {
  const _PwaInstallScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가천대학교 공지사항')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_to_home_screen,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'PWA로 설치 필요',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '이 앱은 기기의 홈 화면에 설치하여 사용해야 합니다. 아래 설치 버튼을 누르시거나, 브라우저 메뉴에서 "홈 화면에 추가" 옵션을 선택해주세요.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (defaultTargetPlatform == TargetPlatform.iOS) {
                    showModalBottomSheet(
                      context: context,
                      builder:
                          (context) => Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'iOS 설치 방법 (Safari 권장)',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('1. 메뉴 바의 공유('),
                                      const Icon(
                                        CupertinoIcons.share,
                                        size: 14,
                                        color: Color(0xFF007AFF),
                                      ),
                                      const Text(') 버튼 클릭'),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('2. 공유 메뉴에서 "홈 화면에 추가" 선택'),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('3. 홈 화면에 앱이 설치되면 눌러서 실행'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                    );
                  } else {
                    PWAInstall().promptInstall_();
                    if (defaultTargetPlatform == TargetPlatform.windows) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Windows에서는 설치 후 F5를 눌러 새로고침 해주세요.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: const Text('설치'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
