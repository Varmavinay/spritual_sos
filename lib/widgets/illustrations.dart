import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A sprig of leaves, drawn in code so it is crisp at any size and follows
/// the light/dark palette.
class LeafSprig extends StatelessWidget {
  const LeafSprig({
    super.key,
    this.width = 120,
    this.height = 170,
    this.leaves = 7,
    this.paleTip = true,
    this.flip = false,
  });

  final double width;
  final double height;
  final int leaves;

  /// Adds the large pale leaf at the top, as on the home card.
  final bool paleTip;

  /// Mirrors the sprig so it leans the other way.
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return ExcludeSemantics(
      child: Transform.flip(
        flipX: flip,
        child: CustomPaint(
          size: Size(width, height),
          painter: _SprigPainter(
            accent: c.accent,
            sand: c.sand,
            pale: c.blush,
            leaves: leaves,
            paleTip: paleTip,
          ),
        ),
      ),
    );
  }
}

class _SprigPainter extends CustomPainter {
  _SprigPainter({
    required this.accent,
    required this.sand,
    required this.pale,
    required this.leaves,
    required this.paleTip,
  });

  final Color accent;
  final Color sand;
  final Color pale;
  final int leaves;
  final bool paleTip;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // The stem: from the bottom right, arching up to the top left.
    final p0 = Offset(w * 0.92, h);
    final p1 = Offset(w * 0.62, h * 0.72);
    final p2 = Offset(w * 0.30, h * 0.45);
    final p3 = Offset(w * 0.34, h * 0.10);

    Offset point(double t) {
      final u = 1 - t;
      return p0 * (u * u * u) +
          p1 * (3 * u * u * t) +
          p2 * (3 * u * t * t) +
          p3 * (t * t * t);
    }

    Offset tangent(double t) {
      final u = 1 - t;
      return (p1 - p0) * (3 * u * u) +
          (p2 - p1) * (6 * u * t) +
          (p3 - p2) * (3 * t * t);
    }

    if (paleTip) {
      _leaf(canvas, Offset(w * 0.40, h * 0.30), -math.pi / 2 + 0.25,
          h * 0.30, h * 0.11, pale, pale);
    }

    final stem = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    canvas.drawPath(
      stem,
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * 0.012)
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < leaves; i++) {
      final t = 0.16 + i * (0.80 / leaves);
      final base = point(t);
      final dir = tangent(t);
      final heading = math.atan2(dir.dy, dir.dx);
      final side = i.isEven ? 1 : -1;
      final length = h * (0.25 - 0.11 * t);
      final light = i % 3 == 1;
      _leaf(canvas, base, heading + side * 0.85, length, length * 0.36,
          light ? sand : accent, light ? pale : sand);
    }
    // Leaf at the very tip.
    final tip = point(1);
    final dir = tangent(1);
    _leaf(canvas, tip, math.atan2(dir.dy, dir.dx), h * 0.12, h * 0.045,
        accent, sand);
  }

  static void _leaf(Canvas canvas, Offset base, double angle, double length,
      double width, Color color, Color highlight) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final shape = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.42, -width, length, 0)
      ..quadraticBezierTo(length * 0.42, width, 0, 0)
      ..close();
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(colors: [color, Color.lerp(color, highlight, 0.55)!])
            .createShader(Rect.fromLTWH(0, -width, length, width * 2)),
    );
    canvas.drawLine(
      Offset(length * 0.08, 0),
      Offset(length * 0.82, 0),
      Paint()
        ..color = highlight.withValues(alpha: 0.6)
        ..strokeWidth = math.max(0.6, width * 0.07),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SprigPainter old) =>
      old.accent != accent || old.sand != sand || old.pale != pale;
}

/// Line drawing of an open book, from the welcome screen.
class OpenBookPainter extends CustomPainter {
  OpenBookPainter({required this.ink, required this.accent, this.stroke = 1.6});

  final Color ink;
  final Color accent;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final spine = Offset(cx, h * 0.96);
    Paint pen(Color color, [double scale = 1]) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Pages fanning out from the spine, innermost first.
    for (var side in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final outer = Offset(cx + side * w * (0.40 + i * 0.03), h * (0.18 + i * 0.07));
        final page = Path()
          ..moveTo(spine.dx, spine.dy)
          ..quadraticBezierTo(cx + side * w * 0.16, h * (0.32 + i * 0.05),
              outer.dx, outer.dy);
        canvas.drawPath(page, pen(i == 0 ? ink : accent, i == 0 ? 1 : 0.8));
        // Outer edge of each page, dropping to the cover.
        canvas.drawLine(outer, Offset(outer.dx, h * (0.62 + i * 0.03)),
            pen(i == 0 ? ink : accent, 0.8));
      }
      // The cover.
      final cover = Path()
        ..moveTo(cx + side * w * 0.5, h * 0.70)
        ..quadraticBezierTo(cx + side * w * 0.2, h * 0.70, spine.dx, spine.dy);
      canvas.drawPath(cover, pen(ink, 1.15));
    }
  }

  @override
  bool shouldRepaint(OpenBookPainter old) =>
      old.ink != ink || old.accent != accent || old.stroke != stroke;
}

/// Rolling hills along the bottom of the welcome screen.
class HillsPainter extends CustomPainter {
  HillsPainter({required this.colors, required this.line});

  /// Back to front.
  final List<Color> colors;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Path hill(double startY, double c1y, double c2y, double endY) => Path()
      ..moveTo(0, h * startY)
      ..cubicTo(w * 0.35, h * c1y, w * 0.6, h * c2y, w, h * endY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final shapes = [
      hill(0.10, -0.05, 0.45, 0.20),
      hill(0.42, 0.22, 0.62, 0.40),
      hill(0.60, 0.48, 0.78, 0.66),
    ];
    for (var i = 0; i < shapes.length && i < colors.length; i++) {
      final color = colors[i];
      canvas.drawPath(
        shapes[i],
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, Color.lerp(color, Colors.black, 0.08)!],
          ).createShader(Offset.zero & size),
      );
    }
    final ridge = Path()
      ..moveTo(0, h * 0.84)
      ..cubicTo(w * 0.25, h * 0.58, w * 0.55, h * 0.62, w * 0.9, h * 0.92);
    canvas.drawPath(
      ridge,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(HillsPainter old) =>
      old.line != line || !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Two bold closing quotation marks ("99"), drawn as shapes so they look the
/// same everywhere, including the generated app icon.
class QuoteMarksPainter extends CustomPainter {
  QuoteMarksPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.height * 0.30;
    for (final x in [size.width * 0.25, size.width * 0.75]) {
      final center = Offset(x, r);
      canvas.drawCircle(center, r, paint);
      final tail = Path()
        ..moveTo(center.dx + r, center.dy)
        ..quadraticBezierTo(center.dx + r * 1.05, size.height * 0.80,
            center.dx - r * 0.85, size.height)
        ..quadraticBezierTo(center.dx + r * 0.25, size.height * 0.62,
            center.dx - r * 0.1, center.dy + r * 0.95)
        ..close();
      canvas.drawPath(tail, paint);
    }
  }

  @override
  bool shouldRepaint(QuoteMarksPainter old) => old.color != color;
}

/// The emblem from the welcome screen: a sun, quotation marks and an open
/// book. Also used to draw the app icon (tool/render_icon_test.dart).
class Emblem extends StatelessWidget {
  const Emblem({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size * 0.8),
        painter: EmblemPainter(
          ink: c.ink,
          accent: c.accent,
          sun: c.blush,
        ),
      ),
    );
  }
}

class EmblemPainter extends CustomPainter {
  EmblemPainter({
    required this.ink,
    required this.accent,
    required this.sun,
    this.strokeScale = 1,
  });

  final Color ink;
  final Color accent;
  final Color sun;
  final double strokeScale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.72, h * 0.22), w * 0.20, Paint()..color = sun);

    canvas.save();
    canvas.translate(w * 0.37, h * 0.17);
    QuoteMarksPainter(accent).paint(canvas, Size(w * 0.27, h * 0.25));
    canvas.restore();

    canvas.save();
    canvas.translate(0, h * 0.42);
    OpenBookPainter(ink: ink, accent: accent, stroke: w * 0.0075 * strokeScale)
        .paint(canvas, Size(w, h * 0.55));
    canvas.restore();
  }

  @override
  bool shouldRepaint(EmblemPainter old) =>
      old.ink != ink || old.accent != accent || old.sun != sun;
}
