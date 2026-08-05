import 'package:flutter/material.dart';

class BookmarkButton extends StatelessWidget {
  final bool bookmarked;
  final VoidCallback onPressed;
  final double size;

  const BookmarkButton({
    super.key,
    required this.bookmarked,
    required this.onPressed,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          bookmarked ? Icons.bookmark : Icons.bookmark_outline,
          key: ValueKey(bookmarked),
          size: size,
        ),
      ),
    );
  }
}
