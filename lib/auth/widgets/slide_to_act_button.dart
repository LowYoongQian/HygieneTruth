import 'package:flutter/material.dart';

class SlideToActButton extends StatefulWidget {
  final String text;
  final VoidCallback onSlideComplete;
  final IconData icon;

  const SlideToActButton({
    super.key,
    required this.text,
    required this.onSlideComplete,
    this.icon = Icons.keyboard_double_arrow_right,
  });

  @override
  State<SlideToActButton> createState() => _SlideToActButtonState();
}

class _SlideToActButtonState extends State<SlideToActButton> {
  double _dragPosition = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbWidth = 46.0;
        const padding = 6.0;
        final maxDrag = trackWidth - thumbWidth - (padding * 2);

        return Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Center Label Text with Fade Out as dragged
              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragPosition / maxDrag)).clamp(0.2, 1.0),
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Draggable Lime-Yellow Thumb Icon Button
              Positioned(
                left: padding + _dragPosition,
                top: padding,
                bottom: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_submitted) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_submitted) return;
                    if (_dragPosition > maxDrag * 0.7) {
                      // Complete slide action!
                      setState(() {
                        _dragPosition = maxDrag;
                        _submitted = true;
                      });
                      widget.onSlideComplete();
                    } else {
                      // Snap back to left
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  onTap: () {
                    // Tap fallback triggers slide completion
                    widget.onSlideComplete();
                  },
                  child: Container(
                    width: thumbWidth,
                    height: thumbWidth,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9F99D), // Lime yellow accent
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
