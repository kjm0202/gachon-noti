import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admob_banner_widget.dart';
import 'adfit_banner_widget_stub.dart'
    if (dart.library.js_interop) 'adfit_banner_widget.dart';
import '../data/services/adfree_service.dart';

class UnifiedBannerWidget extends StatelessWidget {
  final String? adfitAdUnit; // Kakao Adfit 광고 단위 ID (웹용)
  final double width;
  final double height;
  final AdMobBannerType bannerType; // AdMob 배너 타입 (모바일용)

  const UnifiedBannerWidget({
    super.key,
    this.adfitAdUnit,
    this.width = 320,
    this.height = 50,
    this.bannerType = AdMobBannerType.home,
  });

  @override
  Widget build(BuildContext context) {
    print('UnifiedBannerWidget: kIsWeb = $kIsWeb');
    print('UnifiedBannerWidget: adfitAdUnit = $adfitAdUnit');

    // 광고 제거 상태를 실시간으로 감지
    if (Get.isRegistered<AdFreeService>()) {
      return Obx(() {
        final adFreeService = Get.find<AdFreeService>();
        print(
            'UnifiedBannerWidget: shouldShowAds = ${adFreeService.shouldShowAds()}');

        if (!adFreeService.shouldShowAds()) {
          print('UnifiedBannerWidget: 광고 제거 상태 - 배너 숨김');
          return const SizedBox.shrink();
        }

        return _buildBannerWidget();
      });
    }

    // AdFreeService가 등록되지 않은 경우 기본으로 광고 표시
    return _buildBannerWidget();
  }

  Widget _buildBannerWidget() {
    // 웹 플랫폼에서는 Kakao Adfit 사용
    if (kIsWeb) {
      // Adfit 광고 단위 ID가 제공된 경우에만 광고 표시
      if (adfitAdUnit != null && adfitAdUnit!.isNotEmpty) {
        print('UnifiedBannerWidget: 웹에서 AdfitBannerWidget 사용');
        return AdfitBannerWidget(
          adUnit: adfitAdUnit!,
          width: width,
          height: height,
        );
      } else {
        print('UnifiedBannerWidget: 웹에서 광고 단위 ID 없음');
        // 광고 단위 ID가 없으면 빈 공간 반환
        return const SizedBox.shrink();
      }
    } else {
      print('UnifiedBannerWidget: 모바일에서 AdMobBannerWidget 사용');
      // 모바일 플랫폼에서는 AdMob 사용
      return AdMobBannerWidget(bannerType: bannerType);
    }
  }
}
