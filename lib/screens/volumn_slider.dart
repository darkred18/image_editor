import 'package:flutter/material.dart';

class VolumeSlider extends StatefulWidget {
  final double value; // 0.0 ~ 1.0
  final ValueChanged<double> onChanged;

  const VolumeSlider({super.key, required this.value, required this.onChanged});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double _localValue = 0.5;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  void _handleDrag(DragUpdateDetails details, BoxConstraints c) {
    final dy = details.localPosition.dy;
    double newValue = 1 - (dy / c.maxHeight);

    newValue = newValue.clamp(0.0, 1.0);

    setState(() => _localValue = newValue);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return GestureDetector(
          onVerticalDragUpdate: (d) => _handleDrag(d, c),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 50,
              // height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D3E8), // 아래쪽 연보라
                borderRadius: BorderRadius.circular(50),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 🔹 위쪽 보라색 그라데이션 영역(볼륨값 비율만큼)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 50,
                      height: c.maxHeight * _localValue,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3C1E74), Color(0xFF5A2F9E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // 🔹 아래쪽 스피커 아이콘
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 28,
                      color: Color(0xFF39C8F2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NewVolumeSlider extends StatefulWidget {
  final double value; // 0.0 ~ 1.0
  final ValueChanged<double> onChanged;
  final bool isVertical; // true=세로형, false=가로형

  const NewVolumeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.isVertical = true,
  });

  @override
  State<NewVolumeSlider> createState() => _NewVolumeSliderState();
}

class _NewVolumeSliderState extends State<NewVolumeSlider> {
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  void _handleDrag(DragUpdateDetails details, BoxConstraints c) {
    double newValue;

    if (widget.isVertical) {
      final dy = details.localPosition.dy;
      newValue = 1 - (dy / c.maxHeight);
    } else {
      final dx = details.localPosition.dx;
      newValue = dx / c.maxWidth;
    }

    newValue = newValue.clamp(0.0, 1.0);
    setState(() => _localValue = newValue);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return GestureDetector(
          onVerticalDragUpdate: widget.isVertical
              ? (d) => _handleDrag(d, c)
              : null,
          onHorizontalDragUpdate: widget.isVertical
              ? null
              : (d) => _handleDrag(d, c),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: widget.isVertical ? 60 : 260,
              height: widget.isVertical ? 260 : 60,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Stack(
                alignment: widget.isVertical
                    ? Alignment.bottomCenter
                    : Alignment.centerLeft,
                children: [
                  // 값 비율만큼 채워지는 영역
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: widget.isVertical ? 200 * _localValue : null,
                    width: widget.isVertical ? null : 200 * _localValue,
                    color: Colors.white,
                  ),

                  // 아이콘
                  Center(
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
