import 'package:flutter/material.dart';

import '../../theme.dart';
import '../strings.dart';
import '../theme/app_spacing.dart';

class ProfileEmptyUsage extends StatelessWidget {
  const ProfileEmptyUsage({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.s40),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomPaint(
            size: Size(
              AppSpace.profileEmptyIllustrationSize,
              AppSpace.profileEmptyIllustrationSize,
            ),
            painter: _EmptyUsagePainter(),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            AppStrings.profileNoUsage,
            style: AppTheme.body(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _EmptyUsagePainter extends CustomPainter {
  const _EmptyUsagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkMuted
      ..strokeWidth = AppSpace.hairline
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final baseline = size.height * .78;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), paint);
    final line = Path()
      ..moveTo(size.width * .1, baseline * .84)
      ..lineTo(size.width * .36, baseline * .61)
      ..lineTo(size.width * .57, baseline * .7)
      ..lineTo(size.width * .88, baseline * .24);
    canvas.drawPath(line, paint);
  }

  @override
  bool shouldRepaint(covariant _EmptyUsagePainter oldDelegate) => false;
}
