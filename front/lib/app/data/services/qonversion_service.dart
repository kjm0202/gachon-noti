import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qonversion_flutter/qonversion_flutter.dart';
import '../../utils/const.dart';
import 'adfree_service.dart';

class QonversionService extends GetxController {
  static QonversionService get to => Get.find();

  // 초기화 상태
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  // 제품 로딩 상태
  final RxBool _isLoadingProducts = false.obs;
  bool get isLoadingProducts => _isLoadingProducts.value;

  // 구매 진행 중 상태
  final RxBool _isPurchasing = false.obs;
  bool get isPurchasing => _isPurchasing.value;

  // 권한 복원 중 상태
  final RxBool _isRestoring = false.obs;
  bool get isRestoring => _isRestoring.value;

  // 사용 가능한 제품들
  final Rx<QOfferings?> _offerings = Rx<QOfferings?>(null);
  QOfferings? get offerings => _offerings.value;

  // 직접 제품 목록 (offerings 대안)
  final Rx<Map<String, QProduct>?> _products = Rx<Map<String, QProduct>?>(null);
  Map<String, QProduct>? get products => _products.value;

  // 광고 제거 제품
  QProduct? get removeAdsProduct {
    try {
      // 먼저 offerings에서 찾기 시도
      final mainOffering = _offerings.value?.main;
      if (mainOffering != null) {
        final product = mainOffering.products
            .where((product) => product.qonversionId == API.removeAdsProductId)
            .firstOrNull;
        if (product != null) {
          debugPrint('Offerings에서 제품 찾음: ${product.qonversionId}');
          return product;
        }
      }

      // offerings에서 찾지 못했으면 products에서 찾기
      final productsMap = _products.value;
      if (productsMap != null) {
        final product = productsMap[API.removeAdsProductId];
        if (product != null) {
          debugPrint('Products에서 제품 찾음: ${product.qonversionId}');
          return product;
        }
      }

      debugPrint('제품을 찾을 수 없음: ${API.removeAdsProductId}');
      return null;
    } catch (e) {
      debugPrint('광고 제거 제품 조회 오류: $e');
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeQonversion();
  }

  // Qonversion 초기화
  Future<void> _initializeQonversion() async {
    try {
      debugPrint('Qonversion 초기화 시작...');

      // Qonversion SDK 초기화
      final config = QonversionConfigBuilder(
              API.qonversionProjectKey, QLaunchMode.subscriptionManagement)
          .build();
      Qonversion.initialize(config);

      _isInitialized.value = true;
      debugPrint('Qonversion SDK 초기화 완료');

      // SDK 초기화 완료 후 충분한 대기 시간 추가
      await Future.delayed(const Duration(seconds: 2));

      // 제품 정보 로드
      await loadOfferings();
    } catch (e) {
      debugPrint('Qonversion 초기화 실패: $e');
      _isInitialized.value = false;
    }
  }

  // 제품 정보 로드
  Future<void> loadOfferings() async {
    if (!_isInitialized.value) {
      debugPrint('Qonversion이 초기화되지 않음');
      return;
    }

    try {
      _isLoadingProducts.value = true;
      debugPrint('제품 정보 로드 중...');

      // 먼저 offerings 방법 시도
      try {
        final offerings = await Qonversion.getSharedInstance().offerings();
        _offerings.value = offerings;

        debugPrint('Offerings 로드 성공');
        debugPrint('전체 오퍼링 수: ${offerings.availableOfferings.length}');

        // 메인 오퍼링 정보 상세 로그
        if (offerings.main != null) {
          debugPrint('메인 오퍼링 ID: ${offerings.main!.id}');
          debugPrint('메인 오퍼링 제품 수: ${offerings.main!.products.length}');

          // 모든 제품 정보 출력
          for (final product in offerings.main!.products) {
            debugPrint(
                '제품 ID: ${product.qonversionId}, Store ID: ${product.storeId}, 가격: ${product.prettyPrice}');
          }
        } else {
          debugPrint('메인 오퍼링이 없습니다.');
        }

        // 모든 오퍼링 정보 출력
        debugPrint('사용 가능한 모든 오퍼링:');
        for (final offering in offerings.availableOfferings) {
          debugPrint(
              '- 오퍼링 ID: ${offering.id}, 제품 수: ${offering.products.length}');
          for (final product in offering.products) {
            debugPrint(
                '  * 제품: ${product.qonversionId} (${product.storeId}) - ${product.prettyPrice}');
          }
        }
      } catch (offeringsError) {
        debugPrint('Offerings 로드 실패: $offeringsError');
        debugPrint('Products 방법으로 대안 시도...');

        // offerings 실패 시 products 방법으로 대안 시도
        try {
          final products = await Qonversion.getSharedInstance().products();
          _products.value = products;

          debugPrint('Products 로드 성공');
          debugPrint('전체 제품 수: ${products.length}');

          // 모든 제품 정보 출력
          for (final entry in products.entries) {
            final product = entry.value;
            debugPrint(
                '제품 ID: ${product.qonversionId}, Store ID: ${product.storeId}, 가격: ${product.prettyPrice}');
          }
        } catch (productsError) {
          debugPrint('Products 로드도 실패: $productsError');
          throw Exception('제품 정보를 가져올 수 없습니다. Offerings와 Products 모두 실패했습니다.');
        }
      }

      // 광고 제거 제품 찾기 시도
      debugPrint('찾는 제품 ID: ${API.removeAdsProductId}');
      final removeAdsProduct = this.removeAdsProduct;
      if (removeAdsProduct != null) {
        debugPrint(
            '광고 제거 제품 찾음: ${removeAdsProduct.qonversionId} - ${removeAdsProduct.prettyPrice}');
      } else {
        debugPrint(
            '광고 제거 제품을 찾을 수 없습니다. "${API.removeAdsProductId}" ID를 가진 제품이 없습니다.');
        debugPrint('Qonversion 대시보드에서 다음을 확인해주세요:');
        debugPrint('1. "${API.removeAdsProductId}" ID로 제품이 생성되어 있는지');
        debugPrint('2. 제품이 Offering에 연결되어 있는지');
        debugPrint('3. 앱 번들 ID가 대시보드와 일치하는지');
      }
    } catch (e) {
      debugPrint('제품 정보 로드 실패: $e');
      debugPrint('에러 스택 트레이스: ${StackTrace.current}');
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  // 광고 제거 구매
  Future<bool> purchaseRemoveAds() async {
    if (!_isInitialized.value) {
      Get.snackbar('오류', 'Qonversion이 초기화되지 않았습니다.');
      return false;
    }

    var product = removeAdsProduct;

    // 제품이 없으면 다시 로드 시도
    if (product == null) {
      debugPrint('제품 정보가 없어서 다시 로드를 시도합니다...');
      await loadOfferings();
      product = removeAdsProduct;
    }

    if (product == null) {
      debugPrint('제품을 찾을 수 없습니다. Qonversion 대시보드에서 제품 설정을 확인해주세요.');
      Get.snackbar('오류', '구매할 수 있는 제품이 없습니다.\n제품 설정을 확인해주세요.');
      return false;
    }

    try {
      _isPurchasing.value = true;
      debugPrint('광고 제거 구매 시작...');
      debugPrint(
          '구매할 제품: ${product.qonversionId} (${product.storeId}) - ${product.prettyPrice}');

      final entitlements =
          await Qonversion.getSharedInstance().purchaseProduct(product);

      // 구매 성공 확인
      if (entitlements.containsKey(API.adFreeEntitlementId) &&
          entitlements[API.adFreeEntitlementId]?.isActive == true) {
        debugPrint('광고 제거 구매 성공');

        // AdFreeService 상태 즉시 업데이트
        if (Get.isRegistered<AdFreeService>()) {
          final adFreeService = Get.find<AdFreeService>();
          adFreeService.updateAdFreeStatus(true);
          debugPrint('AdFreeService 상태 즉시 업데이트 완료');
        }

        Get.snackbar('구매 완료', '광고가 제거되었습니다!',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        debugPrint('구매 완료되었지만 권한이 활성화되지 않음');
        debugPrint('반환된 권한들: ${entitlements.keys.join(', ')}');
        Get.snackbar('알림', '구매가 처리 중입니다. 잠시 후 다시 확인해주세요.');
        return false;
      }
    } on QPurchaseException catch (e) {
      if (e.isUserCancelled) {
        debugPrint('사용자가 구매를 취소함');
        Get.snackbar('취소', '구매가 취소되었습니다.');
      } else {
        debugPrint('구매 실패: $e');
        Get.snackbar('구매 실패', '구매 중 오류가 발생했습니다.');
      }
      return false;
    } catch (e) {
      debugPrint('구매 중 예외 발생: $e');
      Get.snackbar('오류', '구매 중 예상치 못한 오류가 발생했습니다.');
      return false;
    } finally {
      _isPurchasing.value = false;
    }
  }

  // 권한 복원
  Future<void> restorePurchases() async {
    if (!_isInitialized.value) {
      Get.snackbar('오류', 'Qonversion이 초기화되지 않았습니다.');
      return;
    }

    try {
      _isRestoring.value = true;
      debugPrint('구매 복원 시작...');

      final result = await Qonversion.getSharedInstance().restore();

      if (result.containsKey(API.adFreeEntitlementId) &&
          result[API.adFreeEntitlementId]?.isActive == true) {
        debugPrint('광고 제거 권한 복원 성공');
        Get.snackbar('복원 완료', '광고 제거 권한이 복원되었습니다!',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        debugPrint('복원할 권한이 없음');
        Get.snackbar('복원 결과', '복원할 구매 내역이 없습니다.');
      }
    } catch (e) {
      debugPrint('구매 복원 실패: $e');
      Get.snackbar('복원 실패', '구매 복원 중 오류가 발생했습니다.');
    } finally {
      _isRestoring.value = false;
    }
  }

  // 현재 권한 상태 확인
  Future<Map<String, QEntitlement>> checkEntitlements() async {
    if (!_isInitialized.value) {
      throw Exception('Qonversion이 초기화되지 않음');
    }

    try {
      debugPrint('권한 상태 확인 중...');
      return await Qonversion.getSharedInstance().checkEntitlements();
    } catch (e) {
      debugPrint('권한 상태 확인 실패: $e');
      rethrow;
    }
  }

  // 광고 제거 권한 활성화 여부 확인
  Future<bool> isAdFreeActive() async {
    try {
      final entitlements = await checkEntitlements();
      final adFreeEntitlement = entitlements[API.adFreeEntitlementId];
      final isActive = adFreeEntitlement?.isActive ?? false;
      debugPrint('광고 제거 권한 활성화 상태: $isActive');
      return isActive;
    } catch (e) {
      debugPrint('광고 제거 권한 확인 실패: $e');
      return false; // 에러 시 광고 표시
    }
  }

  // 제품 정보 수동 새로고침
  Future<void> refreshOfferings() async {
    debugPrint('제품 정보 수동 새로고침 시작...');
    await loadOfferings();
  }
}
