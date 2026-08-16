import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/setup_provider.dart';
import 'providers/gateway_provider.dart';
import 'providers/node_provider.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';

/// Centralized color palette for the entire app.
class AppColors {
  AppColors._();

  // Brand accent
  static const Color accent = Color(0xFFDC2626);

  // Dark mode
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceAlt = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);

  // Light mode
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF9F9F9);
  static const Color lightBorder = Color(0xFFE5E5E5);

  // Status
  static const Color statusGreen = Color(0xFF22C55E);
  static const Color statusAmber = Color(0xFFF59E0B);
  static const Color statusRed = Color(0xFFEF4444);
  static const Color statusGrey = Color(0xFF6B7280);

  // Text
  static const Color mutedText = Color(0xFF6B7280);
}

class OpenClawApp extends StatelessWidget {
  const OpenClawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeService()..load(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SetupProvider()),
              ChangeNotifierProvider(create: (_) => GatewayProvider()),
              ChangeNotifierProxyProvider<GatewayProvider, NodeProvider>(
                create: (_) => NodeProvider(),
                update: (_, gatewayProvider, nodeProvider) {
                  nodeProvider!.onGatewayStateChanged(gatewayProvider.state);
                  return nodeProvider;
                },
              ),
            ],
            child: MaterialApp(
              title: 'OpenClaw',
              debugShowCheckedModeBanner: false,
              theme: themeService.buildLightTheme(),
              darkTheme: themeService.buildDarkTheme(),
              themeMode: themeService.flutterThemeMode,
              home: const _AppInitializer(),
            ),
          );
        },
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await NotificationService.init();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}