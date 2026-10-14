import 'package:material_ui/material_ui.dart';

/// The MFB Services Inc. logo lockup on its own (dark background only).
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.width = 220, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/mfb_logo_dark.png',
      width: width,
      semanticLabel: 'MFB Services Intelligence',
    );
  }
}
