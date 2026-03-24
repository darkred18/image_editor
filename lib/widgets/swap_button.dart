import 'package:flutter/material.dart';

class SwapRadioButtons extends StatefulWidget {
  final Function(bool isSwapped) onChanged;

  const SwapRadioButtons({super.key, required this.onChanged});

  @override
  State<SwapRadioButtons> createState() => _SwapRadioButtonsState();
}

class _SwapRadioButtonsState extends State<SwapRadioButtons> {
  bool isSwapped = false;
  final double _width = 50;
  final double _height = 35;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildButton("가로", false),
        const SizedBox(width: 12),
        _buildButton("세로", true),
      ],
    );
  }

  Widget _buildButton(String text, bool targetValue) {
    final selected = isSwapped == targetValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          isSwapped = targetValue;
        });

        widget.onChanged(isSwapped);
      },
      child: Container(
        width: targetValue ? _height : _width,
        height: targetValue ? _width : _height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: selected ? Colors.blue : Colors.blue,
            width: 1,
          ),
        ),
        child: selected ? Icon(Icons.check, color: Colors.white) : null,
        // Text(
        //   text,
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.bold,
        //     color: selected ? Colors.white : Colors.black,
        //   ),
        // ),
      ),
    );
  }
}
