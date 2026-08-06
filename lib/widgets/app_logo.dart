import 'package:flutter/material.dart';

/// The app's actual logo.
///
/// The app used to draw `Icons.insights_rounded` in the app bar, the About
/// screen and the splash — a generic Material icon that had nothing to do with
/// the FinBrief mark on the launcher and store listing. Everywhere the app
/// shows its own identity now uses the same artwork the icon is generated
/// from, so the brand is one thing rather than two.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 24, this.rounded = true});

  final double size;

  /// The source artwork already has rounded corners baked in, so at small
  /// sizes it reads better clipped a little tighter than the raw square.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/icon/icon.png',
      width: size,
      height: size,
      // Crisp at every size; the source is 1254px square.
      filterQuality: FilterQuality.medium,
    );

    if (!rounded) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: image,
    );
  }
}
