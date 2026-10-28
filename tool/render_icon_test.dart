// Draws the app icon from the welcome-screen emblem.
//
//   flutter test tool/render_icon_test.dart
//   dart run flutter_launcher_icons
//
// Writes assets/icon/icon.png (full icon) and assets/icon/foreground.png
// (emblem only, sized for Android's adaptive-icon safe zone).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:divine_quotes/theme.dart';
import 'package:divine_quotes/widgets/illustrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;

Future<void> _render(String path, {required bool background, required double scale}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const c = SosColors.light;
  if (background) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, _size, _size), Paint()..color = c.paper);
  }
  final width = _size * scale;
  final height = width * 0.8;
  canvas.translate((_size - width) / 2, (_size - height) / 2 + _size * 0.02);
  EmblemPainter(ink: c.ink, accent: c.accent, sun: c.sand.withValues(alpha: 0.45), strokeScale: 2.6)
      .paint(canvas, Size(width, height));
  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('render app icon', () async {
    await _render('assets/icon/icon.png', background: true, scale: 0.78);
    await _render('assets/icon/foreground.png', background: false, scale: 0.56);
  });
}
