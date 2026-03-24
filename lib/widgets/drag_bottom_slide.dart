import 'dart:ui';
import 'package:flutter/material.dart';

class IOSDraggablePanel extends StatefulWidget {
  // final ScrollController scrollController;
  final VoidCallback onClose;

  const IOSDraggablePanel({
    super.key,
    // required this.scrollController,
    required this.onClose,
  });

  @override
  State<IOSDraggablePanel> createState() => _IOSDraggablePanelState();
}

class _IOSDraggablePanelState extends State<IOSDraggablePanel> {
  final bool useAdditionalGrids = false;
  final bool showDiagonal = false;
  final double lineWidth = 1;
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0), // 좌측 상단 모서리 반경 20.0
            topRight: Radius.circular(20.0), // 우측 상단 모서리 반경 20.0
            // bottomLeft과 bottomRight는 지정하지 않으면 기본값인 Radius.zero가 적용되어 직각 유지
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              child: Column(
                children: [
                  // 🔹 Scrollable content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        SwitchListTile(
                          title: const Text("Use Additional Grids"),
                          value: useAdditionalGrids,
                          onChanged: (v) {
                            // widget.onUseAdditionalGridsChanged(v);
                            // setState(() {});
                          },
                        ),

                        SwitchListTile(
                          title: const Text("Show Diagonal Lines"),
                          value: showDiagonal,
                          onChanged: (v) {
                            // widget.onShowDiagonalChanged(v);
                            // setState(() {});
                          },
                        ),

                        const Text("Line Width:"),
                        Slider(
                          min: 0.5,
                          max: 10,
                          value: lineWidth,
                          onChanged: (v) {
                            // widget.onLineWidthChanged(v);
                            // setState(() {});
                          },
                        ),

                        ListTile(
                          title: const Text("Templates"),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                        ListTile(
                          title: const Text("More Settings"),
                          trailing: const Icon(Icons.chevron_right),
                        ),

                        const SizedBox(height: 40),
                      ],
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

  Widget _buildSlider(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        Slider(
          min: 0,
          max: 100,
          value: 50,
          onChanged: (v) {},
          activeColor: Colors.white,
          inactiveColor: Colors.white24,
        ),
      ],
    );
  }
}
