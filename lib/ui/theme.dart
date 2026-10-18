import 'package:flutter/material.dart';

import 'brand.dart';

/// Semantic colours for the dose cards, which Material's scheme has no slot
/// for. Ported from the web app's CSS custom properties.
@immutable
class DoseColors extends ThemeExtension<DoseColors> {
  const DoseColors({
    required this.ok,
    required this.okBg,
    required this.caution,
    required this.cautionBg,
    required this.bad,
    required this.badBg,
    required this.muted,
    required this.soft,
    required this.line,
    required this.primaryBg,
    required this.pillInk,
    required this.accent,
    required this.headerTop,
    required this.headerBottom,
    required this.onHeader,
    required this.onHeaderMuted,
  });

  final Color ok;
  final Color okBg;
  final Color caution;
  final Color cautionBg;
  final Color bad;
  final Color badBg;

  /// Secondary text.
  final Color muted;

  /// Input and inert card fill.
  final Color soft;
  final Color line;
  final Color primaryBg;

  /// Text on the "ไม่แนะนำ" / "ระวัง" pills.
  final Color pillInk;

  /// Peach accent: the logo mark and small highlights.
  final Color accent;

  /// The header band's gradient, dark end to darker end.
  final Color headerTop;
  final Color headerBottom;

  /// Text drawn on the header band.
  final Color onHeader;
  final Color onHeaderMuted;

  // Dose colours stay green/amber/red: they carry clinical meaning and must
  // not follow the brand. Only the neutrals move to the plum/lilac palette.
  static const light = DoseColors(
    ok: Color(0xFF12804F),
    okBg: Color(0xFFE4F5EC),
    caution: Color(0xFF9A5A00),
    cautionBg: Color(0xFFFDF0DC),
    bad: Color(0xFFB3261E),
    badBg: Color(0xFFFDEAE8),
    muted: Color(0xFF6B6480),
    soft: Color(0xFFF1ECFA),
    line: Color(0xFFE3DCF2),
    primaryBg: Color(0xFFEDE4FB),
    pillInk: Colors.white,
    accent: Color(0xFFF08A6B),
    headerTop: Color(0xFF3B2A52),
    headerBottom: Color(0xFF2E2140),
    onHeader: Color(0xFFF6F1FA),
    onHeaderMuted: Color(0xFFC9BCDC),
  );

  /// Teal counterpart of [light] — the original web-app palette.
  static const lightTeal = DoseColors(
    ok: Color(0xFF12804F),
    okBg: Color(0xFFE4F5EC),
    caution: Color(0xFF9A5A00),
    cautionBg: Color(0xFFFDF0DC),
    bad: Color(0xFFB3261E),
    badBg: Color(0xFFFDEAE8),
    muted: Color(0xFF5A717A),
    soft: Color(0xFFEDF5F6),
    line: Color(0xFFD5E0E5),
    primaryBg: Color(0xFFDFF1F3),
    pillInk: Colors.white,
    accent: Color(0xFF7FD9E2),
    headerTop: Color(0xFF0E6C76),
    headerBottom: Color(0xFF09525A),
    onHeader: Color(0xFFF2FBFC),
    onHeaderMuted: Color(0xFFA9D6DB),
  );

  /// Teal counterpart of [dark].
  static const darkTeal = DoseColors(
    ok: Color(0xFF4FD3A0),
    okBg: Color(0xFF12342A),
    caution: Color(0xFFF2BB52),
    cautionBg: Color(0xFF352A0E),
    bad: Color(0xFFFF8A80),
    badBg: Color(0xFF3B1816),
    muted: Color(0xFF9BB2BB),
    soft: Color(0xFF16292F),
    line: Color(0xFF26404B),
    primaryBg: Color(0xFF12363D),
    pillInk: Color(0xFF14100A),
    accent: Color(0xFF4CC6D2),
    headerTop: Color(0xFF0D3A42),
    headerBottom: Color(0xFF0A2A30),
    onHeader: Color(0xFFE6F1F4),
    onHeaderMuted: Color(0xFF9BB2BB),
  );

  static const dark = DoseColors(
    ok: Color(0xFF4FD3A0),
    okBg: Color(0xFF12342A),
    caution: Color(0xFFF2BB52),
    cautionBg: Color(0xFF352A0E),
    bad: Color(0xFFFF8A80),
    badBg: Color(0xFF3B1816),
    muted: Color(0xFFA99CC0),
    soft: Color(0xFF241A33),
    line: Color(0xFF3A2D4F),
    primaryBg: Color(0xFF2C2040),
    pillInk: Color(0xFF14100A),
    accent: Color(0xFFF59C80),
    headerTop: Color(0xFF2A1E3C),
    headerBottom: Color(0xFF1E1530),
    onHeader: Color(0xFFF6F1FA),
    onHeaderMuted: Color(0xFFBDAFD2),
  );

  @override
  DoseColors copyWith({
    Color? ok,
    Color? okBg,
    Color? caution,
    Color? cautionBg,
    Color? bad,
    Color? badBg,
    Color? muted,
    Color? soft,
    Color? line,
    Color? primaryBg,
    Color? pillInk,
    Color? accent,
    Color? headerTop,
    Color? headerBottom,
    Color? onHeader,
    Color? onHeaderMuted,
  }) {
    return DoseColors(
      ok: ok ?? this.ok,
      okBg: okBg ?? this.okBg,
      caution: caution ?? this.caution,
      cautionBg: cautionBg ?? this.cautionBg,
      bad: bad ?? this.bad,
      badBg: badBg ?? this.badBg,
      muted: muted ?? this.muted,
      soft: soft ?? this.soft,
      line: line ?? this.line,
      primaryBg: primaryBg ?? this.primaryBg,
      pillInk: pillInk ?? this.pillInk,
      accent: accent ?? this.accent,
      headerTop: headerTop ?? this.headerTop,
      headerBottom: headerBottom ?? this.headerBottom,
      onHeader: onHeader ?? this.onHeader,
      onHeaderMuted: onHeaderMuted ?? this.onHeaderMuted,
    );
  }

  @override
  DoseColors lerp(DoseColors? other, double t) {
    if (other == null) return this;
    return DoseColors(
      ok: Color.lerp(ok, other.ok, t)!,
      okBg: Color.lerp(okBg, other.okBg, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      cautionBg: Color.lerp(cautionBg, other.cautionBg, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      badBg: Color.lerp(badBg, other.badBg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      line: Color.lerp(line, other.line, t)!,
      primaryBg: Color.lerp(primaryBg, other.primaryBg, t)!,
      pillInk: Color.lerp(pillInk, other.pillInk, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      headerTop: Color.lerp(headerTop, other.headerTop, t)!,
      headerBottom: Color.lerp(headerBottom, other.headerBottom, t)!,
      onHeader: Color.lerp(onHeader, other.onHeader, t)!,
      onHeaderMuted: Color.lerp(onHeaderMuted, other.onHeaderMuted, t)!,
    );
  }
}

/// Convenience accessor so widgets read `context.dose.bad`.
extension DoseColorsOf on BuildContext {
  DoseColors get dose => Theme.of(this).extension<DoseColors>()!;
}

const _fontFamily = 'IBMPlexSansThai';

ThemeData buildTheme(Brightness brightness, [Brand brand = Brand.plum]) {
  final isDark = brightness == Brightness.dark;
  final isTeal = brand == Brand.teal;
  final dose = switch ((isDark, isTeal)) {
    (true, true) => DoseColors.darkTeal,
    (true, false) => DoseColors.dark,
    (false, true) => DoseColors.lightTeal,
    (false, false) => DoseColors.light,
  };

  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D7A85),
        brightness: brightness,
      ).copyWith(
        primary: isDark ? const Color(0xFF4CC6D2) : const Color(0xFF0D7A85),
        onPrimary: isDark ? const Color(0xFF052A30) : Colors.white,
        surface: isDark ? const Color(0xFF13242B) : Colors.white,
        onSurface: isDark ? const Color(0xFFE6F1F4) : const Color(0xFF112A31),
        outline: dose.line,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: isDark
        ? (isTeal ? const Color(0xFF0B161B) : const Color(0xFF140E1F))
        : (isTeal ? const Color(0xFFEFF4F6) : const Color(0xFFF7F3FB)),
  );

  return base.copyWith(
    extensions: [dose],
    textTheme: base.textTheme.apply(
      fontFamily: _fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dose.soft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      hintStyle: TextStyle(color: dose.muted, fontFamily: _fontFamily),
      suffixStyle: TextStyle(
        color: dose.muted,
        fontFamily: _fontFamily,
        fontSize: 14,
      ),
      // Units read as part of the field, so they show even when empty.
      floatingLabelBehavior: FloatingLabelBehavior.never,
      // Borderless until focused, matching the mockup's flat fields.
      border: _inputBorder(Colors.transparent),
      enabledBorder: _inputBorder(Colors.transparent),
      focusedBorder: _inputBorder(scheme.primary, width: 1.6),
      errorBorder: _inputBorder(dose.bad),
      focusedErrorBorder: _inputBorder(dose.bad, width: 1.6),
      errorStyle: TextStyle(color: dose.bad, fontFamily: _fontFamily),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: isDark ? scheme.primary : dose.headerBottom,
        foregroundColor: isDark ? scheme.onPrimary : dose.onHeader,
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : Colors.transparent,
      ),
      side: BorderSide(color: dose.muted, width: 1.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1.5}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}
