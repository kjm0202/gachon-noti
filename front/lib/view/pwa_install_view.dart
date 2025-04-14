import 'package:web/web.dart' as web;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pwa_install/pwa_install.dart';
import '../theme.dart';

// PWA 모드가 아닐 때 표시되는 화면
class PwaInstallView extends StatelessWidget {
  const PwaInstallView({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return MaterialApp(
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
                SvgPicture.asset(
                  'assets/icons/safari.svg',
                  width: 80,
                  height: 80,
                )
              else
                SvgPicture.asset(
                  'assets/icons/chrome.svg',
                  width: 80,
                  height: 80,
                ),
              const SizedBox(height: 24),
              Text(
                'PWA로 설치 필요',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AutoSizeText(
                '이 앱은 기기의 홈 화면에 설치 후 사용 가능합니다.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              AutoSizeText(
                '${defaultTargetPlatform == TargetPlatform.iOS ? 'Safari' : 'Chrome'} 브라우저를 권장합니다.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (defaultTargetPlatform == TargetPlatform.android)
                AutoSizeText(
                  '삼성 인터넷 앱은 버그가 있어 추천하지 않습니다.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              AutoSizeText(
                '아래 설치 버튼을 눌러주세요.',
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
                          (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'iOS 설치 방법 (Safari 권장)',
                                  style: Theme.of(context).textTheme.titleLarge,
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
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const Icon(
                                      CupertinoIcons.share,
                                      size: 16,
                                      color: Color(0xFF007AFF),
                                    ),
                                    AutoSizeText(
                                      ') 버튼 클릭',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
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
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
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
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
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
                child: const Text('설치'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
