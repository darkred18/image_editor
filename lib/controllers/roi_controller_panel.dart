import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';

class RoiControlPanel extends StatelessWidget {
  final ImageEditorState state; // preview 데이터 접근을 위해 state 전체를 전달받음

  const RoiControlPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 🎯 높이를 고정하여 하단 UI 변화로 인한 화면 흔들림 방지
      height: 280,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 🎯 신규 추가: ROI 프리뷰 영역 (색상분석 패널 디자인 유지)
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: state.croppedPreview != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(
                          state.croppedPreview!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.center_focus_weak,
                        color: Colors.white24,
                      ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "현재 선택 영역",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "크기: ${state.roiSize.toInt()} px",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "상태: ${state.isMinimumCount ? '최소 혼합' : '일반 분석'}",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ROI 크기 조절 슬라이더
          Row(
            children: [
              const Text("크기 조절", style: TextStyle(color: Colors.white70)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.amber,
                    thumbColor: Colors.amber,
                  ),
                  child: Slider(
                    value: state.roiSize,
                    min: 20,
                    max: 120,
                    onChanged: (v) => state.setRoiSize(v),
                  ),
                ),
              ),
            ],
          ),

          // 최소 색 조합 모드 스위치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("최소 혼합 모드", style: TextStyle(color: Colors.white70)),
              Switch(
                value: state.isMinimumCount,
                onChanged: (v) => state.setMinimumMode(v),
                activeColor: Colors.amber,
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => state.updateRoiAnalysis(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text("영역 확정 및 분석"),
            ),
          ),
        ],
      ),
    );
  }
}
