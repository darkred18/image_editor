import 'package:flutter/material.dart';

class RoiControlPanel extends StatelessWidget {
  final double roiSize;
  final bool isMinimumCount;

  final ValueChanged<double> onSizeChanged;
  final ValueChanged<bool> onMinimumToggle;
  final VoidCallback onAnalyze;

  const RoiControlPanel({
    super.key,
    required this.roiSize,
    required this.isMinimumCount,
    required this.onSizeChanged,
    required this.onMinimumToggle,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 200, // ❌ 고정 높이는 기기마다 Overflow의 원인이 됩니다.
      constraints: const BoxConstraints(maxHeight: 250), // ✅ 최대 높이만 제한
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // 상단 여백 조절
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        // 하이테크한 느낌을 위해 약간의 그림자 추가
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: SingleChildScrollView(
        // ✅ 내용이 길어질 경우를 대비해 스크롤 허용
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ 자식 크기만큼만 높이 차지
          children: [
            // 드래그 핸들 (패널 느낌 강조)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ROI 크기 조절 섹션
            Row(
              children: [
                const SizedBox(
                  width: 70, // 텍스트 영역 너비 고정으로 슬라이더 정렬
                  child: Text(
                    "ROI 크기",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.amber, // 하이테크한 노란색 포인트
                      thumbColor: Colors.amber,
                      overlayColor: Colors.amber.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: roiSize,
                      min: 20,
                      max: 120,
                      divisions: 10, // 조금 더 세밀하게 조정
                      onChanged: onSizeChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    "${roiSize.toInt()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            //--------------------------------
            // 최소 색 조합 모드
            //--------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("최소 혼합 모드", style: TextStyle(color: Colors.white70)),
                Switch(value: isMinimumCount, onChanged: onMinimumToggle),
              ],
            ),

            const SizedBox(height: 20),

            //--------------------------------
            // 분석 버튼
            //--------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAnalyze,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("ROI 분석 다시 실행"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
