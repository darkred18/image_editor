import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';

class PaintControlPanel extends StatelessWidget {
  final ImageEditorState state;

  const PaintControlPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            //--------------------------------
            // 옵션
            //--------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("최소 혼합 모드", style: TextStyle(color: Colors.white70)),
                Switch(
                  value: state.isMinimumCount,
                  onChanged: (v) {
                    state.setMinimumMode(v); // ✅ notify 내부 처리
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            //--------------------------------
            // dominant colors
            //--------------------------------
            if (state.dominantColors.isNotEmpty) ...[
              const Text(
                "Dominant Colors",
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
              Row(
                children: state.dominantColors.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            //--------------------------------
            // 추천 유화 색
            //--------------------------------
            if (state.recommendedPaints.isNotEmpty) ...[
              const Text("추천 유화 색", style: TextStyle(color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.recommendedPaints.length,
                  itemBuilder: (context, i) {
                    final p = state.recommendedPaints[i];

                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            //--------------------------------
            // 혼합 결과
            //--------------------------------
            if (state.bestMix != null) ...[
              const Text("혼합 비율", style: TextStyle(color: Colors.orange)),

              ...List.generate(state.bestMix!.paints.length, (i) {
                final paint = state.bestMix!.paints[i];
                final weight = state.bestMix!.weights[i];

                if (weight <= 0) return const SizedBox();

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        paint.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      "${(weight * 100).round()}%",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              }),
            ],

            const SizedBox(height: 12),

            //--------------------------------
            // 분석 버튼
            //--------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => state.updateRoiAnalysis(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: const Text("색상 분석 다시 실행"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
