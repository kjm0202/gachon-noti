import 'package:flutter/material.dart';

// 모바일 플랫폼용 스텁 - 실제로는 사용되지 않음
class AdfitBannerWidget extends StatelessWidget {
  final String adUnit;
  final double width;
  final double height;

  const AdfitBannerWidget({
    super.key,
    required this.adUnit,
    this.width = 320,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    // 모바일에서는 표시하지 않음
    return const SizedBox.shrink();
  }
}
