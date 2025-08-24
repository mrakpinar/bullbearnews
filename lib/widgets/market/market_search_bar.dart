import 'dart:async';
import 'package:flutter/material.dart';

class MarketSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final bool isDarkMode;

  const MarketSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.isDarkMode,
  });

  @override
  State<MarketSearchBar> createState() => _MarketSearchBarState();
}

class _MarketSearchBarState extends State<MarketSearchBar> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
      child: TextField(
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
        cursorColor: widget.isDarkMode ? Colors.white : Colors.black,
        cursorHeight: 20,
        cursorWidth: 2,
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.start,
        decoration: InputDecoration(
          hintText: 'Search crypto...',
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          hintStyle: TextStyle(
            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        onChanged: (value) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 500), () {
            widget.onSearchChanged(value);
          });
        },
      ),
    );
  }
}
