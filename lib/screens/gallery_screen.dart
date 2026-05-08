import 'package:flutter/material.dart';
import 'package:image_editor/screens/detail_screen.dart';
import 'package:image_editor/screens/edit_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.images});
  final List<XFile> images;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('사진 선택', style: TextStyle(color: Colors.white70)),
        backgroundColor: Colors.amber.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: ReorderableGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          dragStartDelay: const Duration(milliseconds: 300), // 길게 눌러야 드래그
          children: [
            for (int index = 0; index < widget.images.length; index++)
              GestureDetector(
                key: ValueKey(widget.images[index]),
                onTap: () {
                  print('runtimeType :  ${widget.images[index].runtimeType}');
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      // ✅ 전환 시간을 줄임 (기본은 약 300~400ms)
                      transitionDuration: const Duration(milliseconds: 500),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 500,
                      ),
                      pageBuilder: (_, __, ___) => EditorScreen(
                        imagePaths: widget.images.map((e) => e.path).toList(),
                        initialIndex: index,
                      ),
                      // pageBuilder: (_, __, ___) => DetailScreen(
                      //   imagePaths: widget.images.map((e) => e.path).toList(),
                      //   initialIndex: index,
                      // ),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.98,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },

                child: Hero(
                  tag: widget.images[index],
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        direction,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        if (direction == HeroFlightDirection.pop) {
                          // ✅ 뒤로 갈 때는 Hero 애니메이션 생략하고 그냥 fade
                          return FadeTransition(
                            opacity: animation.drive(
                              Tween(begin: 0.1, end: 1.0),
                            ),
                            child: toHeroContext.widget,
                          );
                        }
                        return toHeroContext.widget;
                      },

                  child: Image.asset(
                    widget.images.map((e) => e.path).toList()[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = widget.images.removeAt(oldIndex);
              widget.images.insert(newIndex, item);
            });
          },
        ),
      ),
    );
  }
}
