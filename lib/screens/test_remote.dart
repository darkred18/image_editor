import 'package:flutter/material.dart';
import 'package:image_editor/screens/volumn_slider.dart';

class RemotePage extends StatelessWidget {
  const RemotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A145A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTopStatus(),
              const SizedBox(height: 20),
              Expanded(child: _buildTouchPad()),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: VolumeSlider(
                  value: 0.4,
                  onChanged: (v) {
                    print("volume = $v");
                  },
                ),
              ),
              // _buildControlButtons(),
              // const SizedBox(height: 20),
              // _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        border: BoxBorder.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, color: Colors.greenAccent, size: 26),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Remote",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              Text(
                "Connected",
                style: TextStyle(fontSize: 14, color: Colors.greenAccent),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.menu, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTouchPad() {
    return Container(
      decoration: BoxDecoration(
        // border: BoxBorder.all(color: Colors.white24),
        gradient: const LinearGradient(
          colors: [Color(0xFF612F90), Color(0xFF3A2D8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // 중앙 방향 아이콘
          Center(
            child: Icon(
              Icons.control_camera,
              size: 60,
              color: Colors.white.withOpacity(0.4),
            ),
          ),

          // 텍스트
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Swipe to control",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _CircleButton(icon: Icons.skip_previous_rounded),
        _CircleButton(icon: Icons.replay_10),
        _CircleButton(icon: Icons.play_arrow_rounded, isMain: true),
        _CircleButton(icon: Icons.forward_10),
        _CircleButton(icon: Icons.skip_next_rounded),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        VolumeSlider(
          value: 0.4,
          onChanged: (v) {
            print("volume = $v");
          },
        ),
        _BottomButton(icon: Icons.volume_up, label: "음량"),
        _BottomButton(icon: Icons.open_in_full, label: "화면"),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool isMain;

  const _CircleButton({required this.icon, this.isMain = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isMain ? const Color(0xFF6C4CF6) : Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: isMain ? 36 : 28),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
