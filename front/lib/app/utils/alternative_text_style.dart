import 'package:flutter/material.dart';

class AltTextStyle {
  AltTextStyle._();

  static const _fontFamily = 'PretendardVariable';

  // 기본 TextStyle 정의
  static const TextStyle _baseStyle = TextStyle(
    fontFamily: _fontFamily,
  );

  // weight와 letterSpacing에 따른 스타일 생성 헬퍼 메소드
  static TextStyle _createStyle({
    required double weight,
    required double fontSize,
    required double heightValue, // 테이블의 HEIGHT 값
    required double letterSpacing,
  }) {
    // height 계산 (HEIGHT / SIZE)
    final double height = heightValue / fontSize;
    return _baseStyle.copyWith(
      fontVariations: [FontVariation('wght', weight)],
      fontSize: fontSize,
      height:
          height.isNaN || height.isInfinite ? null : height, // 0으로 나누는 경우 방지
      letterSpacing: letterSpacing,
    );
  }

  // Material Design 3 (2021) Text Styles
  static final TextStyle displayLarge = _createStyle(
    weight: 400, // regular
    fontSize: 57.0,
    heightValue: 64.0,
    letterSpacing: -0.25,
  );
  static final TextStyle displayMedium = _createStyle(
    weight: 400, // regular
    fontSize: 45.0,
    heightValue: 52.0,
    letterSpacing: 0.0,
  );
  static final TextStyle displaySmall = _createStyle(
    weight: 400, // regular
    fontSize: 36.0,
    heightValue: 44.0,
    letterSpacing: 0.0,
  );

  static final TextStyle headlineLarge = _createStyle(
    weight: 400, // regular
    fontSize: 32.0,
    heightValue: 40.0,
    letterSpacing: 0.0,
  );
  static final TextStyle headlineMedium = _createStyle(
    weight: 400, // regular
    fontSize: 28.0,
    heightValue: 36.0,
    letterSpacing: 0.0,
  );
  static final TextStyle headlineSmall = _createStyle(
    weight: 400, // regular
    fontSize: 24.0,
    heightValue: 32.0,
    letterSpacing: 0.0,
  );

  static final TextStyle titleLarge = _createStyle(
    weight: 400, // regular
    fontSize: 22.0,
    heightValue: 28.0,
    letterSpacing: 0.0,
  );
  static final TextStyle titleMedium = _createStyle(
    weight: 500, // medium
    fontSize: 16.0,
    heightValue: 24.0,
    letterSpacing: 0.15,
  );
  static final TextStyle titleSmall = _createStyle(
    weight: 500, // medium
    fontSize: 14.0,
    heightValue: 20.0,
    letterSpacing: 0.1,
  );

  static final TextStyle bodyLarge = _createStyle(
    weight: 400, // regular
    fontSize: 16.0,
    heightValue: 24.0,
    letterSpacing: 0.5,
  );
  static final TextStyle bodyMedium = _createStyle(
    weight: 400, // regular
    fontSize: 14.0,
    heightValue: 20.0,
    letterSpacing: 0.25,
  );
  static final TextStyle bodySmall = _createStyle(
    weight: 400, // regular
    fontSize: 12.0,
    heightValue: 16.0,
    letterSpacing: 0.4,
  );

  static final TextStyle labelLarge = _createStyle(
    weight: 500, // medium
    fontSize: 14.0,
    heightValue: 20.0,
    letterSpacing: 0.1,
  );
  static final TextStyle labelMedium = _createStyle(
    weight: 500, // medium
    fontSize: 12.0,
    heightValue: 16.0,
    letterSpacing: 0.5,
  );
  static final TextStyle labelSmall = _createStyle(
    weight: 500, // medium
    fontSize: 11.0,
    heightValue: 16.0,
    letterSpacing: 0.5,
  );

  // 기존 스타일은 주석 처리 또는 삭제
  /*
  static final TextStyle title1 = _withWeight(700, 32, 1.2);
  static final TextStyle title2 = _withWeight(700, 24, 1.4);
  static final TextStyle title3 = _withWeight(600, 20, 1.2);

  static final TextStyle subtitle1 = _withWeight(600, 24, 1.2);
  static final TextStyle subtitle2 = _withWeight(700, 20, 1.2);
  static final TextStyle subtitle3 = _withWeight(600, 16, 1.1);

  static final TextStyle subtext1 = _withWeight(400, 16, 1.3);
  static final TextStyle subtext2 = _withWeight(400, 14, 1.2);

  static final TextStyle caption = _withWeight(400, 12, 1.2);
  */
}
