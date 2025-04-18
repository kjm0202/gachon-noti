import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff555a92),
      surfaceTint: Color(0xff555a92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe0e0ff),
      onPrimaryContainer: Color(0xff3d4279),
      secondary: Color(0xff835414),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffffddb9),
      onSecondaryContainer: Color(0xff663e00),
      tertiary: Color(0xff3e6837),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffbef0b2),
      onTertiaryContainer: Color(0xff265022),
      error: Color(0xff904a42),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad5),
      onErrorContainer: Color(0xff73342d),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff1b1b21),
      onSurfaceVariant: Color(0xff46464f),
      outline: Color(0xff777680),
      outlineVariant: Color(0xffc7c5d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inversePrimary: Color(0xffbec2ff),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff10144b),
      primaryFixedDim: Color(0xffbec2ff),
      onPrimaryFixedVariant: Color(0xff3d4279),
      secondaryFixed: Color(0xffffddb9),
      onSecondaryFixed: Color(0xff2b1700),
      secondaryFixedDim: Color(0xfff9bb72),
      onSecondaryFixedVariant: Color(0xff663e00),
      tertiaryFixed: Color(0xffbef0b2),
      onTertiaryFixed: Color(0xff002202),
      tertiaryFixedDim: Color(0xffa3d397),
      onTertiaryFixedVariant: Color(0xff265022),
      surfaceDim: Color(0xffdbd9e0),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fa),
      surfaceContainer: Color(0xffefedf4),
      surfaceContainerHigh: Color(0xffeae7ef),
      surfaceContainerHighest: Color(0xffe4e1e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff2c3167),
      surfaceTint: Color(0xff555a92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6368a2),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff4f2f00),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff946322),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff153e13),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff4c7745),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff5e241d),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffa25850),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff111116),
      onSurfaceVariant: Color(0xff35353e),
      outline: Color(0xff52525b),
      outlineVariant: Color(0xff6d6c76),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inversePrimary: Color(0xffbec2ff),
      primaryFixed: Color(0xff6368a2),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff4b5088),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff946322),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff784b0a),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff4c7745),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff345e2f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc8c5cd),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fa),
      surfaceContainer: Color(0xffeae7ef),
      surfaceContainerHigh: Color(0xffdedce3),
      surfaceContainerHighest: Color(0xffd3d0d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff22275c),
      surfaceTint: Color(0xff555a92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff3f447b),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff422600),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff694000),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff093409),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff295224),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff511a14),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff76362f),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2b2b34),
      outlineVariant: Color(0xff494851),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inversePrimary: Color(0xffbec2ff),
      primaryFixed: Color(0xff3f447b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff282d63),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff694000),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff4b2c00),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff295224),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff113b0f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbab8bf),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff2eff7),
      surfaceContainer: Color(0xffe4e1e9),
      surfaceContainerHigh: Color(0xffd6d3db),
      surfaceContainerHighest: Color(0xffc8c5cd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbec2ff),
      surfaceTint: Color(0xffbec2ff),
      onPrimary: Color(0xff262b61),
      primaryContainer: Color(0xff3d4279),
      onPrimaryContainer: Color(0xffe0e0ff),
      secondary: Color(0xfff9bb72),
      onSecondary: Color(0xff482a00),
      secondaryContainer: Color(0xff663e00),
      onSecondaryContainer: Color(0xffffddb9),
      tertiary: Color(0xffa3d397),
      onTertiary: Color(0xff0e380d),
      tertiaryContainer: Color(0xff265022),
      onTertiaryContainer: Color(0xffbef0b2),
      error: Color(0xffffb4aa),
      onError: Color(0xff561e18),
      errorContainer: Color(0xff73342d),
      onErrorContainer: Color(0xffffdad5),
      surface: Color(0xff131318),
      onSurface: Color(0xffe4e1e9),
      onSurfaceVariant: Color(0xffc7c5d0),
      outline: Color(0xff91909a),
      outlineVariant: Color(0xff46464f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inversePrimary: Color(0xff555a92),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff10144b),
      primaryFixedDim: Color(0xffbec2ff),
      onPrimaryFixedVariant: Color(0xff3d4279),
      secondaryFixed: Color(0xffffddb9),
      onSecondaryFixed: Color(0xff2b1700),
      secondaryFixedDim: Color(0xfff9bb72),
      onSecondaryFixedVariant: Color(0xff663e00),
      tertiaryFixed: Color(0xffbef0b2),
      onTertiaryFixed: Color(0xff002202),
      tertiaryFixedDim: Color(0xffa3d397),
      onTertiaryFixedVariant: Color(0xff265022),
      surfaceDim: Color(0xff131318),
      surfaceBright: Color(0xff39393f),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1b1b21),
      surfaceContainer: Color(0xff1f1f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff34343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd8d9ff),
      surfaceTint: Color(0xffbec2ff),
      onPrimary: Color(0xff1b2055),
      primaryContainer: Color(0xff878cc8),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffffd5a8),
      onSecondary: Color(0xff392000),
      secondaryContainer: Color(0xffbd8642),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffb8e9ac),
      onTertiary: Color(0xff022d04),
      tertiaryContainer: Color(0xff6f9c66),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff48130f),
      errorContainer: Color(0xffcc7b71),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff131318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdddbe6),
      outline: Color(0xffb2b1bb),
      outlineVariant: Color(0xff908f99),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inversePrimary: Color(0xff3e437a),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff040741),
      primaryFixedDim: Color(0xffbec2ff),
      onPrimaryFixedVariant: Color(0xff2c3167),
      secondaryFixed: Color(0xffffddb9),
      onSecondaryFixed: Color(0xff1d0e00),
      secondaryFixedDim: Color(0xfff9bb72),
      onSecondaryFixedVariant: Color(0xff4f2f00),
      tertiaryFixed: Color(0xffbef0b2),
      onTertiaryFixed: Color(0xff001601),
      tertiaryFixedDim: Color(0xffa3d397),
      onTertiaryFixedVariant: Color(0xff153e13),
      surfaceDim: Color(0xff131318),
      surfaceBright: Color(0xff44444a),
      surfaceContainerLowest: Color(0xff07070c),
      surfaceContainerLow: Color(0xff1d1d23),
      surfaceContainer: Color(0xff27272d),
      surfaceContainerHigh: Color(0xff323238),
      surfaceContainerHighest: Color(0xff3d3d43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff0eeff),
      surfaceTint: Color(0xffbec2ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffb9befd),
      onPrimaryContainer: Color(0xff00013a),
      secondary: Color(0xffffeddd),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xfff5b76e),
      onSecondaryContainer: Color(0xff150900),
      tertiary: Color(0xffccfdbe),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff9fcf94),
      onTertiaryContainer: Color(0xff000f00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220000),
      surface: Color(0xff131318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff1eefa),
      outlineVariant: Color(0xffc3c1cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inversePrimary: Color(0xff3e437a),
      primaryFixed: Color(0xffe0e0ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffbec2ff),
      onPrimaryFixedVariant: Color(0xff040741),
      secondaryFixed: Color(0xffffddb9),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xfff9bb72),
      onSecondaryFixedVariant: Color(0xff1d0e00),
      tertiaryFixed: Color(0xffbef0b2),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa3d397),
      onTertiaryFixedVariant: Color(0xff001601),
      surfaceDim: Color(0xff131318),
      surfaceBright: Color(0xff504f56),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1f1f25),
      surfaceContainer: Color(0xff303036),
      surfaceContainerHigh: Color(0xff3b3b41),
      surfaceContainerHighest: Color(0xff47464c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
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
