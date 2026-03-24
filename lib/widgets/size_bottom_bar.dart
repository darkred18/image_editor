import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue,
        // borderRadius: const BorderRadius.only(
        //   topLeft: Radius.circular(20),
        //   topRight: Radius.circular(20),
        // ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(icon: Icons.home, index: 0),
          _buildItem(icon: Icons.photo, index: 1),
          _buildItem(icon: Icons.person, index: 2),
        ],
      ),
    );
  }

  Widget _buildItem({required IconData icon, required int index}) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.amber,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white,
          size: isSelected ? 32 : 26,
        ),
      ),
    );
  }
}
