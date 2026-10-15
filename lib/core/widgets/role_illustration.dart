import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Vector interpretation of the reference's scissors/comb and customer motifs.
class RoleIllustration extends StatelessWidget {
  const RoleIllustration({super.key, required this.vendor});
  final bool vendor;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(72, 72), painter: _RolePainter(vendor));
}

class _RolePainter extends CustomPainter {
  _RolePainter(this.vendor);
  final bool vendor;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 72, size.height / 72);
    final line = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Palette.lavender;
    if (vendor) {
      canvas.save();
      canvas.translate(46, 25);
      canvas.rotate(.7);
      final comb = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -24, 18, 45),
        const Radius.circular(3),
      );
      canvas.drawRRect(comb, fill);
      canvas.drawRRect(comb, line);
      for (var y = -18.0; y < 18; y += 5) {
        canvas.drawLine(Offset(-8, y), Offset(3, y), line);
      }
      canvas.restore();
      canvas.drawPath(
        Path()
          ..moveTo(25, 46)
          ..lineTo(12, 8)
          ..quadraticBezierTo(27, 16, 38, 40)
          ..lineTo(49, 51),
        line,
      );
      canvas.drawPath(
        Path()
          ..moveTo(23, 53)
          ..lineTo(57, 17)
          ..quadraticBezierTo(59, 32, 37, 49),
        line,
      );
      canvas.drawOval(const Rect.fromLTWH(13, 46, 17, 18), fill);
      canvas.drawOval(const Rect.fromLTWH(13, 46, 17, 18), line);
      canvas.drawOval(const Rect.fromLTWH(42, 49, 17, 18), fill);
      canvas.drawOval(const Rect.fromLTWH(42, 49, 17, 18), line);
      canvas.drawCircle(const Offset(34, 39), 2, line);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(17, 62)
          ..quadraticBezierTo(17, 48, 27, 46)
          ..lineTo(31, 41)
          ..lineTo(42, 41)
          ..lineTo(46, 46)
          ..quadraticBezierTo(57, 48, 57, 62)
          ..close(),
        fill,
      );
      canvas.drawPath(
        Path()
          ..moveTo(17, 62)
          ..quadraticBezierTo(17, 48, 27, 46)
          ..lineTo(31, 41)
          ..lineTo(42, 41)
          ..lineTo(46, 46)
          ..quadraticBezierTo(57, 48, 57, 62)
          ..close(),
        line,
      );
      canvas.drawPath(
        Path()
          ..moveTo(25, 21)
          ..quadraticBezierTo(23, 6, 39, 7)
          ..quadraticBezierTo(54, 6, 50, 26)
          ..lineTo(46, 37)
          ..quadraticBezierTo(36, 49, 27, 35)
          ..close(),
        line,
      );
      canvas.drawPath(
        Path()
          ..moveTo(25, 22)
          ..lineTo(29, 15)
          ..quadraticBezierTo(35, 23, 48, 21)
          ..moveTo(26, 47)
          ..lineTo(36, 57)
          ..lineTo(47, 47),
        line,
      );
      canvas.drawCircle(const Offset(57, 36), 4, line);
      canvas.drawCircle(const Offset(64, 43), 4, line);
      canvas.drawLine(const Offset(59, 38), const Offset(68, 25), line);
      canvas.drawLine(const Offset(62, 40), const Offset(54, 24), line);
    }
  }

  @override
  bool shouldRepaint(_RolePainter oldDelegate) => oldDelegate.vendor != vendor;
}
