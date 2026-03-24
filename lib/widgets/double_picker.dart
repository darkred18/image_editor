import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class DoublePicker extends StatefulWidget {
  DoublePicker({
    super.key,
    required this.items,
    required this.selectedItemChanged,
    required this.selectedIndexes,
  });

  late List<List<String>> items;
  late List<int> selectedIndexes;
  final VoidCallback selectedItemChanged;

  @override
  State<DoublePicker> createState() => _DoublePickerState();
}

class _DoublePickerState extends State<DoublePicker> {
  bool _isPickerVisible = false;
  final double _pickerHeight = 250.0;
  final Duration _animationDuration = Duration(milliseconds: 250);
  // String _selectedFruit1 = '사과';
  // String _selectedFruit2 = '키위';

  // late FixedExtentScrollController _scrollController1;
  // late FixedExtentScrollController _scrollController2;

  // final List<int> _selectedIndexes = [0, 0];
  // 1. 상태 및 데이터는 그대로 유지
  late List<String> _itemFirst; // ['사과', '바나나', '딸기', '포도', '오렌지', '자두'];
  late List<String> _itemSecond; //['키위', '망고', '수박', '멜론', '복숭아', '블루베리'];

  late List<FixedExtentScrollController> _scrollControllers;
  // late List<SinglePicker> _pickers;
  late SinglePicker _picker1;
  late SinglePicker _picker2;

  @override
  void initState() {
    super.initState();
    _itemFirst = widget.items[0];
    _itemSecond = widget.items[1].map((e) => '$e호').toList();

    _scrollControllers = List.generate(
      widget.selectedIndexes.length,
      (i) =>
          FixedExtentScrollController(initialItem: widget.selectedIndexes[i]),
    );

    _picker1 = SinglePicker(
      items: _itemFirst,
      controller: _scrollControllers[0],
      onSelectedItemChanged: _picker1Changed,
    );
    _picker2 = SinglePicker(
      items: _itemSecond,
      controller: _scrollControllers[1],
      onSelectedItemChanged: _picker2Changed,
    );

    // 🌟 컨트롤러의 상태를 읽거나 쓰려는 코드를 여기에 넣습니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(_picker1.controller.selectedItem);
      print(_picker2.controller.selectedItem);
    });
  }

  void _picker1Changed(int index) {
    // print('_picker1Changed 1: $index ');
    setState(() {
      widget.selectedIndexes[0] = index;
    });
    widget.selectedItemChanged();
    if (index == 0) {
      print('index : $index');
    }
  }

  void _picker2Changed(int index) {
    // print('_picker2Changed 2: $index ');
    setState(() {
      widget.selectedIndexes[1] = index;
    });
    widget.selectedItemChanged();
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
                _picker1,
                _picker2,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerTitleButton() {
    return Container(
      // height: 60,
      // width: 200,
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
                  "${_itemFirst[widget.selectedIndexes[0]]}  ${_itemSecond[widget.selectedIndexes[1]]}",
                  style: const TextStyle(color: Colors.amber, fontSize: 20),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isPickerVisible
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_up,
                  color: Colors.amber,
                  size: 20,
                ),
              ],
            ),
          ),
          // SizedBox(height: 5),
          _buildPickerContainer(),
        ],
      ),
    );
  }

  // 3. 최종 build 메서드는 레이아웃 구조만 담당
  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Center(
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            width: 200,
            height: _isPickerVisible ? _pickerHeight : 50, // 버튼이 위로 확장됨
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(25),
            ),

            child: _pickerTitleButton(),
          ),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class SinglePicker extends StatefulWidget {
  final List<String> items;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;

  const SinglePicker({
    super.key,
    required this.items,
    required this.controller,
    required this.onSelectedItemChanged,
  });

  @override
  State<SinglePicker> createState() => _SinglePickerState();
}

class _SinglePickerState extends State<SinglePicker> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 40.0,
        scrollController: widget.controller,
        onSelectedItemChanged: _changedValue,
        children: List.generate(widget.items.length, (index) {
          final value = widget.items[index];
          // print('value : $value');
          // 🌟 컨트롤러의 상태를 읽거나 쓰려는 코드를 여기에 넣습니다.
          final isSelected = index == _selectedIndex;
          return _buildPickerLabel(value, isSelected);
        }),
      ),
    );
  }

  void _changedValue(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onSelectedItemChanged(index);
  }

  Widget _buildPickerLabel(String text, bool isSelected, {bool addHo = false}) {
    return Center(
      child: Text(
        addHo ? "$text호" : text,
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white,
          fontSize: isSelected ? 22 : 20,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
