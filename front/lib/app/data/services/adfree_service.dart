import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'qonversion_service.dart';

class AdFreeService extends GetxController {
  static AdFreeService get to => Get.find();

  // 광고 제거 상태
  final RxBool _isAdFree = false.obs;
  bool get isAdFree => _isAdFree.value;

  @override
  void onInit() {
    super.onInit();
    _loadAdFreeStatus();
  }

  // 광고 제거 상태 로드 (Qonversion에서 로드)
  Future<void> _loadAdFreeStatus() async {
    try {
      // QonversionService가 등록되어 있는지 확인
      if (Get.isRegistered<QonversionService>()) {
        final qonversionService = Get.find<QonversionService>();

        // Qonversion이 초기화될 때까지 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));

        // Qonversion에서 광고 제거 상태 확인
        final isAdFree = await qonversionService.isAdFreeActive();
        _isAdFree.value = isAdFree;
        debugPrint('Qonversion에서 광고 제거 상태 로드: ${_isAdFree.value}');
      } else {
        debugPrint('QonversionService가 등록되지 않음');
        _isAdFree.value = false;
      }
    } catch (e) {
      debugPrint('광고 제거 상태 로드 실패: $e');
      _isAdFree.value = false;
    }
  }

  // 광고 제거 상태 업데이트
  void updateAdFreeStatus(bool isAdFree) {
    final previousStatus = _isAdFree.value;
    _isAdFree.value = isAdFree;

    debugPrint('광고 제거 상태 업데이트: $previousStatus -> $isAdFree');

    if (previousStatus != isAdFree) {
      // 상태가 변경된 경우 UI 강제 업데이트
      update();
      debugPrint('UI 강제 업데이트 트리거됨');

      if (isAdFree) {
        debugPrint('광고 제거 상태로 변경됨 - 모든 배너가 숨겨져야 함');
      } else {
        debugPrint('광고 표시 상태로 변경됨 - 배너가 표시되어야 함');
      }
    }

    // TODO: SharedPreferences에 저장
  }

  // 광고를 표시해야 하는지 확인
  bool shouldShowAds() {
    return !_isAdFree.value;
  }

  // 광고 제거 직접 구매 (Qonversion 구현)
  Future<void> purchaseRemoveAds() async {
    try {
      debugPrint('광고 제거 구매 시작...');

      // QonversionService가 등록되어 있는지 확인
      if (!Get.isRegistered<QonversionService>()) {
        Get.snackbar('오류', 'QonversionService가 초기화되지 않았습니다.');
        return;
      }

      final qonversionService = Get.find<QonversionService>();

      // 직접 구매 진행 (Google Play/App Store 결제 팝업 표시)
      final success = await qonversionService.purchaseRemoveAds();

      if (success) {
        // 구매 성공 시 상태 업데이트 (이미 QonversionService에서 업데이트됨)
        // 추가 확인을 위해 권한 상태 다시 로드
        await Future.delayed(const Duration(milliseconds: 500)); // 처리 대기
        await _loadAdFreeStatus();

        debugPrint('구매 성공 후 최종 광고 제거 상태: ${_isAdFree.value}');

        // UI 강제 업데이트
        update();
      }
    } catch (e) {
      debugPrint('광고 제거 구매 실패: $e');
      Get.snackbar('오류', '구매 중 오류가 발생했습니다.');
    }
  }

  // 구매 복원 (Qonversion 구현)
  Future<void> restorePurchases() async {
    try {
      debugPrint('구매 복원 시작...');

      // QonversionService가 등록되어 있는지 확인
      if (!Get.isRegistered<QonversionService>()) {
        Get.snackbar('오류', 'QonversionService가 초기화되지 않았습니다.');
        return;
      }

      final qonversionService = Get.find<QonversionService>();

      // Qonversion을 통해 구매 복원
      await qonversionService.restorePurchases();

      // 복원 후 상태 다시 확인
      await _loadAdFreeStatus();
    } catch (e) {
      debugPrint('구매 복원 실패: $e');
      Get.snackbar('복원 실패', '구매 복원 중 오류가 발생했습니다.');
    }
  }
}
