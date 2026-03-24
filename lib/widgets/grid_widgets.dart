import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:image_editor/screens/volumn_slider.dart';

// MARK: - 메인 뷰 (배경 이미지와 모달 트리거)

class GridViewPage extends StatefulWidget {
  const GridViewPage({super.key});

  @override
  State<GridViewPage> createState() => _GridViewPageState();
}

class _GridViewPageState extends State<GridViewPage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  // 더미 이미지 바이트를 생성하는 함수 (실제 앱에서는 파일 로드/네트워크에서 받아옴)
  Future<void> _loadImageBytes() async {
    // 실제 이미지 대신, 임시로 작은 더미 PNG 이미지 바이트를 생성합니다.
    // 사용자님의 실제 Uint8List 데이터를 여기에 할당하세요.
    final dummyBytes = _createDummyImageBytes();

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _imageBytes = dummyBytes;
      _isLoading = false;
    });
  }

  // 1x1 픽셀 PNG 바이트 (매우 작고 빠른 로딩을 위함)
  Uint8List _createDummyImageBytes() {
    return Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      8,
      2,
      0,
      0,
      0,
      144,
      119,
      83,
      222,
      0,
      0,
      0,
      10,
      73,
      68,
      65,
      84,
      120,
      156,
      99,
      0,
      1,
      0,
      0,
      5,
      0,
      1,
      13,
      10,
      2,
      123,
      145,
      0,
      0,
      0,
      0,
      73,
      69,
      78,
      68,
      174,
      66,
      96,
      130,
    ]);
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const SettingsBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // 1. 배경 이미지 (Uint8List 사용)
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_imageBytes != null)
            Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              opacity: const AlwaysStoppedAnimation(0.4),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.red.shade100,
                  width: double.infinity,
                  height: double.infinity,
                  child: const Center(child: Text("이미지 로드 실패")),
                );
              },
            )
          else
            Container(
              color: Colors.grey[300],
              width: double.infinity,
              height: double.infinity,
              child: const Center(child: Text("배경 이미지가 없습니다")),
            ),

          // 모달을 띄우는 버튼
          Center(
            child: ElevatedButton(
              onPressed: _openSettingsModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text('설정 열기', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - 설정 뷰 (스크롤 가능한 내용)

class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  // 설정 값들을 위한 State 변수
  bool _useAdditionalGrids = false;
  final int _rows = 7;
  final double _colCount = 10.0;
  Color _gridColor = Colors.white; // Color 타입 유지
  double _lineWidth = 3.0;
  bool _showDiagonalLines = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        children: [
          _buildModalHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // SizedBox(
                  //   height: 200,
                  //   child: VolumeSlider(
                  //     value: 0.4,
                  //     onChanged: (v) {
                  //       print("volume = $v");
                  //     },
                  //   ),
                  // ),
                  NewVolumeSlider(
                    value: 80,
                    onChanged: (value) {},
                    isVertical: true,
                  ),
                  // MARK: - Use Additional Grids (복원)
                  _buildSettingsToggle(
                    title: 'Use Additional Grids',
                    value: _useAdditionalGrids,
                    onChanged: (val) =>
                        setState(() => _useAdditionalGrids = val),
                  ),
                  const Divider(),

                  // MARK: - Grid Type (복원)
                  _buildNavigationRow(
                    title: 'Grid Type:',
                    subtitle: 'Square(Set rows only)',
                    onTap: () {},
                  ),

                  // // MARK: - row/col Slider
                  // _buildSettingsSlider(
                  //   label: 'row:',
                  //   value: _rows.toDouble(),
                  //   max: 20.0,
                  //   onChanged: (val) => setState(() => _rows = val.round()),
                  //   displayValue: _rows.toString(),
                  // ),
                  // _buildSettingsSlider(
                  //   label: 'col:',
                  //   value: _colCount,
                  //   max: 20.0,
                  //   onChanged: (val) => setState(() => _colCount = val),
                  //   displayValue: _colCount.round().toString(),
                  // ),
                  const Divider(),

                  // MARK: - Grid Color (Color Picker)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, bottom: 5.0),
                    child: Text(
                      'Grid Color:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  _buildColorPicker(context), // <--- 문제 발생 지점 주변

                  const Divider(),

                  // MARK: - Line Width (복원)
                  _buildSettingsSlider(
                    label: 'Line Width:',
                    value: _lineWidth,
                    max: 10.0,
                    onChanged: (val) => setState(() => _lineWidth = val),
                    displayValue: _lineWidth.round().toString(),
                  ),

                  const Divider(),

                  // MARK: - Show Diagonal Lines (복원)
                  _buildDiagonalLinesRow(),

                  const Divider(),

                  // MARK: - Templates / More Settings (복원)
                  _buildNavigationRow(
                    title: 'Templates',
                    onTap: () {},
                    showChevron: true,
                  ),

                  const Divider(),

                  _buildNavigationRow(
                    title: 'More Settings',
                    onTap: () {},
                    showChevron: true,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - 재사용 가능한 위젯 함수들 (전체 코드에 포함되어야 함)

  // _buildModalHeader (생략: 위에서 복원됨)
  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // _buildSettingsToggle (생략)
  Widget _buildSettingsToggle({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.green,
        ),
      ],
    );
  }

  // _buildSettingsSlider (생략: 위에서 사용됨)
  Widget _buildSettingsSlider({
    required String label,
    required double value,
    required double max,
    required Function(double) onChanged,
    required String displayValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            '$label $displayValue',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        // Slider(
        //   value: value,
        //   min: range,
        //   max: max,
        //   divisions: ((max - range) / step).round(),
        //   onChanged: onChanged,
        //   activeColor: Colors.blue,
        // ),
        IOSVolumeHudHorizontal(onChanged: onChanged, value: value),
      ],
    );
  }

  // _buildNavigationRow (생략)
  Widget _buildNavigationRow({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showChevron = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          if (showChevron) const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  // _buildDiagonalLinesRow (생략)
  Widget _buildDiagonalLinesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Show Diagonal Lines', style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Switch(
              value: _showDiagonalLines,
              onChanged: (val) => setState(() => _showDiagonalLines = val),
              activeThumbColor: Colors.green,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'pro',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // MARK: - _buildColorPicker (복원된 버튼 로직 포함)

  Widget _buildColorPicker(BuildContext context) {
    // _gridColor가 Flutter 표준 Color 타입임을 가정하고,
    // .r, .g, .b 속성이 아닌 .red, .green, .blue getter를 사용합니다.

    // 만약 사용자님의 환경에서 반드시 .r, .g, .b를 써야 한다면
    // 아래 변수 선언만 final r = _gridColor.r; 등으로 바꿔주세요.

    final r = _gridColor.r * 255;
    final g = _gridColor.g * 255;
    final b = _gridColor.b * 255;
    final aStr = _gridColor.a.toStringAsFixed(1);

    return Column(
      children: [
        // R G B A 값 표시 (Text)
        _buildColorComponentDisplay('R:', r.toString(), Colors.red),
        _buildColorComponentDisplay('G:', g.toString(), Colors.green),
        _buildColorComponentDisplay('B:', b.toString(), Colors.blue),
        _buildColorComponentDisplay('A:', aStr, null),

        // Color Picker 버튼 (복원된 버튼 로직)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gridColor,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // 임시 색상 변경 로직 (실제 Color Picker를 연결해야 합니다.)
                  setState(() {
                    _gridColor = (_gridColor == Colors.white)
                        ? Colors.blue
                        : Colors.white;
                  });
                },
                child: const Text('색상 변경 (임시)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // _SettingsBottomSheetState 클래스 내부

  // MARK: - _buildColorComponentDisplay (포인터 움직임 및 상태 업데이트 적용)

  double getColorValue(double c) {
    return c * 255.0;
  }

  Widget _buildColorComponentDisplay(
    String label,
    String value,
    Color? sliderColor,
  ) {
    // 현재 _gridColor 상태에서 R, G, B, A 값을 다시 추출합니다.
    final bool isAlpha = label == 'A:';

    // 현재 성분의 0-255 정수 값 또는 0.0-1.0 실수 값
    double currentComponentValue = 0.0;

    // 널 안전성을 위해 .red 등을 직접 사용합니다. (커스텀 속성이라면 .r로 변경)
    if (label == 'R:') currentComponentValue = getColorValue(_gridColor.r);
    if (label == 'G:') currentComponentValue = getColorValue(_gridColor.g);
    if (label == 'B:') currentComponentValue = getColorValue(_gridColor.b);
    if (label == 'A:') currentComponentValue = _gridColor.a;

    // Slider의 값 (0.0 ~ 1.0 범위)
    final double sliderValue = isAlpha
        ? currentComponentValue
        : currentComponentValue / 255.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 텍스트 표시 (현재 상태 _gridColor를 반영)
          SizedBox(
            width: 70,
            child: Text(
              '$label${isAlpha ? currentComponentValue.toStringAsFixed(1) : currentComponentValue.round()}',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          Expanded(
            child: Slider(
              value: sliderValue,
              min: 0.0,
              max: 1.0,
              onChanged: (double newValue) {
                // 1. ⚠️ setState() 호출: 포인터를 움직이고 UI를 업데이트합니다.
                setState(() {
                  final int newColorInt = (newValue * 255).round();

                  // 2. 새 Color 객체 생성 및 _gridColor 업데이트
                  if (label == 'R:') {
                    _gridColor = _gridColor.withRed(newColorInt);
                    print('Slider Moved: R -> $newColorInt');
                  } else if (label == 'G:') {
                    _gridColor = _gridColor.withGreen(newColorInt);
                    print('Slider Moved: G -> $newColorInt');
                  } else if (label == 'B:') {
                    _gridColor = _gridColor.withBlue(newColorInt);
                    print('Slider Moved: B -> $newColorInt');
                  } else if (label == 'A:') {
                    // Alpha는 0.0 ~ 1.0 실수 값을 직접 사용
                    _gridColor = _gridColor.withOpacity(newValue);
                    print(
                      'Slider Moved: Alpha -> ${newValue.toStringAsFixed(2)}',
                    );
                  }
                });
              },
              activeColor: sliderColor ?? Colors.grey,
            ),
          ),

          // 색상 원 표시 (새로운 _gridColor 상태를 반영)
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
              // isAlpha가 아닐 경우, sliderColor 대신 _gridColor 자체를 사용하여 최종 색상 반영
              color: isAlpha
                  ? _gridColor
                  : sliderColor != null
                  ? sliderColor.withAlpha(
                      _gridColor.alpha,
                    ) // Alpha값을 사용하여 R, G, B 색상에 반영
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

int opacity(double percent) => (percent * 255).toInt();

Widget customSlider({
  required double value,
  required ValueChanged<double> onChanged,
  Color activeColor = Colors.blue,
}) {
  return SliderTheme(
    data: SliderThemeData(
      trackHeight: 3, // 얇은 트랙
      activeTrackColor: activeColor.withAlpha(opacity(0.8)),
      inactiveTrackColor: activeColor.withAlpha(opacity(0.2)),

      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 8, // 작은 원 핸들
      ),
      thumbColor: activeColor,
      overlayColor: activeColor.withAlpha(opacity(0.2)), // 터치 시 확장되는 영역
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      trackShape: const RoundedRectSliderTrackShape(),
    ),
    child: Slider(min: 0, max: 255, value: value, onChanged: onChanged),
  );
}

Widget appleSlider({
  required double value,
  required ValueChanged<double> onChanged,
  Color trackColor = const Color(0xFF007AFF),
}) {
  return SliderTheme(
    data: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: trackColor,
      inactiveTrackColor: Colors.grey.shade300,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 10,
        elevation: 2,
        pressedElevation: 4,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      overlayColor: trackColor.withAlpha(40), // 부드러운 강조
      thumbColor: Colors.white,
    ),
    child: Slider(value: value, min: 0, max: 255, onChanged: onChanged),
  );
}

class IOSVolumeHudHorizontal extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final ValueChanged<double> onChanged; // 값 변경 콜백

  const IOSVolumeHudHorizontal({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 아이콘
          Positioned(
            top: 10,
            child: Icon(
              CupertinoIcons.speaker_2_fill,
              color: Colors.white,
              size: 24,
            ),
          ),

          // 바 전체
          Container(
            height: 120,
            width: 320,
            padding: const EdgeInsets.only(top: 40),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final newValue = (value + details.delta.dx / 250).clamp(
                  0.0,
                  1.0,
                );
                onChanged(newValue);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    // 배경
                    Container(color: Colors.white.withOpacity(0.2)),

                    // 채워진 영역
                    FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
