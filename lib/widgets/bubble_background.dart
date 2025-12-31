import 'package:flutter/material.dart';
import 'dart:math' as math;

class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double o1 = isDark ? 0.14 : 0.08;
    final double o2 = isDark ? 0.12 : 0.06;
    final double o3 = isDark ? 0.10 : 0.04;
    final Color bubble = scheme.primary.withValues(alpha: o1);
    final Color bubble2 = scheme.secondary.withValues(alpha: o2);
    final Color bubble3 = scheme.onSurface.withValues(alpha: o3);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BubblePainter(
              t: _controller.value,
              c1: bubble,
              c2: bubble2,
              c3: bubble3,
            ),
          );
        },
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double t;
  final Color c1;
  final Color c2;
  final Color c3;

  _BubblePainter({
    required this.t,
    required this.c1,
    required this.c2,
    required this.c3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p1 = Paint()..color = c1;
    final Paint p2 = Paint()..color = c2;
    final Paint p3 = Paint()..color = c3;

    final double w = size.width;
    final double h = size.height;
    const double twoPi = 6.283185307179586;

    final Offset o1 = Offset(
      w * (0.18 + 0.05 * (1 + math.sin(twoPi * (t + 0.10)))),
      h * (0.22 + 0.04 * (1 + math.cos(twoPi * (t + 0.20)))),
    );
    final Offset o2 = Offset(
      w * (0.78 + 0.05 * (1 + math.sin(twoPi * (t + 0.33)))),
      h * (0.28 + 0.05 * (1 + math.cos(twoPi * (t + 0.53)))),
    );
    final Offset o3 = Offset(
      w * (0.52 + 0.06 * (1 + math.sin(twoPi * (t + 0.68)))),
      h * (0.68 + 0.05 * (1 + math.cos(twoPi * (t + 0.82)))),
    );
    final Offset o4 = Offset(
      w * (0.32 + 0.04 * (1 + math.sin(twoPi * (t + 0.25)))),
      h * (0.78 + 0.04 * (1 + math.cos(twoPi * (t + 0.40)))),
    );
    final Offset o5 = Offset(
      w * (0.88 + 0.03 * (1 + math.sin(twoPi * (t + 0.58)))),
      h * (0.58 + 0.03 * (1 + math.cos(twoPi * (t + 0.72)))),
    );
    final Offset o6 = Offset(
      w * (0.08 + 0.03 * (1 + math.sin(twoPi * (t + 0.85)))),
      h * (0.48 + 0.03 * (1 + math.cos(twoPi * (t + 0.95)))),
    );

    canvas.drawCircle(o1, 82, p1);
    canvas.drawCircle(o2, 108, p2);
    canvas.drawCircle(o3, 74, p3);
    canvas.drawCircle(o4, 56, p2);
    canvas.drawCircle(o5, 48, p1);
    canvas.drawCircle(o6, 42, p3);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.c1 != c1 ||
      oldDelegate.c2 != c2 ||
      oldDelegate.c3 != c3;
}


