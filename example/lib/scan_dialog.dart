import 'package:flutter/material.dart';

class ScanImageView extends StatefulWidget {
  const ScanImageView({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  _ScanImageViewState createState() => _ScanImageViewState();
}

class _ScanImageViewState extends State<ScanImageView>
    with TickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        foregroundPainter: _ScanPainter(
          controller.value,
          Colors.white,
          Colors.green,
        ),
        child: widget.child,
        willChange: true,
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(
    this.value,
    this.borderColor,
    this.scanColor,
  );

  final double value;
  final Color borderColor;
  final Color scanColor;

  late final Paint _paint = initPaint();

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final double boxWidth = size.width * 2 / 3;
    final double boxHeight = height / 4;

    final double left = (width - boxWidth) / 2;
    final double top = boxHeight;
    final double bottom = boxHeight * 2;
    final double right = left + boxWidth;
    _paint.color = borderColor;
    final Rect rect = Rect.fromLTWH(left, top, boxWidth, boxHeight);
    canvas.drawRect(rect, _paint);

    _paint.strokeWidth = 3;

    final Path path1 = Path()
      ..moveTo(left, top + 10)
      ..lineTo(left, top)
      ..lineTo(left + 10, top);
    canvas.drawPath(path1, _paint);
    final Path path2 = Path()
      ..moveTo(left, bottom - 10)
      ..lineTo(left, bottom)
      ..lineTo(left + 10, bottom);
    canvas.drawPath(path2, _paint);
    final Path path3 = Path()
      ..moveTo(right, bottom - 10)
      ..lineTo(right, bottom)
      ..lineTo(right - 10, bottom);
    canvas.drawPath(path3, _paint);
    final Path path4 = Path()
      ..moveTo(right, top + 10)
      ..lineTo(right, top)
      ..lineTo(right - 10, top);
    canvas.drawPath(path4, _paint);

    _paint.color = scanColor;

    final Rect scanRect = Rect.fromLTWH(
      left + 10,
      top + 10 + (value * (boxHeight - 20)),
      boxWidth - 20,
      3,
    );

    _paint.shader = const LinearGradient(
      colors: <Color>[
        Colors.white54,
        Colors.white,
        Colors.white54,
      ],
      stops: <double>[0.0, 0.5, 1],
    ).createShader(scanRect);
    canvas.drawRect(scanRect, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  Paint initPaint() {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }
}
