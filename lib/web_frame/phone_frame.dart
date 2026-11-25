import 'package:material_ui/material_ui.dart';

import '../theme/noche.dart';

/// Draws [child] inside a phone when [enabled] and the window is at least
/// [minWindowWidth] wide; otherwise returns [child] untouched.
///
/// The phone is shrunk with a [FittedBox] when the window is short, never
/// enlarged. [FittedBox] scales through a transform that takes part in hit
/// testing, so taps and drags land on the right widget. The microphone
/// measures its slide-to-cancel distance with `PointerEvent.position`, which
/// is in window pixels, so its 80-pixel threshold is 80 window pixels at any
/// scale.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.enabled, required this.child});

  static const Size screenSize = Size(390, 844);
  static const double minWindowWidth = 600;

  /// Top padding the child sees, so its content clears the island.
  static const double islandInset = 44;

  static const double _bezel = 12;
  static const double _outerRadius = 48;
  static const double _margin = 24;

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!enabled || media.size.width < minWindowWidth) return child;

    const innerRadius = _outerRadius - _bezel;
    final screenMedia = media.copyWith(
      size: screenSize,
      padding: const EdgeInsets.only(top: islandInset),
      viewPadding: const EdgeInsets.only(top: islandInset),
      viewInsets: EdgeInsets.zero,
    );

    return ColoredBox(
      color: Noche.backdrop,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(_margin),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DecoratedBox(
              key: const Key('phoneBezel'),
              decoration: BoxDecoration(
                color: const Color(0xFF15161F),
                borderRadius: BorderRadius.circular(_outerRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 40,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(_bezel),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: SizedBox.fromSize(
                    size: screenSize,
                    child: Stack(
                      children: [
                        MediaQuery(data: screenMedia, child: child),
                        const Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: 110,
                              height: 28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF000000),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
