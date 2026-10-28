import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';

/// Shown the first time the app opens.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final hills = (box.maxHeight * 0.30).clamp(160.0, 320.0);
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: hills,
                child: CustomPaint(
                  painter: HillsPainter(
                    colors: [
                      c.blush,
                      c.sand,
                      Color.lerp(c.accent, c.sand, 0.25)!,
                    ],
                    line: c.card.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: hills * 0.12,
                child: const LeafSprig(width: 90, height: 140, paleTip: false, flip: true),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: hills * 0.75),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Emblem(size: (box.maxWidth * 0.6).clamp(180.0, 260.0)),
                          const SizedBox(height: 34),
                          Text('Spiritual SOS',
                              textAlign: TextAlign.center,
                              style: serif(fontSize: 46, color: c.ink, height: 1.05)),
                          const SizedBox(height: 18),
                          const AccentRule(width: 36),
                          const SizedBox(height: 18),
                          Text('Small words. A little more light.',
                              textAlign: TextAlign.center,
                              style: serif(fontSize: 19, color: c.muted)),
                          const SizedBox(height: 34),
                          FilledButton(
                            onPressed: onBegin,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(200, 54),
                            ),
                            child: const Text('Begin'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
