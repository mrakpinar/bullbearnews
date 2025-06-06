import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // New method to get appropriate colors based on theme
  Color get backgroundColor {
    return _themeMode == ThemeMode.dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
  }

  Color get primaryColor {
    return _themeMode == ThemeMode.dark ? AppColors.primary : AppColors.primary;
  }
}
