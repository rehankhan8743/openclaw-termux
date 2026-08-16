import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
import '../constants.dart';

enum AppThemeMode { system, light, dark }

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  AppThemeMode _themeMode = AppThemeMode.system;
  Color _accentColor = AppConstants.accentColors[0];
  double _terminalFontSize = AppConstants.terminalFontSizeDefault;
  bool _useAmoledBlack = false;

  AppThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  double get terminalFontSize => _terminalFontSize;
  bool get useAmoledBlack => _useAmoledBlack;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    if (_themeMode == AppThemeMode.dark) return true;
    if (_themeMode == AppThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = AppThemeMode.values[prefs.getInt('theme_mode') ?? 0];
    final colorIndex = prefs.getInt('accent_color_index') ?? 0;
    _accentColor = AppConstants.accentColors[colorIndex.clamp(0, AppConstants.accentColors.length - 1)];
    _terminalFontSize = prefs.getDouble('terminal_font_size') ?? AppConstants.terminalFontSizeDefault;
    _useAmoledBlack = prefs.getBool('use_amoled_black') ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    final index = AppConstants.accentColors.indexOf(color);
    if (index >= 0) await prefs.setInt('accent_color_index', index);
    notifyListeners();
  }

  Future<void> setTerminalFontSize(double size) async {
    _terminalFontSize = size.clamp(AppConstants.terminalFontSizeMin, AppConstants.terminalFontSizeMax);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('terminal_font_size', _terminalFontSize);
    notifyListeners();
  }

  Future<void> setUseAmoledBlack(bool value) async {
    _useAmoledBlack = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_amoled_black', value);
    notifyListeners();
  }

  ThemeData buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: _accentColor,
        onPrimary: Colors.white,
        secondary: _accentColor,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: Colors.black,
        onSurfaceVariant: AppColors.mutedText,
        error: AppColors.statusRed,
        onError: Colors.white,
        outline: AppColors.lightBorder,
      ),
      textTheme: textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.lightBg,
        foregroundColor: Colors.black,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.lightSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBg,
        selectedItemColor: _accentColor,
        unselectedItemColor: AppColors.mutedText,
      ),
    );
  }

  ThemeData buildDarkTheme() {
    final bg = _useAmoledBlack ? Colors.black : AppColors.darkBg;
    final surface = _useAmoledBlack ? const Color(0xFF0A0A0A) : AppColors.darkSurface;
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: _accentColor,
        onPrimary: Colors.white,
        secondary: _accentColor,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: Colors.white,
        onSurfaceVariant: AppColors.mutedText,
        error: AppColors.statusRed,
        onError: Colors.white,
        outline: AppColors.darkBorder,
      ),
      textTheme: textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: surface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: _accentColor,
        unselectedItemColor: AppColors.mutedText,
      ),
    );
  }
}