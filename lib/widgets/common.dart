import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Rounded card used throughout the app.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    this.radius = 24,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: shadow
            ? const <BoxShadow>[
                BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6)),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Arabic Quran text in the KFGQPC Uthmanic font: RTL, centred, generous line
/// height so that stacked marks (harakat, waqf signs) are never clipped.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    required this.fontSize,
    this.color,
    this.height = 2.0,
    this.align = TextAlign.center,
  });

  final String text;
  final double fontSize;
  final Color? color;
  final double height;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: align,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: kQuranFont,
          fontSize: fontSize,
          height: height,
          color: color ?? c.text,
        ),
      ),
    );
  }
}

/// Ayah number in Arabic-Indic digits, drawn by the KFGQPC font as its
/// ornamental ayah-end marker.
class AyahBadge extends StatelessWidget {
  const AyahBadge({super.key, required this.number, this.size = 44});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    // The KFGQPC font draws digits inside its own ornamental ayah-end marker,
    // so no extra ring is drawn here.
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          toArabicIndic(number),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: kQuranFont,
            fontSize: size,
            height: 1.0,
            color: c.gold,
          ),
        ),
      ),
    );
  }
}

/// Thin gold divider with a small diamond in the middle.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Container(height: 1, color: c.gold.withAlpha(0x66))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 7, height: 7, color: c.gold),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.gold.withAlpha(0x66))),
      ],
    );
  }
}

/// Number with a caption, used for statistics.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color ?? c.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: c.textMuted),
        ),
      ],
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
