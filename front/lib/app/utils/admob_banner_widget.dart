import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/services/admob_service.dart';
import '../data/services/adfree_service.dart';

// 광고 타입 enum
enum AdMobBannerType {
  home, // 홈 화면용
  settings, // 설정 화면용
}

// 참고: 웹과 모바일에서 다른 광고를 표시하려면 UnifiedBannerWidget을 사용해야 함
// 이 위젯은 모바일 전용 AdMob 배너임
class AdMobBannerWidget extends StatelessWidget {
  final AdMobBannerType bannerType;

  const AdMobBannerWidget({
    super.key,
    this.bannerType = AdMobBannerType.home,
  });

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

    // 광고 제거 상태를 실시간으로 감지
    if (Get.isRegistered<AdFreeService>()) {
      return Obx(() {
        final adFreeService = Get.find<AdFreeService>();
        print(
            'AdMobBannerWidget: shouldShowAds = ${adFreeService.shouldShowAds()}');

        if (!adFreeService.shouldShowAds()) {
          print('AdMobBannerWidget: 광고 제거 상태 - 배너 숨김');
          return const SizedBox.shrink();
        }

        return _buildBannerAd(context);
      });
    }

    // AdFreeService가 등록되지 않은 경우 기본으로 광고 표시
    return _buildBannerAd(context);
  }

  Widget _buildBannerAd(BuildContext context) {
    final adMobService = Get.find<AdMobService>();

    return Obx(() {
      // 배너 타입에 따라 다른 광고 사용
      final bool isAdReady;
      final BannerAd? bannerAd;

      switch (bannerType) {
        case AdMobBannerType.settings:
          isAdReady = adMobService.isSettingsBannerAdReady;
          bannerAd = adMobService.settingsBannerAd;
          break;
        case AdMobBannerType.home:
        default:
          isAdReady = adMobService.isBannerAdReady;
          bannerAd = adMobService.bannerAd;
          break;
      }

      if (!isAdReady || bannerAd == null) {
        // 광고가 로드되지 않았을 때는 빈 컨테이너 반환
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
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
        child: AdWidget(ad: bannerAd),
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

    // 광고 제거 상태를 실시간으로 감지
    if (Get.isRegistered<AdFreeService>()) {
      return Obx(() {
        final adFreeService = Get.find<AdFreeService>();
        print(
            'AdMobMediumRectangleBannerWidget: shouldShowAds = ${adFreeService.shouldShowAds()}');

        if (!adFreeService.shouldShowAds()) {
          print('AdMobMediumRectangleBannerWidget: 광고 제거 상태 - 배너 숨김');
          return const SizedBox.shrink();
        }

        return _buildMediumRectangleBannerAd(context);
      });
    }

    // AdFreeService가 등록되지 않은 경우 기본으로 광고 표시
    return _buildMediumRectangleBannerAd(context);
  }

  Widget _buildMediumRectangleBannerAd(BuildContext context) {
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
