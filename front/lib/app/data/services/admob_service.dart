import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

class AdMobService extends GetxController {
  static AdMobService get to => Get.find();

  BannerAd? _bannerAd;
  final RxBool _isBannerAdReady = false.obs;

  bool get isBannerAdReady => _isBannerAdReady.value;
  BannerAd? get bannerAd => _bannerAd;

  // 광고 단위 ID
  static final String _bannerAdUnitId = kDebugMode
      ? (Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2435281174' // iOS 테스트 광고 단위 ID
          : 'ca-app-pub-3940256099942544/9214589741') // Android 테스트 광고 단위 ID
      : (Platform.isIOS
          ? 'ca-app-pub-2873399578890001/3360259499' // iOS 실제 배너 광고 단위 ID
          : 'ca-app-pub-2873399578890001/1187174683'); // Android 실제 배너 광고 단위 ID

  @override
  void onInit() {
    super.onInit();
    // 웹에서는 AdMob을 초기화하지 않음
    if (!kIsWeb) {
      _initializeMobileAds();
    }
  }

  @override
  void onClose() {
    _bannerAd?.dispose();
    super.onClose();
  }

  // AdMob 초기화 (모바일 전용)
  Future<void> _initializeMobileAds() async {
    if (kIsWeb) {
      debugPrint('웹 환경에서는 AdMob을 사용할 수 없습니다.');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _loadBannerAd();
    } catch (e) {
      debugPrint('AdMob 초기화 실패: $e');
    }
  }

  // 배너 광고 로드
  void _loadBannerAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('배너 광고 로드 성공');
            _isBannerAdReady.value = true;
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('배너 광고 로드 실패: ${err.message}');
            _isBannerAdReady.value = false;
            ad.dispose();
          },
          onAdOpened: (ad) {
            debugPrint('배너 광고 클릭됨');
          },
          onAdClosed: (ad) {
            debugPrint('배너 광고 닫힘');
          },
        ),
      );

      _bannerAd?.load();
    } catch (e) {
      debugPrint('배너 광고 생성 실패: $e');
    }
  }

  // 배너 광고 재로드
  void reloadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdReady.value = false;
    _loadBannerAd();
  }
}
