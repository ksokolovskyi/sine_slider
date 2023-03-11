// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tactile_feedback/tactile_feedback.dart';

class SineSlider extends StatefulWidget {
  final double value;

  final ValueChanged<double> onChanged;

  final ValueChanged<double>? onChangeStart;

  final ValueChanged<double>? onChangeEnd;

  const SineSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  State<SineSlider> createState() => _SineSliderState();
}

class _SineSliderState extends State<SineSlider> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _SineSlider(
        value: widget.value,
        vsync: this,
        onChanged: widget.onChanged,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
      ),
    );
  }
}

class _SineSlider extends LeafRenderObjectWidget {
  final double value;

  final TickerProvider vsync;

  final ValueChanged<double> onChanged;

  final ValueChanged<double>? onChangeStart;

  final ValueChanged<double>? onChangeEnd;

  const _SineSlider({
    super.key,
    required this.value,
    required this.vsync,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSineSlider(
      value: value,
      vsync: vsync,
      gestureSettings: MediaQuery.of(context).gestureSettings,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSineSlider renderObject,
  ) {
    renderObject
      ..value = value
      ..vsync = vsync
      ..gestureSettings = MediaQuery.of(context).gestureSettings
      ..onChanged = onChanged
      ..onChangeStart = onChangeStart
      ..onChangeEnd = onChangeEnd;
  }
}

class _RenderSineSlider extends RenderBox implements MouseTrackerAnnotation {
  _RenderSineSlider({
    required double value,
    required TickerProvider vsync,
    required DeviceGestureSettings gestureSettings,
    required ValueChanged<double> onChanged,
    required ValueChanged<double>? onChangeStart,
    required ValueChanged<double>? onChangeEnd,
  })  : assert(value >= 0.0 && value <= 1.0),
        _value = value,
        _vsync = vsync,
        _onChanged = onChanged,
        _onChangeStart = onChangeStart,
        _onChangeEnd = onChangeEnd {
    final team = GestureArenaTeam();

    _drag = HorizontalDragGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _endInteraction
      ..gestureSettings = gestureSettings;

    _tap = TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..gestureSettings = gestureSettings;

    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 100),
    );

    _valueAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _focusController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 150),
    );

    _focusAnimation = CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    );
  }

  static const double _maxAmplitude = 15.0;

  static const double _minTrackWidth = 144.0;
  static const double _trackHeight = 15.0;
  static const double _trackMargin = 15.0;

  static const double _minThumbWidth = 15.0;
  static const double _maxThumbWidth = 30.0;
  static const double _thumbWidthRange = _maxThumbWidth - _minThumbWidth;
  static const double _maxThumbWidthExtension = 2.5;
  static const double _maxFocusedThumbWidth =
      _maxThumbWidth + _maxThumbWidthExtension;

  static const double _minThumbHeight = 50.0;
  static const double _maxThumbHeight = 70.0;
  static const double _thumbHeightRange = _maxThumbHeight - _minThumbHeight;
  static const double _maxThumbHeightExtension = 5.0;
  static const double _maxFocusedThumbHeight =
      _maxThumbHeight + _maxThumbHeightExtension;

  static const _intrinsicWidth = _minTrackWidth + _maxFocusedThumbWidth / 2;
  static const _intrinsicHeight = _maxFocusedThumbHeight;

  static const _basicCursor = SystemMouseCursors.basic;
  static const _grabCursor = SystemMouseCursors.grab;
  static const _grabbingCursor = SystemMouseCursors.grabbing;

  late final AnimationController _focusController;
  late final Animation<double> _focusAnimation;
  double get _focusValue => _focusAnimation.value;

  late final AnimationController _controller;
  late final Animation<double> _valueAnimation;
  final Tween<double> _valueTween = Tween<double>();
  double get _animatedValue => _valueTween.evaluate(_valueAnimation);

  late final HorizontalDragGestureRecognizer _drag;
  late final TapGestureRecognizer _tap;

  bool _active = false;
  double _currentDragValue = 0.0;
  MouseCursor _cursor = _basicCursor;

  int _lastWaveHalf = -1;
  int _lastImpactedWaveHalf = -1;

  @override
  MouseCursor get cursor => _cursor;

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue >= 0.0 && newValue <= 1.0);

    if (newValue == _value) {
      return;
    }

    _value = newValue;

    markNeedsPaint();
  }

  DeviceGestureSettings? get gestureSettings => _drag.gestureSettings;
  set gestureSettings(DeviceGestureSettings? gestureSettings) {
    _drag.gestureSettings = gestureSettings;
    _tap.gestureSettings = gestureSettings;
  }

  ValueChanged<double> _onChanged;
  set onChanged(ValueChanged<double> onChanged) {
    if (_onChanged == onChanged) {
      return;
    }

    _onChanged = onChanged;
  }

  ValueChanged<double>? _onChangeStart;
  set onChangeStart(ValueChanged<double>? onChangeStart) {
    if (onChangeStart == _onChangeStart) {
      return;
    }

    _onChangeStart = onChangeStart;
  }

  ValueChanged<double>? _onChangeEnd;
  set onChangeEnd(ValueChanged<double>? onChangeEnd) {
    if (onChangeEnd == _onChangeEnd) {
      return;
    }

    _onChangeEnd = onChangeEnd;
  }

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    if (value == _vsync) {
      return;
    }

    _vsync = value;

    _controller.resync(_vsync);
    _focusController.resync(_vsync);
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => null;

  @override
  bool get validForMouseTracker => true;

  void _animateValue() => _onChanged(_animatedValue);
  void _animateFocus() => markNeedsPaint();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _valueAnimation.addListener(_animateValue);
    _focusAnimation.addListener(_animateFocus);
  }

  @override
  void detach() {
    _controller.stop();
    _valueAnimation.removeListener(_animateValue);

    _focusController.stop();
    _focusAnimation.removeListener(_animateFocus);

    super.detach();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusController.dispose();

    super.dispose();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _intrinsicWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _intrinsicWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight;

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : _intrinsicWidth,
      _intrinsicHeight,
    );
  }

  Rect _getTrackRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
  }) {
    const padding = _maxFocusedThumbWidth / 2;
    const height = _trackHeight;

    final left = offset.dx + padding;
    final top = offset.dy + (parentBox.size.height - height) / 2;
    final right = left + parentBox.size.width - padding * 2;
    final bottom = top + height;

    return Rect.fromLTRB(
      math.min(left, right),
      top,
      math.max(left, right),
      bottom,
    );
  }

  double _getWaveLength(double width) {
    final n = width / 40;
    return width / _floorToHalf(n);
  }

  double _floorToHalf(double n) {
    final r = n.floor();

    if (n - r < 0.5) {
      return math.max(r - 0.5, 1.5);
    }

    return math.max(r + 0.5, 1.5);
  }

  double _f({
    required double a,
    required double l,
    required double x,
  }) {
    const doublePi = math.pi * 2;
    return a * math.sin((doublePi * x) / l);
  }

  void _performImpact(double x) {
    final l = _getWaveLength(size.width);
    final y = _f(a: 1, l: l, x: x);
    final n = (x / (l / 2)).ceil();

    if (_lastImpactedWaveHalf != n && (y >= 0.95 && y <= 1.0)) {
      TactileFeedback.impact();

      _lastWaveHalf = n;
      _lastImpactedWaveHalf = n;
    } else if (_lastWaveHalf != n) {
      _lastWaveHalf = n;
      _lastImpactedWaveHalf = -1;
    }
  }

  void _paintTrack(
    PaintingContext context,
    Rect rect,
  ) {
    final offset = Offset(rect.left, rect.center.dy);

    final w = rect.width;
    final thumbCenter = w * _value;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..isAntiAlias = true;

    final amplitude = _maxAmplitude * _value;
    final l = _getWaveLength(w);

    final leftPath = Path();

    for (double x = 0; x <= thumbCenter; x += 0.05) {
      if (x == 0) {
        leftPath.moveTo(
          x,
          _f(a: amplitude, l: l, x: x) * -1,
        );
      } else {
        leftPath.lineTo(
          x,
          _f(a: amplitude, l: l, x: x) * -1,
        );
      }
    }

    final rightPath = Path();

    for (double x = thumbCenter; x <= w; x += 0.05) {
      if (x == thumbCenter) {
        rightPath.moveTo(
          x,
          _f(a: amplitude, l: l, x: x) * -1,
        );
      } else {
        rightPath.lineTo(
          x,
          _f(a: amplitude, l: l, x: x) * -1,
        );
      }
    }

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: w + _trackMargin,
          height: _trackHeight,
        ),
        const Radius.circular(40),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          offset,
          offset.translate(w, 0),
          const [
            Color(0xFF38393B),
            Color(0xFF37383A),
          ],
        )
        ..strokeCap = StrokeCap.round,
    );

    context.canvas.drawPath(
      leftPath.shift(offset),
      paint..color = const Color(0xFFA6A7A9),
    );

    context.canvas.drawPath(
      rightPath.shift(offset),
      paint..color = const Color(0xFF8D8D8D).withOpacity(0.4),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final visualPosition = _value;

    final trackRect = _getTrackRect(
      parentBox: this,
      offset: offset,
    );

    final thumbCenter = Offset(
      trackRect.left + visualPosition * trackRect.width,
      trackRect.center.dy,
    );

    _performImpact(visualPosition * trackRect.width);

    _paintTrack(context, trackRect);

    final thumbWidth = _minThumbWidth +
        _thumbWidthRange * _value +
        _maxThumbWidthExtension * _focusValue;
    final thumbHeight = _minThumbHeight +
        _thumbHeightRange * _value +
        _maxThumbHeightExtension * _focusValue;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: thumbCenter,
          width: thumbWidth,
          height: thumbHeight,
        ),
        const Radius.circular(40),
      ),
      Paint()
        ..color = Colors.white
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      // We need to add the drag first so that it has priority.
      _drag.addPointer(event);
      _tap.addPointer(event);

      return;
    }

    if (event is PointerHoverEvent) {
      final visualPosition = _value;

      final trackRect = _getTrackRect(
        parentBox: this,
        offset: Offset.zero,
      );

      final thumbCenter = Offset(
        trackRect.left + visualPosition * trackRect.width,
        trackRect.center.dy,
      );

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: thumbCenter,
          width: _minThumbWidth + _thumbWidthRange * _value,
          height: _minThumbHeight + _thumbHeightRange * _value,
        ),
        const Radius.circular(40),
      );

      final point = globalToLocal(event.position);

      if (rect.contains(point)) {
        _cursor = _grabCursor;

        if (_focusController.status == AnimationStatus.forward) {
          return;
        }

        _focusController.forward();
      } else {
        _cursor = _basicCursor;

        if (_focusController.status == AnimationStatus.reverse) {
          return;
        }

        _focusController.reverse();
      }
    }
  }

  double _discretize(double value) {
    return value.clamp(0.0, 1.0);
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final trackRect = _getTrackRect(
      parentBox: this,
      offset: Offset.zero,
    );

    return (globalToLocal(globalPosition).dx - trackRect.left) /
        trackRect.width;
  }

  void _startInteraction(Offset globalPosition) {
    if (_active) {
      return;
    }

    _active = true;

    _onChangeStart?.call(
      _discretize(value),
    );

    _currentDragValue = _discretize(
      _getValueFromGlobalPosition(globalPosition),
    );

    _valueTween.begin = _value;
    _valueTween.end = _currentDragValue;

    _controller.forward(from: 0).whenComplete(() {
      if (_active) {
        return;
      }

      _onChangeEnd?.call(
        _discretize(_valueTween.end ?? 0),
      );
    });
  }

  void _endInteraction() {
    if (_controller.isAnimating) {
      _active = false;
      _currentDragValue = 0.0;
      return;
    }

    if (!_active) {
      return;
    }

    _onChangeEnd?.call(
      _discretize(_currentDragValue),
    );

    _active = false;

    _currentDragValue = 0.0;
  }

  void _handleDragStart(DragStartDetails details) {
    _cursor = _grabbingCursor;

    if (_focusController.status != AnimationStatus.forward) {
      _focusController.forward();
    }

    _startInteraction(details.globalPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _cursor = _grabbingCursor;

    final trackRect = _getTrackRect(
      parentBox: this,
      offset: Offset.zero,
    );

    final valueDelta = details.primaryDelta! / trackRect.width;

    _currentDragValue += valueDelta;

    _onChanged(
      _discretize(_currentDragValue),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    _cursor = _grabCursor;

    markNeedsPaint();

    _endInteraction();
  }

  void _handleTapDown(TapDownDetails details) {
    _cursor = _grabbingCursor;

    if (_focusController.status != AnimationStatus.forward) {
      _focusController.forward();
    }

    _startInteraction(details.globalPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    _cursor = _grabCursor;

    markNeedsPaint();

    _endInteraction();
  }
}
