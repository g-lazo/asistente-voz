import 'package:material_ui/material_ui.dart';

/// Palette and shared decorations of the dark "Noche" look.
///
/// Nothing here blurs or uses shaders: the Android emulator renders in
/// software, so translucent means a colour with alpha and glows are radial
/// gradients and box shadows.
abstract final class Noche {
  static const Color background = Color(0xFF0E0F1C);
  static const Color backdrop = Color(0xFF07080F);
  static const Color text = Color(0xFFF2F3FB);
  static const Color violet = Color(0xFF6C4DFF);
  static const Color blue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color danger = Color(0xFFFF5A6E);

  /// Violet to blue, top-left to bottom-right.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, blue],
  );

  static Color get textMuted => text.withValues(alpha: 0.7);

  /// Translucent white fill with a hairline border, the stand-in for glass.
  static BoxDecoration panel({double radius = 16}) => BoxDecoration(
    color: const Color(0x14FFFFFF),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0x1AFFFFFF)),
  );
}

ThemeData nocheTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Noche.violet,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Noche.violet,
        onPrimary: Colors.white,
        secondary: Noche.blue,
        tertiary: Noche.cyan,
        error: Noche.danger,
        onError: Colors.white,
        surface: Noche.background,
        onSurface: Noche.text,
        onSurfaceVariant: Noche.textMuted,
      );
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Noche.background,
    canvasColor: Noche.background,
    textTheme: ThemeData(brightness: Brightness.dark).textTheme
        .apply(bodyColor: Noche.text, displayColor: Noche.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x14FFFFFF),
      labelStyle: TextStyle(color: Noche.textMuted),
      border: border(const Color(0x1AFFFFFF)),
      enabledBorder: border(const Color(0x1AFFFFFF)),
      focusedBorder: border(Noche.violet),
      errorBorder: border(Noche.danger),
      focusedErrorBorder: border(Noche.danger),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Noche.violet,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0x1FFFFFFF),
        disabledForegroundColor: Noche.textMuted,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFD6CCFF)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF23253B),
      contentTextStyle: const TextStyle(color: Noche.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1C30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Noche.violet,
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Noche.text,
      unselectedLabelColor: Noche.textMuted,
      indicator: BoxDecoration(
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

/// Page background: the base colour with a violet glow in the top-left
/// corner and a cyan one in the bottom-right, then [child] on top.
class NocheBackground extends StatelessWidget {
  const NocheBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Noche.background),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.1,
              colors: [
                Noche.violet.withValues(alpha: 0.55),
                Noche.violet.withValues(alpha: 0),
              ],
              stops: const [0, 0.6],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomRight,
              radius: 0.9,
              colors: [
                Noche.cyan.withValues(alpha: 0.35),
                Noche.cyan.withValues(alpha: 0),
              ],
              stops: const [0, 0.6],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
