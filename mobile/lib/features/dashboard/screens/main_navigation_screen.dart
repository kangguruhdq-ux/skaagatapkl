import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../journal/providers/journal_provider.dart';
import '../../skills/screens/skills_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../notifications/screens/notifications_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigateTab: _onTabTapped),
      const AttendanceScreen(),
      const JournalScreen(),
      const SkillsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _currentIndex > _previousIndex;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        unreadNotifications: 3,
        onRefresh: () async {
          try {
            await Provider.of<JournalProvider>(context, listen: false)
                .fetchJournals();
          } catch (_) {}
        },
        onNotificationTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const NotificationsScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
            ),
          );
        },
        onProfileTap: () {
          _onTabTapped(4);
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetTween = Tween<Offset>(
            begin:
                isForward ? const Offset(0.08, 0.0) : const Offset(-0.08, 0.0),
            end: Offset.zero,
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetTween.animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
