import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm paper-and-terracotta palette of the Spiritual SOS design.
@immutable
class SosColors extends ThemeExtension<SosColors> {
  const SosColors({
    required this.paper,
    required this.card,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.blush,
    required this.sand,
    required this.line,
    required this.shadow,
  });

  /// Page background.
  final Color paper;

  /// Raised cards.
  final Color card;

  /// Main text.
  final Color ink;

  /// Secondary text and inactive icons.
  final Color muted;

  /// Terracotta: quote marks, rules, selected states.
  final Color accent;
  final Color onAccent;

  /// Soft tinted panels (the reflection box, the sun on the welcome screen).
  final Color blush;

  /// Mid tone used in the illustrations.
  final Color sand;

  /// Hairlines and outlines.
  final Color line;
  final Color shadow;

  static const light = SosColors(
    paper: Color(0xFFF6EFE6),
    card: Color(0xFFFBF7F1),
    ink: Color(0xFF221C18),
    muted: Color(0xFF7A6E64),
    accent: Color(0xFFB4532F),
    onAccent: Color(0xFFFFFFFF),
    blush: Color(0xFFF0E1D2),
    sand: Color(0xFFDCC0A5),
    line: Color(0xFFE4D6C7),
    shadow: Color(0x1F8A5A3A),
  );

  static const dark = SosColors(
    paper: Color(0xFF1B1613),
    card: Color(0xFF26201B),
    ink: Color(0xFFF4EADF),
    muted: Color(0xFFB3A597),
    accent: Color(0xFFE38B65),
    onAccent: Color(0xFF2A140A),
    blush: Color(0xFF362A22),
    sand: Color(0xFF5E4636),
    line: Color(0xFF3B3129),
    shadow: Color(0x66000000),
  );

  static SosColors of(BuildContext context) =>
      Theme.of(context).extension<SosColors>()!;

  @override
  SosColors copyWith() => this;

  @override
  SosColors lerp(SosColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SosColors(
      paper: mix(paper, other.paper),
      card: mix(card, other.card),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      blush: mix(blush, other.blush),
      sand: mix(sand, other.sand),
      line: mix(line, other.line),
      shadow: mix(shadow, other.shadow),
    );
  }
}

/// The serif used for titles and scripture.
TextStyle serif({
  double fontSize = 18,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
  FontStyle? fontStyle,
  double? letterSpacing,
}) =>
    GoogleFonts.ebGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );

/// Small spaced capitals, e.g. "DAILY WISDOM".
TextStyle eyebrow(Color color, {double fontSize = 11}) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: fontSize * 0.42,
      color: color,
    );

ThemeData _build(SosColors c, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.muted,
    surface: c.paper,
    onSurface: c.ink,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.card,
    surfaceContainerLow: c.card,
    surfaceContainer: c.card,
    surfaceContainerHigh: c.card,
    surfaceContainerHighest: c.blush,
    outline: c.muted,
    outlineVariant: c.line,
  );
  final base = ThemeData(colorScheme: scheme, brightness: brightness);
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(100));
  return base.copyWith(
    scaffoldBackgroundColor: c.paper,
    extensions: [c],
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: serif(fontSize: 22, color: c.ink),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.ink.withValues(alpha: 0.55)),
        shape: pill,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        shape: pill,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 26),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        shape: pill,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      hintStyle: TextStyle(color: c.muted.withValues(alpha: 0.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.accent, width: 1.4),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.onAccent : c.muted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.accent : c.blush),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.accent : c.line),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.line,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.paper, fontSize: 14),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.paper,
      dialBackgroundColor: c.blush,
      hourMinuteColor: c.blush,
    ),
  );
}

final lightTheme = _build(SosColors.light, Brightness.light);
final darkTheme = _build(SosColors.dark, Brightness.dark);
