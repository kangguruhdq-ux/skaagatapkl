import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberSession = true;
  String _selectedRole = 'siswa';

  String _inputLabel = 'NISN Siswa';
  String _inputHelper = 'Contoh NISN: 0068492011';
  IconData _identifierIcon = Icons.badge_outlined;

  void _setRole(String role, String label, String helper, IconData icon) {
    setState(() {
      _selectedRole = role;
      _inputLabel = label;
      _inputHelper = helper;
      _identifierIcon = icon;
    });
  }

  void _loadDemo(String id, String pass, String role, String label,
      String helper, IconData icon) {
    setState(() {
      _identifierController.text = id;
      _passwordController.text = pass;
      _selectedRole = role;
      _inputLabel = label;
      _inputHelper = helper;
      _identifierIcon = icon;
    });
  }

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      username: _identifierController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Gagal masuk ke sistem.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // School Emblem & Branding
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer
                                    .withOpacity(0.12),
                              ),
                            ),
                            Container(
                              width: 84,
                              height: 84,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceLowest,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Logo_SMKN3Yk.JPG.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.school,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                 decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   color: AppColors.surfaceLowest,
                                 ),
                                child: const Icon(
                                  Icons.verified,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SMKN 3 YOGYAKARTA',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKAGATA PKL INTELLIGENCE',
                          style: AppTypography.headlineXlMobile.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'SISTEM OTENTIKASI TERPADU v2.4',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role Selector Switcher (4 Roles)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PILIH PERAN PENGGUNA',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aktif',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleButton(
                                title: 'Siswa PKL',
                                icon: Icons.school_outlined,
                                isSelected: _selectedRole == 'siswa',
                                onTap: () => _setRole(
                                  'siswa',
                                  'NISN Siswa',
                                  'Contoh NISN: 0068492011',
                                  Icons.badge_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildRoleButton(
                                title: 'Guru Pembimbing',
                                icon: Icons.co_present_outlined,
                                isSelected: _selectedRole == 'guru',
                                onTap: () => _setRole(
                                  'guru',
                                  'NIP / NUPTK Guru',
                                  'Contoh NIP: 19840217 200801 1 004',
                                  Icons.badge_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleButton(
                                title: 'Admin PKL / Hubin',
                                icon: Icons.admin_panel_settings_outlined,
                                isSelected: _selectedRole == 'admin',
                                onTap: () => _setRole(
                                  'admin',
                                  'Username Admin Hubin',
                                  'Akses Terbatas Administrator',
                                  Icons.security_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main Credentials Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Identifier Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _inputLabel,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune,
                                    size: 12, color: AppColors.secondary),
                                const SizedBox(width: 2),
                                Text(
                                  'Dapodik Sinkron',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _identifierController,
                          style: AppTypography.bodyMd,
                          decoration: InputDecoration(
                            prefixIcon: Icon(_identifierIcon,
                                color: AppColors.onSurfaceVariant, size: 20),
                            hintText: 'Masukkan pengenal / ID',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_inputHelper, style: AppTypography.bodySm),

                        const SizedBox(height: 16),

                        // Password Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Kata Sandi Platform',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'PIN / Sandi Akun',
                              style: AppTypography.labelSm
                                  .copyWith(color: AppColors.outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTypography.bodyMd,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.key_outlined,
                                color: AppColors.onSurfaceVariant, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            hintText: 'Masukkan kata sandi',
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Session remember & forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberSession,
                                      activeColor: AppColors.primary,
                                      onChanged: (v) => setState(
                                          () => _rememberSession = v ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Ingat Sesi Perangkat',
                                      style: AppTypography.bodySm.copyWith(
                                          color: AppColors.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Hubungi administrator untuk reset kata sandi.')));
                              },
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero),
                              child: Text(
                                'Lupa Sandi?',
                                style: AppTypography.labelMd
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Geofence Bound Telemetry Chip
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cell_tower,
                                  color: AppColors.secondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Perangkat terverifikasi untuk ',
                                    style: AppTypography.bodySm,
                                    children: [
                                      TextSpan(
                                        text:
                                            'Telemetry Geofence Presensi Mandiri',
                                        style: AppTypography.bodySm.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Login Submit Button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Masuk ke Sistem PKL',
                                      style: AppTypography.labelLg.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FIDO2 Biometric Quick Auth
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      onTap: () {
                        _handleLogin();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondaryContainer
                                    .withOpacity(0.3),
                              ),
                              child: const Icon(Icons.fingerprint,
                                  color: AppColors.secondary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verifikasi Biometrik Siswa Terdaftar',
                                    style: AppTypography.labelMd
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Scan Sidik Jari / Face ID Terdaftar',
                                    style: AppTypography.bodySm,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Demo Accounts Sandbox
                  Row(
                    children: [
                      const Icon(Icons.swap_calls,
                          color: AppColors.secondary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'AKUN UJI COBA DEMO SANDBOX',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDemoChip(
                          title: 'Demo Siswa (Fikri - TKJ)',
                          dotColor: AppColors.primary,
                          onTap: () => _loadDemo(
                            '0068492011',
                            'Skagata123#',
                            'siswa',
                            'NISN Siswa',
                            'Contoh NISN: 0068492011',
                            Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDemoChip(
                          title: 'Demo Guru (Dra. Wahyuningsih)',
                          dotColor: AppColors.secondary,
                          onTap: () => _loadDemo(
                            '19840217 200801 1 004',
                            'GuruAktif2025!',
                            'guru',
                            'NIP / NUPTK Guru',
                            'Contoh NIP: 19840217 200801 1 004',
                            Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDemoChip(
                          title: 'Demo Admin (Hubin SMKN 3)',
                          dotColor: AppColors.primary,
                          onTap: () => _loadDemo(
                            'admin_hubin',
                            'AdminHubin2024!',
                            'admin',
                            'Username Admin Hubin',
                            'Akses Terbatas Administrator',
                            Icons.security_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Registration Link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum memiliki akun PKL? ',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: 'Registrasi Akun Siswa',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.labelMd.copyWith(
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoChip({
    required String title,
    required Color dotColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.labelMd.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
