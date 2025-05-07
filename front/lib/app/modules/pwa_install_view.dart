import 'package:gachon_noti_front/app/utils/alternative_text_style.dart';
import 'package:web/web.dart' as web;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:get/get.dart';
import '../../theme.dart';

// PWA 모드가 아닐 때 표시되는 화면
class PwaInstallView extends StatelessWidget {
  const PwaInstallView({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return GetMaterialApp(
      title: '가천 알림이',
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
      appBar: AppBar(title: const Text('가천 알림이')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (defaultTargetPlatform == TargetPlatform.iOS)
                Image.asset(
                  'assets/icons/safari.webp',
                  width: 80,
                  height: 80,
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/chrome.webp',
                      width: 80,
                      height: 80,
                    ),
                    if (defaultTargetPlatform == TargetPlatform.android) ...[
                      const SizedBox(width: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/samsung_internet.webp',
                            width: 80,
                            height: 80,
                          ),
                          Icon(
                            Icons.block,
                            color: Colors.red.withOpacity(0.8),
                            size: 80,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                'PWA로 설치 필요',
                style: AltTextStyle.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '기기의 홈 화면에 설치 후 사용 가능합니다.\n',
                style: AltTextStyle.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              Text(
                '${defaultTargetPlatform == TargetPlatform.iOS ? 'Safari' : 'Chrome'} 브라우저를 권장합니다.',
                style: AltTextStyle.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (defaultTargetPlatform == TargetPlatform.android)
                Text(
                  '(삼성 인터넷 앱은 버그가 있어 추천 X)\n',
                  style: AltTextStyle.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              Text(
                '아래 설치 버튼을 눌러주세요.',
                style: AltTextStyle.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('설치'),
                  onPressed: () {
                    if (defaultTargetPlatform == TargetPlatform.iOS) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'iOS 설치 방법 (Safari 권장)',
                                style: AltTextStyle.titleLarge,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  AutoSizeText(
                                    '1. 메뉴 바의 공유(',
                                    style: AltTextStyle.bodyLarge,
                                  ),
                                  const Icon(
                                    CupertinoIcons.share,
                                    size: 16,
                                    color: Color(0xFF007AFF),
                                  ),
                                  AutoSizeText(
                                    ') 버튼 클릭',
                                    style: AltTextStyle.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AutoSizeText(
                                  '2. 공유 메뉴에서 "홈 화면에 추가" 선택',
                                  style: AltTextStyle.bodyLarge,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AutoSizeText(
                                  '3. 홈 화면에 앱이 설치되면 눌러서 실행',
                                  style: AltTextStyle.bodyLarge,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    } else {
                      PWAInstall().promptInstall_();
                      if (defaultTargetPlatform == TargetPlatform.windows ||
                          defaultTargetPlatform == TargetPlatform.macOS ||
                          defaultTargetPlatform == TargetPlatform.linux) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AutoSizeText(
                              'PC에서는 설치 후 새 창이 뜨면 새로고침 해주세요.',
                            ),
                            action: SnackBarAction(
                              label: '새로고침',
                              onPressed: () {
                                web.window.location.reload();
                              },
                            ),
                            duration: Duration(days: 365),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('홈페이지'),
                  onPressed: () {
                    web.window.open('https://gachon-noti.notion.site/');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
