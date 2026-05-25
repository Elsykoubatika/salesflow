import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Identité visuelle DealFlow Pro.
/// Palette, marque (symbole infini) et motif réseau réutilisables.
class DealFlowBrand {
  // Palette émeraude + métal
  static const Color green950 = Color(0xFF04130D);
  static const Color green900 = Color(0xFF0A2C1F);
  static const Color green800 = Color(0xFF0D4530);
  static const Color green700 = Color(0xFF0F5C40);
  static const Color green600 = Color(0xFF157A54);
  static const Color green500 = Color(0xFF1F9D6B);
  static const Color mint = Color(0xFF7FD1AA);
  static const Color silver = Color(0xFFCDD6D2);
  static const Color cream = Color(0xFFF3F1EA);
  static const Color ink = Color(0xFF0C1A14);

  static const String slogan = 'Le flux continu de vos affaires';
}

/// Le symbole « infini » métallique de DealFlow — deux boucles entrelacées.
/// Peint sans image : dégradés vert→argent pour un rendu métal.
class InfinityMark extends StatelessWidget {
  final double size;
  const InfinityMark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _InfinityPainter()),
    );
  }
}

class _InfinityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.23; // rayon des boucles
    final stroke = w * 0.13;

    // Ombre portée
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.save();
    canvas.translate(0, h * 0.035);
    _drawLoops(canvas, cx, cy, r, shadow, shadow);
    canvas.restore();

    // Boucle gauche — dégradé métal vert→argent
    final leftRect = Rect.fromCircle(center: Offset(cx - r, cy), radius: r * 2);
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF4F6F5),
          Color(0xFF9AA8A2),
          DealFlowBrand.green500,
          DealFlowBrand.green800,
        ],
        stops: [0.0, 0.28, 0.6, 1.0],
      ).createShader(leftRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Boucle droite — dégradé inverse
    final rightRect = Rect.fromCircle(center: Offset(cx + r, cy), radius: r * 2);
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Color(0xFFF4F6F5),
          Color(0xFFCDD6D2),
          DealFlowBrand.green500,
          DealFlowBrand.green900,
        ],
        stops: [0.0, 0.3, 0.62, 1.0],
      ).createShader(rightRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    _drawLoops(canvas, cx, cy, r, leftPaint, rightPaint);

    // Reflet brillant interne
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.16
      ..strokeCap = StrokeCap.round;
    final hl = Path();
    hl.addArc(
      Rect.fromCircle(center: Offset(cx - r, cy), radius: r * 0.62),
      math.pi * 1.15,
      math.pi * 0.9,
    );
    hl.addArc(
      Rect.fromCircle(center: Offset(cx + r, cy), radius: r * 0.62),
      math.pi * 0.15,
      math.pi * 0.9,
    );
    canvas.drawPath(hl, glow);
  }

  void _drawLoops(
      Canvas canvas, double cx, double cy, double r, Paint left, Paint right) {
    // Boucle gauche
    final lPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx - r, cy), radius: r));
    // Boucle droite
    final rPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx + r, cy), radius: r));
    canvas.drawPath(lPath, left);
    canvas.drawPath(rPath, right);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Motif « réseau » — points reliés par des lignes fines.
/// Évoque le flux et le réseau d'agents. Rendu discret en arrière-plan.
class NetworkPattern extends StatelessWidget {
  final Color lineColor;
  final Color dotColor;
  final double opacity;

  const NetworkPattern({
    super.key,
    this.lineColor = const Color(0xFF2F8F68),
    this.dotColor = const Color(0xFF5FC596),
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size.infinite,
        painter: _NetworkPainter(lineColor: lineColor, dotColor: dotColor),
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final Color lineColor;
  final Color dotColor;
  _NetworkPainter({required this.lineColor, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nœuds en coordonnées relatives (0..1)
    final nodes = <Offset>[
      Offset(0.10, 0.12), Offset(0.38, 0.22), Offset(0.20, 0.42),
      Offset(0.62, 0.30), Offset(0.82, 0.16), Offset(0.95, 0.40),
      Offset(0.15, 0.66), Offset(0.50, 0.60), Offset(0.78, 0.72),
      Offset(0.35, 0.86), Offset(0.92, 0.90), Offset(0.60, 0.95),
    ];
    final pts = nodes.map((n) => Offset(n.dx * w, n.dy * h)).toList();

    // Liens entre nœuds (indices)
    const links = [
      [0, 1], [1, 2], [1, 3], [3, 4], [3, 5], [2, 6], [3, 7],
      [6, 7], [7, 8], [5, 8], [6, 9], [8, 10], [9, 11], [7, 11], [4, 5],
    ];

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final l in links) {
      canvas.drawLine(pts[l[0]], pts[l[1]], linePaint);
    }

    final dotPaint = Paint()..color = dotColor;
    for (var i = 0; i < pts.length; i++) {
      final radius = (i % 3 == 0) ? 4.5 : 3.0;
      canvas.drawCircle(pts[i], radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Le mot-symbole « DEALFLOW / PRO ».
class DealFlowWordmark extends StatelessWidget {
  final double size;
  final bool light;
  const DealFlowWordmark({super.key, this.size = 30, this.light = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DEALFLOW',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: size * 0.04,
            height: 1,
            color: light ? Colors.white : DealFlowBrand.green800,
          ),
        ),
        SizedBox(height: size * 0.16),
        Text(
          'PRO',
          style: TextStyle(
            fontSize: size * 0.40,
            fontWeight: FontWeight.w700,
            letterSpacing: size * 0.30,
            height: 1,
            color: DealFlowBrand.green500,
          ),
        ),
      ],
    );
  }
}
