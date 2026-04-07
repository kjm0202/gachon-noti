import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/admob_service.dart';
import '../../../data/services/adfree_service.dart';
import '../controllers/webview_controller.dart';

class WebviewView extends GetView<WebViewController2> {
  const WebviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.title.value.isEmpty ? '공지사항' : controller.title.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await controller.webViewController.canGoBack()) {
              controller.webViewController.goBack();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.webViewController.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 로딩 인디케이터
          Obx(() => controller.isLoading.value
              ? const LinearProgressIndicator()
              : const SizedBox.shrink()),
          // 웹뷰
          Expanded(
            child: WebViewWidget(
              controller: controller.webViewController,
            ),
          ),
          // 하단 고정 AdMob 배너
          _AdmobWebviewBanner(),
        ],
      ),
    );
  }
}

/// 웹뷰 전용 AdMob 배너 (하단 고정)
class _AdmobWebviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdMobService>()) {
      return const SizedBox.shrink();
    }

    final adMobService = Get.find<AdMobService>();

    // AdFreeService 체크
    if (Get.isRegistered<AdFreeService>()) {
      return Obx(() {
        final adFreeService = Get.find<AdFreeService>();
        if (!adFreeService.shouldShowAds()) {
          return const SizedBox.shrink();
        }
        return _buildBanner(context, adMobService);
      });
    }

    return _buildBanner(context, adMobService);
  }

  Widget _buildBanner(BuildContext context, AdMobService adMobService) {
    return Obx(() {
      if (!adMobService.isWebviewBannerAdReady ||
          adMobService.webviewBannerAd == null) {
        return const SizedBox.shrink();
      }

      final ad = adMobService.webviewBannerAd!;
      return Container(
        alignment: Alignment.center,
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border(
            top: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: AdWidget(ad: ad),
      );
    });
  }
}
