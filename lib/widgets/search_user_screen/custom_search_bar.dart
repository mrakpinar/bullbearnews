import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDark;
  final VoidCallback? onClear;
  final Animation<double>? animation;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isDark,
    this.onClear,
    this.animation,
    this.textInputAction = TextInputAction.search,
    this.onSubmitted,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    Widget searchBar = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF393E46).withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSerif',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46).withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                size: 24,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onClear ??
                            () {
                              controller.clear();
                            },
                        borderRadius: BorderRadius.circular(20),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );

    // Eğer animasyon verilmişse animasyonlu döndür
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - animation!.value)),
            child: Opacity(
              opacity: animation!.value,
              child: searchBar,
            ),
          );
        },
      );
    }

    return searchBar;
  }
}
