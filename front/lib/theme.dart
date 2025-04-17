import "package:flutter/material.dart";
import 'utils/alternative_text_style.dart';

class MaterialTheme {
  const MaterialTheme();

  static final TextTheme _appTextTheme = TextTheme(
    displayLarge: AltTextStyle.displayLarge,
    displayMedium: AltTextStyle.displayMedium,
    displaySmall: AltTextStyle.displaySmall,
    headlineLarge: AltTextStyle.headlineLarge,
    headlineMedium: AltTextStyle.headlineMedium,
    headlineSmall: AltTextStyle.headlineSmall,
    titleLarge: AltTextStyle.titleLarge,
    titleMedium: AltTextStyle.titleMedium,
    titleSmall: AltTextStyle.titleSmall,
    bodyLarge: AltTextStyle.bodyLarge,
    bodyMedium: AltTextStyle.bodyMedium,
    bodySmall: AltTextStyle.bodySmall,
    labelLarge: AltTextStyle.labelLarge,
    labelMedium: AltTextStyle.labelMedium,
    labelSmall: AltTextStyle.labelSmall,
  );

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff405f91),
      surfaceTint: Color(0xff405f91),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd6e3ff),
      onPrimaryContainer: Color(0xff274777),
      secondary: Color(0xff2c638b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffcde5ff),
      onSecondaryContainer: Color(0xff084b72),
      tertiary: Color(0xff7e570f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffddb0),
      onTertiaryContainer: Color(0xff614000),
      error: Color(0xff904a42),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad5),
      onErrorContainer: Color(0xff73342d),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff191c20),
      onSurfaceVariant: Color(0xff44474e),
      outline: Color(0xff74777f),
      outlineVariant: Color(0xffc4c6d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3036),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff001b3e),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff274777),
      secondaryFixed: Color(0xffcde5ff),
      onSecondaryFixed: Color(0xff001d31),
      secondaryFixedDim: Color(0xff99ccfa),
      onSecondaryFixedVariant: Color(0xff084b72),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff281800),
      tertiaryFixedDim: Color(0xfff2be6e),
      onTertiaryFixedVariant: Color(0xff614000),
      surfaceDim: Color(0xffd9d9e0),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3fa),
      surfaceContainer: Color(0xffededf4),
      surfaceContainerHigh: Color(0xffe7e8ee),
      surfaceContainerHighest: Color(0xffe2e2e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff133665),
      surfaceTint: Color(0xff405f91),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff506da0),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff00395a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff3d719b),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff4b3100),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff8f651e),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff5e241d),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffa25850),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff0f1116),
      onSurfaceVariant: Color(0xff33363e),
      outline: Color(0xff4f525a),
      outlineVariant: Color(0xff6a6d75),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3036),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xff506da0),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff365586),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff3d719b),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff205981),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff8f651e),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff734d03),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc5c6cd),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3fa),
      surfaceContainer: Color(0xffe7e8ee),
      surfaceContainerHigh: Color(0xffdcdce3),
      surfaceContainerHighest: Color(0xffd1d1d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff022b5b),
      surfaceTint: Color(0xff405f91),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2a497a),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff002f4b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff0d4d74),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff3e2800),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff644200),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff511a14),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff76362f),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff292c33),
      outlineVariant: Color(0xff464951),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3036),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xff2a497a),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff0d3262),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff0d4d74),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff003655),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff644200),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff472e00),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb8b8bf),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff0f0f7),
      surfaceContainer: Color(0xffe2e2e9),
      surfaceContainerHigh: Color(0xffd3d4db),
      surfaceContainerHighest: Color(0xffc5c6cd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffaac7ff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff09305f),
      primaryContainer: Color(0xff274777),
      onPrimaryContainer: Color(0xffd6e3ff),
      secondary: Color(0xff99ccfa),
      onSecondary: Color(0xff003351),
      secondaryContainer: Color(0xff084b72),
      onSecondaryContainer: Color(0xffcde5ff),
      tertiary: Color(0xfff2be6e),
      onTertiary: Color(0xff442c00),
      tertiaryContainer: Color(0xff614000),
      onTertiaryContainer: Color(0xffffddb0),
      error: Color(0xffffb4aa),
      onError: Color(0xff561e18),
      errorContainer: Color(0xff73342d),
      onErrorContainer: Color(0xffffdad5),
      surface: Color(0xff111318),
      onSurface: Color(0xffe2e2e9),
      onSurfaceVariant: Color(0xffc4c6d0),
      outline: Color(0xff8e9099),
      outlineVariant: Color(0xff44474e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e9),
      inversePrimary: Color(0xff405f91),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff001b3e),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff274777),
      secondaryFixed: Color(0xffcde5ff),
      onSecondaryFixed: Color(0xff001d31),
      secondaryFixedDim: Color(0xff99ccfa),
      onSecondaryFixedVariant: Color(0xff084b72),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff281800),
      tertiaryFixedDim: Color(0xfff2be6e),
      onTertiaryFixedVariant: Color(0xff614000),
      surfaceDim: Color(0xff111318),
      surfaceBright: Color(0xff37393e),
      surfaceContainerLowest: Color(0xff0c0e13),
      surfaceContainerLow: Color(0xff191c20),
      surfaceContainer: Color(0xff1d2024),
      surfaceContainerHigh: Color(0xff282a2f),
      surfaceContainerHighest: Color(0xff33353a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcdddff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff002550),
      primaryContainer: Color(0xff7491c6),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc1e0ff),
      onSecondary: Color(0xff002841),
      secondaryContainer: Color(0xff6395c1),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd69b),
      onTertiary: Color(0xff362200),
      tertiaryContainer: Color(0xffb7893e),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff48130f),
      errorContainer: Color(0xffcc7b71),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff111318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdadce6),
      outline: Color(0xffafb2bb),
      outlineVariant: Color(0xff8d9099),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e9),
      inversePrimary: Color(0xff284878),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff00112b),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff133665),
      secondaryFixed: Color(0xffcde5ff),
      onSecondaryFixed: Color(0xff001322),
      secondaryFixedDim: Color(0xff99ccfa),
      onSecondaryFixedVariant: Color(0xff00395a),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff1b0f00),
      tertiaryFixedDim: Color(0xfff2be6e),
      onTertiaryFixedVariant: Color(0xff4b3100),
      surfaceDim: Color(0xff111318),
      surfaceBright: Color(0xff42444a),
      surfaceContainerLowest: Color(0xff06070c),
      surfaceContainerLow: Color(0xff1b1e22),
      surfaceContainer: Color(0xff26282d),
      surfaceContainerHigh: Color(0xff313238),
      surfaceContainerHighest: Color(0xff3c3e43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffebf0ff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffa5c3fc),
      onPrimaryContainer: Color(0xff000b20),
      secondary: Color(0xffe6f1ff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff95c8f6),
      onSecondaryContainer: Color(0xff000c18),
      tertiary: Color(0xffffedd9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffeeba6a),
      onTertiaryContainer: Color(0xff130900),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220000),
      surface: Color(0xff111318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeeeff9),
      outlineVariant: Color(0xffc0c2cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e9),
      inversePrimary: Color(0xff284878),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff00112b),
      secondaryFixed: Color(0xffcde5ff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff99ccfa),
      onSecondaryFixedVariant: Color(0xff001322),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff2be6e),
      onTertiaryFixedVariant: Color(0xff1b0f00),
      surfaceDim: Color(0xff111318),
      surfaceBright: Color(0xff4e5056),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1d2024),
      surfaceContainer: Color(0xff2e3036),
      surfaceContainerHigh: Color(0xff393b41),
      surfaceContainerHighest: Color(0xff45474c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: _appTextTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        fontFamily: 'PretendardVariable',
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
