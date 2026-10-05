import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The same field-guide look as the website: warm paper, ink, one vermilion accent,
/// and the type colours carrying the rest.
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.paper2,
    required this.card,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.line,
    required this.line2,
    required this.accent,
  });

  final Color paper;
  final Color paper2;
  final Color card;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color line;
  final Color line2;
  final Color accent;

  static const light = Palette(
    paper: Color(0xFFF3EFE6),
    paper2: Color(0xFFEBE5D8),
    card: Color(0xFFFBF9F4),
    ink: Color(0xFF1C1A16),
    ink2: Color(0xFF474338),
    muted: Color(0xFF7A7466),
    line: Color(0xFFD9D1C0),
    line2: Color(0xFFC8BEA9),
    accent: Color(0xFFC9432C),
  );

  static const dark = Palette(
    paper: Color(0xFF13120F),
    paper2: Color(0xFF1B1A16),
    card: Color(0xFF1F1D19),
    ink: Color(0xFFEFE9DC),
    ink2: Color(0xFFC8C0AE),
    muted: Color(0xFF8F887A),
    line: Color(0xFF322F29),
    line2: Color(0xFF423E36),
    accent: Color(0xFFFF6B4F),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: l(paper, other.paper),
      paper2: l(paper2, other.paper2),
      card: l(card, other.card),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      accent: l(accent, other.accent),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}

const typeColors = <String, Color>{
  'normal': Color(0xFF9A9A88),
  'fire': Color(0xFFE2552E),
  'water': Color(0xFF3A7FE0),
  'electric': Color(0xFFE8B415),
  'grass': Color(0xFF4C9D3A),
  'ice': Color(0xFF45BFD8),
  'fighting': Color(0xFFD06A1C),
  'poison': Color(0xFF8F4CC4),
  'ground': Color(0xFFA4692F),
  'flying': Color(0xFF7FA8E0),
  'psychic': Color(0xFFE04F7C),
  'bug': Color(0xFF8A9A1F),
  'rock': Color(0xFFA89D6E),
  'ghost': Color(0xFF6B4A8A),
  'dragon': Color(0xFF5361D6),
  'dark': Color(0xFF5A4B4A),
  'steel': Color(0xFF5E9AB0),
  'fairy': Color(0xFFE07ED8),
};

Color typeColor(String type) => typeColors[type] ?? typeColors['normal']!;

/// A soft tint of [color] over the card colour, as on the website.
Color tint(BuildContext context, Color color, [double amount = 0.14]) =>
    Color.alphaBlend(color.withValues(alpha: amount), context.palette.card);

const statColors = [
  Color(0xFFD9534F),
  Color(0xFFE88A3C),
  Color(0xFFE3B93A),
  Color(0xFF8FBF3F),
  Color(0xFF3FAE7C),
  Color(0xFF2F8FBF),
];

Color statColor(int value) =>
    statColors[value >= 150
        ? 5
        : value >= 120
        ? 4
        : value >= 90
        ? 3
        : value >= 60
        ? 2
        : value >= 30
        ? 1
        : 0];

const radius = 14.0;

TextStyle display(double size, {FontWeight weight = FontWeight.w600, Color? color, FontStyle? style}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontStyle: style,
      letterSpacing: -size * 0.02,
      height: 1.05,
    );

TextStyle mono(double size, {FontWeight weight = FontWeight.w500, Color? color, double spacing = 0}) =>
    GoogleFonts.ibmPlexMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Small uppercase label, as used for section captions.
TextStyle label(BuildContext context) => mono(11, color: context.palette.muted, spacing: 0.8);

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final text = GoogleFonts.ibmPlexSansTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink);
  final scheme = ColorScheme.fromSeed(seedColor: p.accent, brightness: brightness).copyWith(
    surface: p.paper,
    surfaceContainerLowest: p.card,
    surfaceContainerLow: p.card,
    surfaceContainer: p.card,
    surfaceContainerHigh: p.paper2,
    surfaceContainerHighest: p.paper2,
    primary: p.ink,
    onPrimary: p.paper,
    secondary: p.accent,
    onSurface: p.ink,
    onSurfaceVariant: p.ink2,
    outline: p.line2,
    outlineVariant: p.line,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    textTheme: text,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: display(22, color: p.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.paper2,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall!.copyWith(
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? p.ink : p.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.ink : p.muted),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: p.line),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.card,
      selectedColor: p.ink,
      side: BorderSide(color: p.line2),
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge!.copyWith(color: p.ink),
      secondaryLabelStyle: text.labelLarge!.copyWith(color: p.paper),
      checkmarkColor: p.paper,
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      hintStyle: TextStyle(color: p.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: p.line2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: p.line2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: p.ink, width: 1.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.line2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: p.ink, foregroundColor: p.paper, shape: const StadiumBorder()),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line2),
        shape: const StadiumBorder(),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.ink,
        selectedForegroundColor: p.paper,
        side: BorderSide(color: p.line2),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
  );
}
