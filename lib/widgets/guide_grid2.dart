import 'package:flutter/material.dart';

class SettingsBottomSheet2 extends StatefulWidget {
  final bool useAdditionalGrids;
  final bool showDiagonal;
  final double lineWidth;

  // final ValueChanged<bool> onUseAdditionalGridsChanged;
  // final ValueChanged<bool> onShowDiagonalChanged;
  // final ValueChanged<double> onLineWidthChanged;

  const SettingsBottomSheet2({
    super.key,
    required this.useAdditionalGrids,
    required this.showDiagonal,
    required this.lineWidth,
    // required this.onUseAdditionalGridsChanged,
    // required this.onShowDiagonalChanged,
    // required this.onLineWidthChanged,
  });

  @override
  State<SettingsBottomSheet2> createState() => _SettingsBottomSheet2State();
}

class _SettingsBottomSheet2State extends State<SettingsBottomSheet2> {
  double sheetHeightRatio = 0.5;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
          height: MediaQuery.of(context).size.height * sheetHeightRatio,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setInnerState(() {
                    sheetHeightRatio -=
                        details.delta.dy / MediaQuery.of(context).size.height;
                    sheetHeightRatio = sheetHeightRatio.clamp(0.2, 0.9);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    SwitchListTile(
                      title: const Text("Use Additional Grids"),
                      value: widget.useAdditionalGrids,
                      onChanged: (v) {
                        // widget.onUseAdditionalGridsChanged(v);
                        // setState(() {});
                      },
                    ),

                    SwitchListTile(
                      title: const Text("Show Diagonal Lines"),
                      value: widget.showDiagonal,
                      onChanged: (v) {
                        // widget.onShowDiagonalChanged(v);
                        // setState(() {});
                      },
                    ),

                    const Text("Line Width:"),
                    Slider(
                      min: 0.5,
                      max: 10,
                      value: widget.lineWidth,
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
        );
      },
    );
  }
}
