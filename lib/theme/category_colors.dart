import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Deterministic category color assignment shared by [CategoryTag] and the
/// analytics charts, so a category's tag color and chart slice color always
/// match.
///
/// The three sanctioned "category variety" tokens (tertiaryContainer ~355°,
/// secondaryContainer ~161°, primaryContainer ~39° hue) are spread roughly
/// 120-200° apart on the color wheel, leaving two wide gaps. Blending each
/// toward onSurface (the previous approach) only changed lightness/
/// saturation within the same hue family, so adjacent categories could land
/// on near-identical hues (e.g. a vivid green next to a desaturated green).
/// Instead, five extra hues are inserted into those gaps — computed, not
/// arbitrary hex — so all eight palette entries stay roughly 40-50° apart
/// and read as distinct even in small chart swatches.
abstract final class CategoryColors {
  static const List<Color> _base = [
    AppColors.tertiaryContainer,
    AppColors.secondaryContainer,
    AppColors.primaryContainer,
  ];

  static const List<double> _insertedHues = [80, 122, 210, 258, 307];
  static const double _insertedSaturation = 0.70;
  static const double _insertedLightness = 0.58;

  static List<Color> get palette => [
        ..._base,
        for (final hue in _insertedHues)
          HSLColor.fromAHSL(1, hue, _insertedSaturation, _insertedLightness)
              .toColor(),
      ];

  static Color forCategoryId(String categoryId) {
    final colors = palette;
    return colors[categoryId.hashCode.abs() % colors.length];
  }
}
