import 'package:bullbearnews/models/news_model.dart';
import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  final Color textColor;
  final NewsModel? news;
  const AppBarTitle({super.key, required this.textColor, required this.news});

  @override
  Widget build(BuildContext context) {
    return Text(
      news?.title ?? '',
      style: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        height: 1.2,
        fontFamily: 'DMSerif',
        fontStyle: FontStyle.normal,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        decorationStyle: TextDecorationStyle.solid,
        decorationThickness: 1.0,
        wordSpacing: 2.0,
        textBaseline: TextBaseline.alphabetic,
        locale: const Locale('en', 'US'),
        backgroundColor: Colors.transparent,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
