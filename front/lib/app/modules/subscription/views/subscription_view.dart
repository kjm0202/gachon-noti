import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/alternative_text_style.dart';
import '../controllers/subscription_controller.dart';
import '../../home/controllers/home_controller.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 저장/취소 버튼의 높이를 계산합니다.
      // 버튼 높이 + 패딩 + 마진 = 약 100
      final bottomButtonsHeight = controller.hasChanges.value ? 100.0 : 0.0;

      return Stack(
        children: [
          ListView(
            // 변경사항이 있을 때 하단에 패딩 추가
            padding: EdgeInsets.only(bottom: bottomButtonsHeight),
            children: controller.allBoards.map((boardId) {
              final subscribed = controller.isBoardSubscribed(boardId);
              return Obx(() => CheckboxListTile(
                    title: Text(controller.getBoardName(boardId)),
                    subtitle: Text(controller.getBoardDescription(boardId)),
                    value: subscribed,
                    onChanged: controller.loading.value
                        ? null // 저장 중에는 체크박스 비활성화
                        : (val) {
                            if (val != null) {
                              controller.toggleBoardTemp(boardId);
                            }
                          },
                  ));
            }).toList(),
          ),

          // 변경사항이 있을 때만 저장/취소 버튼 표시
          Obx(() {
            if (controller.hasChanges.value) {
              return Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: Text(
                              '취소',
                              style: AltTextStyle.bodyLarge
                                  .copyWith(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            onPressed: controller.loading.value
                                ? null
                                : () => controller.cancelChanges(),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: controller.loading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              '저장',
                              style: AltTextStyle.bodyLarge
                                  .copyWith(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            onPressed:
                                controller.loading.value ? null : _saveChanges,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
        ],
      );
    });
  }

  Future<void> _saveChanges() async {
    final success = await controller.saveAllSubscriptions();

    if (success) {
      // 홈 컨트롤러의 handleSubscriptionChange 메서드 호출
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        await homeController.handleSubscriptionChange();
      }
    }
  }
}
