import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class DoublePicker extends StatefulWidget {
  DoublePicker({
    super.key,
    required this.items,
    required this.selectedItemChanged,
  });

  late List<List<String>> items;
  final List<int> selectedIndexes = [0, 0];
  final Function selectedItemChanged;

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
  late List<SinglePicker> _pickers;

  @override
  void initState() {
    super.initState();
    _itemFirst = widget.items[0];
    _itemSecond = widget.items[1];

    _scrollControllers = List.generate(
      widget.selectedIndexes.length,
      (i) =>
          FixedExtentScrollController(initialItem: widget.selectedIndexes[i]),
    );
    // 🌟 2. 컨트롤러의 위치에 접근하거나 제어하는 코드를 여기에 배치해야 합니다.

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // 이 블록 안의 코드는 ListWheelScrollView (CupertinoPicker)가
    //   // 화면에 그려져 컨트롤러와 연결된 후에 실행됩니다.

    //   // 🚨 예외를 일으키던 코드를 여기에 넣습니다.
    //   // 예:
    //   print(_scrollControllers[0].selectedItem);

    //   // 예외 없이 안전하게 스크롤 위치를 이동시킬 수도 있습니다.
    //   // _scrollControllers[0].jumpToItem(5);

    //   // 만약 로딩 상태를 업데이트해야 한다면 여기서 setState를 호출합니다.
    //   // setState(() {
    //   //   _isPickerReady = true;
    // });

    _pickers = List.generate(
      (widget.selectedIndexes.length),
      (i) => SinglePicker(
        items: i == 0 ? _itemFirst : _itemSecond,
        controller: _scrollControllers[i],
        onSelectedItemChanged: (int selectedItemIndex) {
          setState(() {
            widget.selectedIndexes[i] = selectedItemIndex;
            widget.selectedItemChanged;
          });
        },
      ),
    );
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
                  "${_itemFirst[widget.selectedIndexes[0]]}  ${_itemSecond[widget.selectedIndexes[1]]}",
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
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
        const SizedBox(height: 30),
      ],
    );
  }
}

class SinglePicker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 40.0,
        scrollController: controller,
        onSelectedItemChanged: onSelectedItemChanged,
        // children: items.map((String item) {
        //   return Center(
        //     child: Text(
        //       item,
        //       style: const TextStyle(fontSize: 20, color: Colors.white70),
        //     ),
        //   );
        // }).toList(),
        children: List.generate(items.length, (index) {
          final value = items[index];
          final isSelected = false; //index == controller.selectedItem;
          return _buildPickerLabel(value, isSelected);
        }),
      ),
    );
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
