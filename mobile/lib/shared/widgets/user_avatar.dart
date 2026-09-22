import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/constants/api_endpoints.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? avatarUrl;
  final String? name;

  const UserAvatar({
    super.key,
    this.radius = 20,
    this.avatarUrl,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final isSelf = name == null && avatarUrl == null;
    final effectiveUrl = isSelf ? authUser?.avatarUrl : avatarUrl;
    final effectiveName = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : (authUser?.fullName ?? 'User');
    final resolved = ApiEndpoints.getImageUrl(effectiveUrl);

    // Generate up to 2 initials
    String initials = 'U';
    final parts = effectiveName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      initials = parts[0][0].toUpperCase();
    }

    Widget fallbackWidget() {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: resolved.isEmpty
            ? fallbackWidget()
            : Image.network(
                resolved,
                key: ValueKey(resolved),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallbackWidget(),
              ),
      ),
    );
  }
}
