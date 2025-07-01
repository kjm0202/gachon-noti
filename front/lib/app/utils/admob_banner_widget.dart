import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/services/admob_service.dart';

// 참고: 웹과 모바일에서 다른 광고를 표시하려면 UnifiedBannerWidget을 사용해야 함
// 이 위젯은 모바일 전용 AdMob 배너임
class AdMobBannerWidget extends StatelessWidget {
  const AdMobBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 웹에서는 광고를 표시하지 않음
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // AdMobService가 등록되어 있는지 확인
    if (!Get.isRegistered<AdMobService>()) {
      return const SizedBox.shrink();
    }

    final adMobService = Get.find<AdMobService>();

    return Obx(() {
      if (!adMobService.isBannerAdReady || adMobService.bannerAd == null) {
        // 광고가 로드되지 않았을 때는 빈 컨테이너 반환
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        width: adMobService.bannerAd!.size.width.toDouble(),
        height: adMobService.bannerAd!.size.height.toDouble(),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: AdWidget(ad: adMobService.bannerAd!),
      );
    });
  }
}

// 중간 직사각형 배너 광고 위젯 (300x250) - 다이얼로그용
class AdMobMediumRectangleBannerWidget extends StatelessWidget {
  const AdMobMediumRectangleBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 웹에서는 광고를 표시하지 않음
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // AdMobService가 등록되어 있는지 확인
    if (!Get.isRegistered<AdMobService>()) {
      return const SizedBox.shrink();
    }

    final adMobService = Get.find<AdMobService>();

    return Obx(() {
      if (!adMobService.isMediumRectangleBannerAdReady ||
          adMobService.mediumRectangleBannerAd == null) {
        // 광고가 로드되지 않았을 때는 빈 컨테이너 반환
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        width: 300,
        height: 250,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: AdWidget(ad: adMobService.mediumRectangleBannerAd!),
      );
    });
  }
}
