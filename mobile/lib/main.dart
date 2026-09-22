import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/api_endpoints.dart';
import 'core/navigation/navigation_service.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_settings.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_swap_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/teacher/screens/teacher_dashboard_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/screens/main_navigation_screen.dart';
import 'features/attendance/providers/attendance_provider.dart';
import 'features/journal/providers/journal_provider.dart';
import 'features/skills/providers/skills_provider.dart';
import 'shared/widgets/mobile_preview_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load custom API host if user configured one
  final customHost = await LocalStorage.getCustomHost();
  if (customHost != null && customHost.isNotEmpty) {
    ApiEndpoints.setCustomHost(customHost);
  }

  // Load theme preference before runApp to avoid flickering
  await ThemeSettings.load();

  runApp(const SkagataPklApp());
}

class SkagataPklApp extends StatefulWidget {
  const SkagataPklApp({super.key});

  @override
  State<SkagataPklApp> createState() => _SkagataPklAppState();
}

class _SkagataPklAppState extends State<SkagataPklApp> {
  @override
  void initState() {
    super.initState();
    ThemeSettings.mode.addListener(_themeChanged);
    ThemeSettings.load();
  }

  void _themeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThemeSettings.mode.removeListener(_themeChanged);
    super.dispose();
  }

  Widget _getHomeScreen(AuthProvider auth) {
    if (auth.isLoading && !auth.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
        ),
      );
    }
    if (!auth.isAuthenticated) {
      return const AuthSwapScreen();
    }

    final role = auth.user?.role.toLowerCase() ?? 'siswa';
    if (role == 'admin') {
      return const AdminDashboardScreen();
    } else if (role == 'guru') {
      return const TeacherDashboardScreen();
    } else {
      return const MainNavigationScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => SkillsProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeSettings.mode,
        builder: (context, currentMode, _) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
            title: 'SKAGATA PKL Intelligence',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            builder: (context, child) {
              return MobilePreviewFrame(child: child ?? const SizedBox.shrink());
            },
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('${auth.isAuthenticated}_${auth.user?.role}'),
                    child: _getHomeScreen(auth),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
