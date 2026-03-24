import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SimpleCupertinoPickerExample extends StatefulWidget {
  const SimpleCupertinoPickerExample({super.key});

  @override
  State<SimpleCupertinoPickerExample> createState() =>
      _SimpleCupertinoPickerExampleState();
}

class _SimpleCupertinoPickerExampleState
    extends State<SimpleCupertinoPickerExample> {
  // Picker 데이터
  final List<String> options = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Elderberry',
  ];

  // 선택된 값
  String selectedValue = 'Apple';

  // Scroll 위치를 관리하는 controller
  late FixedExtentScrollController scrollController;

  @override
  void initState() {
    super.initState();
    // 초기 선택값 위치 계산
    int initialIndex = options.indexOf(selectedValue);
    scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CupertinoPicker Sample')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Selected: $selectedValue', style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              scrollController: scrollController,
              itemExtent: 40, // 각 아이템 높이
              onSelectedItemChanged: (index) {
                setState(() {
                  selectedValue = options[index];
                });
              },
              children: options
                  .map(
                    (item) => Center(
                      child: Text(item, style: TextStyle(fontSize: 20)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 1. **key** 매개변수를 포함한 공개 위젯 (Best Practice)
class CupertinoListPickerSample extends StatefulWidget {
  const CupertinoListPickerSample({super.key});

  @override
  State<CupertinoListPickerSample> createState() =>
      _CupertinoListPickerSampleState();
}

class _CupertinoListPickerSampleState extends State<CupertinoListPickerSample> {
  // 선택할 항목 리스트 (일반적인 문자열 리스트)
  final List<String> _themes = ['레드', '블루', '그린', '퍼플', '오렌지', '시안'];

  // 현재 선택된 값 (초기값은 첫 번째 항목)
  String _selectedTheme = '레드';

  // 리스트 Picker를 Bottom Sheet 형태로 보여주는 함수
  void _showThemePicker() {
    // 2. 초기 선택 인덱스 설정 (현재 선택된 값의 위치)
    int initialIndex = _themes.indexOf(_selectedTheme);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200, // Picker 영역 높이
          width: 200,
          color: const Color.fromARGB(255, 236, 173, 173), // 배경색
          child: Column(
            children: [
              // Picker 상단의 '완료' 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('완료'),
                    onPressed: () {
                      Navigator.of(context).pop(); // 모달 닫기
                    },
                  ),
                ],
              ),
              // 3. 실제 항목 리스트를 스크롤할 수 있는 CupertinoPicker
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40.0, // 각 항목의 높이
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex, // 초기 스크롤 위치 지정
                  ),
                  // 항목 선택이 변경될 때 호출
                  onSelectedItemChanged: (int selectedItemIndex) {
                    // 4. 상태를 즉시 업데이트하지 않고, 임시 변수를 사용하는 것이 더 일반적이나,
                    // 여기서는 편의상 setState를 사용합니다.
                    setState(() {
                      _selectedTheme = _themes[selectedItemIndex];
                    });
                  },
                  // 5. 항목 리스트 구성
                  children: _themes.map((String theme) {
                    return Center(
                      child: Text(
                        theme,
                        style: const TextStyle(
                          fontSize: 22,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CupertinoPicker 일반 리스트 샘플')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('현재 선택된 테마:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            // 선택된 값 표시
            Text(
              _selectedTheme,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _getColorFromName(_selectedTheme), // 선택된 테마에 맞춰 색상 변경
              ),
            ),
            const SizedBox(height: 30),
            // Picker를 띄우는 버튼
            ElevatedButton(
              onPressed: _showThemePicker,
              child: const Text('테마 색상 선택'),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 문자열에 맞는 실제 Flutter Color를 반환하는 헬퍼 함수
  Color _getColorFromName(String name) {
    switch (name) {
      case '레드':
        return Colors.red;
      case '블루':
        return Colors.blue;
      case '그린':
        return Colors.green;
      case '퍼플':
        return Colors.purple;
      case '오렌지':
        return Colors.orange;
      case '시안':
        return Colors.cyan;
      default:
        return Colors.black;
    }
  }
}

class AnimatedPickerSample extends StatefulWidget {
  // Good Practice: key 매개변수 포함
  const AnimatedPickerSample({super.key});

  @override
  State<AnimatedPickerSample> createState() => _AnimatedPickerSampleState();
}

class _AnimatedPickerSampleState extends State<AnimatedPickerSample> {
  // 선택할 항목 리스트
  final List<String> _themes = ['레드', '블루', '그린', '퍼플', '오렌지', '시안'];

  // 현재 선택된 값
  String _selectedTheme = '레드';

  // 🌟 Picker 표시 여부를 제어하는 상태 변수
  bool _isPickerVisible = false;

  // CupertinoPicker의 현재 선택 인덱스를 임시 저장
  int _currentPickerIndex = 0;

  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    // 초기 선택 값의 인덱스 설정
    _currentPickerIndex = _themes.indexOf(_selectedTheme);
    _controller = FixedExtentScrollController(initialItem: _currentPickerIndex);
  }

  // 3. 위젯이 메모리에서 해제될 때 컨트롤러 해제
  @override
  void dispose() {
    _controller.dispose(); // **메모리 누수 방지**
    super.dispose();
  }

  // 1. Picker 표시 상태를 토글하는 함수
  void _togglePicker() {
    setState(() {
      _isPickerVisible = !_isPickerVisible;
    });
  }

  // 선택된 문자열에 맞는 실제 Flutter Color를 반환하는 헬퍼 함수
  Color _getColorFromName(String name) {
    switch (name) {
      case '레드':
        return Colors.red;
      case '블루':
        return Colors.blue;
      case '그린':
        return Colors.green;
      case '퍼플':
        return Colors.purple;
      case '오렌지':
        return Colors.orange;
      case '시안':
        return Colors.cyan;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('애니메이션 확장 리스트 피커')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 선택된 값 표시
            Text(
              '현재 테마: $_selectedTheme',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getColorFromName(_selectedTheme),
              ),
            ),
            const SizedBox(height: 100),

            // 2. 피커 토글 버튼 (버튼 자체가 확장되지는 않고, 버튼을 누르면 아래 영역이 확장됨)
            OutlinedButton.icon(
              onPressed: _togglePicker,
              icon: Icon(
                _isPickerVisible
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              label: Text(_isPickerVisible ? '선택 완료 (닫기)' : '테마 색상 선택 (열기)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 10),

            // 3. 🌟 AnimatedSize 위젯으로 높이 애니메이션 적용
            AnimatedSize(
              duration: const Duration(milliseconds: 300), // 애니메이션 지속 시간
              curve: Curves.easeInOut, // 애니메이션 곡선
              child: ClipRect(
                // 애니메이션 시 경계면 처리
                // 4. Picker의 높이를 조건부로 설정
                child: SizedBox(
                  height: _isPickerVisible
                      ? 200.0
                      : 0.0, // 표시 상태에 따라 높이를 200.0 또는 0.0으로 설정
                  child: CupertinoPicker(
                    itemExtent: 40.0,
                    // Picker의 초기 스크롤 위치를 현재 선택된 값으로 맞춤
                    scrollController: _controller,
                    onSelectedItemChanged: (int selectedItemIndex) {
                      // 5. 사용자가 스크롤 할 때마다 상태 업데이트 (반영)
                      setState(() {
                        _selectedTheme = _themes[selectedItemIndex];
                      });
                    },
                    children: _themes.map((String theme) {
                      return Text(
                        theme,
                        style: TextStyle(
                          fontSize: 22,
                          color: theme == _selectedTheme
                              ? Colors.amber
                              : Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
//
// 2. **가로 분할 이중 피커 샘플**
class TwoColumnPickerSample extends StatefulWidget {
  const TwoColumnPickerSample({super.key});

  @override
  State<TwoColumnPickerSample> createState() => _TwoColumnPickerSampleState();
}

class _TwoColumnPickerSampleState extends State<TwoColumnPickerSample> {
  // 1. 두 개의 과일 리스트 정의
  final List<String> _fruits1 = ['사과', '바나나', '딸기', '포도', '오렌지', '자두'];
  final List<String> _fruits2 = ['키위', '망고', '수박', '멜론', '복숭아', '블루베리'];

  // 2. 두 개의 선택 값 상태 변수
  String _selectedFruit1 = '사과';
  String _selectedFruit2 = '키위';

  // Picker 표시 여부 상태 변수
  bool _isPickerVisible = false;

  // 3. 두 개의 스크롤 컨트롤러 선언
  late FixedExtentScrollController _scrollController1;
  late FixedExtentScrollController _scrollController2;

  // 4. 컨트롤러 초기화 (모범 사례)
  @override
  void initState() {
    super.initState();
    _scrollController1 = FixedExtentScrollController(
      initialItem: _fruits1.indexOf(_selectedFruit1),
    );
    _scrollController2 = FixedExtentScrollController(
      initialItem: _fruits2.indexOf(_selectedFruit2),
    );
  }

  // 5. 컨트롤러 해제 (모범 사례)
  @override
  void dispose() {
    _scrollController1.dispose(); // 첫 번째 컨트롤러 해제
    _scrollController2.dispose(); // 두 번째 컨트롤러 해제
    super.dispose();
  }

  // Picker 표시 상태를 토글하는 함수
  void _togglePicker() {
    setState(() {
      _isPickerVisible = !_isPickerVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가로 분할 이중 피커 샘플')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 🌟 두 개의 선택 값 표시
            Text(
              '선택된 과일: $_selectedFruit1, $_selectedFruit2',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // 피커 토글 버튼
            OutlinedButton.icon(
              onPressed: _togglePicker,
              icon: Icon(
                _isPickerVisible
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              label: Text(_isPickerVisible ? '선택 완료 (닫기)' : '과일 선택 (열기)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 10),

            // 6. AnimatedSize 위젯으로 높이 애니메이션 적용
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ClipRect(
                child: SizedBox(
                  height: _isPickerVisible ? 200.0 : 0.0,
                  // 7. 🌟 Row 위젯으로 두 피커를 가로로 배치
                  child: Row(
                    children: <Widget>[
                      // 8. 첫 번째 피커 (Expanded로 공간 균등 분할)
                      Expanded(
                        child: CupertinoPicker(
                          backgroundColor: Colors.amber[50],
                          itemExtent: 40.0,
                          scrollController: _scrollController1, // 전용 컨트롤러 사용
                          onSelectedItemChanged: (int selectedItemIndex) {
                            setState(() {
                              _selectedFruit1 =
                                  _fruits1[selectedItemIndex]; // 첫 번째 값 업데이트
                            });
                          },
                          children: _fruits1.map((String fruit) {
                            return Center(
                              child: Text(
                                fruit,
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // 9. 두 번째 피커
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40.0,
                          scrollController: _scrollController2, // 전용 컨트롤러 사용
                          onSelectedItemChanged: (int selectedItemIndex) {
                            setState(() {
                              _selectedFruit2 =
                                  _fruits2[selectedItemIndex]; // 두 번째 값 업데이트
                            });
                          },
                          children: _fruits2.map((String fruit) {
                            return Center(
                              child: Text(
                                fruit,
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. 재사용 가능한 단일 피커 위젯 (StatelessWidget)
class SingleFruitPickerColumn extends StatelessWidget {
  final List<String> items;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;

  const SingleFruitPickerColumn({
    super.key,
    required this.items,
    required this.controller,
    required this.onSelectedItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 40.0,
        scrollController: controller,
        onSelectedItemChanged: onSelectedItemChanged,
        children: items.map((String fruit) {
          return Center(
            child: Text(
              fruit,
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NTwoColumnPickerSample extends StatefulWidget {
  const NTwoColumnPickerSample({super.key});

  @override
  State<NTwoColumnPickerSample> createState() => _NTwoColumnPickerSampleState();
}

class _NTwoColumnPickerSampleState extends State<NTwoColumnPickerSample> {
  // 1. 상태 및 데이터는 그대로 유지
  final List<String> _fruits1 = ['사과', '바나나', '딸기', '포도', '오렌지', '자두'];
  final List<String> _fruits2 = ['키위', '망고', '수박', '멜론', '복숭아', '블루베리'];

  bool _isPickerVisible = false;
  final double _pickerHeight = 250.0;
  final Duration _animationDuration = Duration(milliseconds: 250);
  // String _selectedFruit1 = '사과';
  // String _selectedFruit2 = '키위';

  // late FixedExtentScrollController _scrollController1;
  // late FixedExtentScrollController _scrollController2;

  final List<int> _selectedIndexes = [0, 0];
  final List<FixedExtentScrollController> _scrollControllers = [];

  final List<SingleFruitPickerColumn> _pickers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _selectedIndexes.length; i++) {
      _scrollControllers.add(
        FixedExtentScrollController(initialItem: _selectedIndexes[i]),
      );
      _pickers.add(
        SingleFruitPickerColumn(
          items: i == 0 ? _fruits1 : _fruits2,
          controller: _scrollControllers[i],
          onSelectedItemChanged: (int selectedItemIndex) {
            setState(() {
              _selectedIndexes[i] = selectedItemIndex;
            });
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildPickerContainer() {
    return AnimatedSize(
      duration: _animationDuration,
      curve: Curves.easeInOut,

      // 🌟 1. AnimatedOpacity 추가
      child: AnimatedOpacity(
        // 현재 _isPickerVisible 상태에 따라 투명도(opacity) 결정
        // 열려있을 때(true)는 1.0 (불투명), 닫혀있을 때(false)는 0.0 (투명)
        opacity: _isPickerVisible ? 1.0 : 0.0,

        // 높이 애니메이션과 동일한 지속 시간을 사용하여 동기화
        duration: _animationDuration,
        curve: Curves.easeInOut,

        child: ClipRect(
          // 2. AnimatedSize의 자식으로 Picker 영역 배치
          child: SizedBox(
            // 높이: AnimatedSize가 이 높이 변화를 감지하여 애니메이션을 실행합니다.
            height: _isPickerVisible ? _pickerHeight - 50 : 0.0,
            child: Row(
              children: [
                // ... _SingleFruitPickerColumn 위젯들 ...
                _pickers[0],
                _pickers[1],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerButton() {
    return Container(
      // height: 60,
      width: 300,
      alignment: Alignment.center,
      child: Column(
        children: [
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                _isPickerVisible = !_isPickerVisible;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_fruits1[_selectedIndexes[0]]}  ${_fruits2[_selectedIndexes[1]]}",
                  style: const TextStyle(color: Colors.amber, fontSize: 18),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isPickerVisible
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_up,
                  color: Colors.amber,
                  size: 18,
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          _buildPickerContainer(),
        ],
      ),
    );
  }

  // 3. 최종 build 메서드는 레이아웃 구조만 담당
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('리팩토링된 이중 피커 샘플')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              '선택된 과일: ${_fruits1[_selectedIndexes[0]]}, ${_fruits2[_selectedIndexes[1]]}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 200),
            Center(
              child: AnimatedContainer(
                duration: _animationDuration,
                curve: Curves.easeInOut,
                width: 200,
                height: _isPickerVisible ? _pickerHeight : 45, // 버튼이 위로 확장됨
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: _pickerButton(),
              ),
            ),

            // 🌟 추출된 메서드 사용
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
