import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/watermark_bloc.dart';
import 'floating_watermark_painter.dart';

class SecurityOverlayView extends StatelessWidget {
  const SecurityOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatermarkBloc, WatermarkState>(
      builder: (context, state) {
        if (state is WatermarkLoaded) {
          return IgnorePointer(child: WatermarkMovingLayer(text: state.text));
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class WatermarkMovingLayer extends StatefulWidget {
  final String text;
  const WatermarkMovingLayer({super.key, required this.text});

  @override
  State<WatermarkMovingLayer> createState() => _WatermarkMovingLayerState();
}

class _WatermarkMovingLayerState extends State<WatermarkMovingLayer>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _random = Random();

  double _posX = 0.5;
  double _posY = 0.5;
  double _angle = 0.0;
  double _speed = 0.00004;

  @override
  void initState() {
    super.initState();
    _posX = _random.nextDouble();
    _posY = _random.nextDouble();
    _angle = _random.nextDouble() * 2 * pi;

    _ticker = createTicker((elapsed) {
      setState(() {
        _angle += (_random.nextDouble() - 0.5) * 0.002;

        _posX += cos(_angle) * _speed;
        _posY += sin(_angle) * _speed;

        bool hitLeft = _posX <= 0.0;
        bool hitRight = _posX >= 1.0;
        bool hitTop = _posY <= 0.0;
        bool hitBottom = _posY >= 1.0;

        if (hitLeft || hitRight || hitTop || hitBottom) {
          _posX = _posX.clamp(0.0, 1.0);
          _posY = _posY.clamp(0.0, 1.0);
          _angle = _getNewRandomAngle(hitLeft, hitRight, hitTop, hitBottom);

          _speed = 0.00003 + (_random.nextDouble() * 0.00002);
        }
      });
    });

    _ticker.start();
  }

  double _getNewRandomAngle(bool left, bool right, bool top, bool bottom) {
    const double margin = 0.15;
    if (left && top) {
      return _random.nextDouble() * ((pi / 2) - 2 * margin) + margin;
    }
    if (right && top) {
      return _random.nextDouble() * ((pi / 2) - 2 * margin) + (pi / 2) + margin;
    }
    if (left && bottom) {
      return _random.nextDouble() * ((pi / 2) - 2 * margin) +
          (3 * pi / 2) +
          margin;
    }
    if (right && bottom) {
      return _random.nextDouble() * ((pi / 2) - 2 * margin) + pi + margin;
    }
    if (left) {
      return (_random.nextDouble() * (pi - 2 * margin)) - (pi / 2) + margin;
    }
    if (right) {
      return (_random.nextDouble() * (pi - 2 * margin)) + (pi / 2) + margin;
    }
    if (top) {
      return (_random.nextDouble() * (pi - 2 * margin)) + margin;
    }
    if (bottom) {
      return (_random.nextDouble() * (pi - 2 * margin)) + pi + margin;
    }
    return _random.nextDouble() * 2 * pi;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: FloatingWatermarkPainter(
            text: widget.text,
            progressX: _posX,
            progressY: _posY,
          ),
        );
      },
    );
  }
}
