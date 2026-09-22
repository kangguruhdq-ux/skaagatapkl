import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class AuthSwapScreen extends StatefulWidget {
  final bool initialRegister;

  const AuthSwapScreen({super.key, this.initialRegister = false});

  @override
  State<AuthSwapScreen> createState() => _AuthSwapScreenState();
}

class _AuthSwapScreenState extends State<AuthSwapScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLoginMode;
  final _identifierController = TextEditingController(text: '0068492011');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _rememberSession = true;
  String _selectedRole = 'siswa';

  String _inputLabel = 'NISN Siswa';
  String _inputHelper = 'Contoh NISN: 0068492011';
  IconData _identifierIcon = Icons.badge_outlined;

  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _isLoginMode = !widget.initialRegister;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setRole(String role, String label, String helper, IconData icon) {
    setState(() {
      _selectedRole = role;
      _inputLabel = label;
      _inputHelper = helper;
      _identifierIcon = icon;
      // Auto-populate demo ID corresponding to role if current text is empty or a known demo ID
      final current = _identifierController.text.trim();
      if (current.isEmpty ||
          current == '0068492011' ||
          current == '198402172009032004' ||
          current == 'admin_hubin') {
        if (role == 'siswa') _identifierController.text = '0068492011';
        if (role == 'guru') _identifierController.text = '198402172009032004';
        if (role == 'admin') _identifierController.text = 'admin_hubin';
        _passwordController.text = 'password123';
      }
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
    setState(() => _isAuthenticating = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Simulate high-tech biometric/credential verification delay
    await Future.delayed(const Duration(milliseconds: 600));

    final success = await auth.login(
      username: _identifierController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      final name = auth.user?.fullName ?? 'Pengguna';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Selamat datang kembali, $name! Sesi telemetri aktif.')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(auth.errorMessage ??
                      'Gagal masuk. Periksa pengenal dan kata sandi Anda.')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // School Emblem & Branding
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceLowest,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Image.asset(
                                'assets/images/Logo_SMKN3Yk.JPG.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'SMKN 3 YOGYAKARTA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'SKAGATA PKL INTELLIGENCE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: const Text(
                                'SISTEM TELEMETRI & OTENTIKASI v2.4',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Segmented Swap Tab (Masuk vs Daftar)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (!_isLoginMode) {
                                    setState(() => _isLoginMode = true);
                                  }
                                },
                                borderRadius: BorderRadius.circular(9),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _isLoginMode
                                        ? AppColors.surfaceLowest
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: _isLoginMode
                                        ? [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 4)
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login,
                                          size: 16,
                                          color: _isLoginMode
                                              ? AppColors.primary
                                              : AppColors.onSurfaceVariant),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Masuk Akun',
                                        style: TextStyle(
                                          fontWeight: _isLoginMode
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 12,
                                          color: _isLoginMode
                                              ? AppColors.primary
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_isLoginMode) {
                                    setState(() => _isLoginMode = false);
                                  }
                                },
                                borderRadius: BorderRadius.circular(9),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: !_isLoginMode
                                        ? AppColors.surfaceLowest
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: !_isLoginMode
                                        ? [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 4)
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_alt_1,
                                          size: 16,
                                          color: !_isLoginMode
                                              ? AppColors.primary
                                              : AppColors.onSurfaceVariant),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Daftar Baru',
                                        style: TextStyle(
                                          fontWeight: !_isLoginMode
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 12,
                                          color: !_isLoginMode
                                              ? AppColors.primary
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Animated Swap-Card Switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: _isLoginMode
                                    ? const Offset(-0.06, 0.0)
                                    : const Offset(0.06, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _isLoginMode
                            ? _buildLoginCard(context)
                            : _buildRegisterCard(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // High-Tech Cybernetic Loading Overlay
          if (_isAuthenticating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 30),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.secondary),
                              ),
                              SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'MEMVERIFIKASI KREDENSIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Validasi Token & Hardware Fingerprint SKAGATA...',
                          style:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Column(
      key: const ValueKey('login_card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector Grid
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildRoleTab(
                      'Siswa PKL',
                      Icons.school,
                      'siswa',
                      'NISN Siswa',
                      'Contoh NISN: 0068492011',
                      Icons.badge_outlined),
                  const SizedBox(width: 4),
                  _buildRoleTab(
                      'Guru Pembimbing',
                      Icons.person_pin,
                      'guru',
                      'NIP / NUPTK Guru',
                      'Contoh NIP: 198402172009032004',
                      Icons.account_box_outlined),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildRoleTab(
                      'Admin PKL / Hubin',
                      Icons.admin_panel_settings,
                      'admin',
                      'Username Administrator',
                      'Contoh: admin_hubin',
                      Icons.shield_outlined),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Main Credentials Form Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                    children: const [
                      Icon(Icons.tune, size: 12, color: AppColors.secondary),
                      SizedBox(width: 2),
                      Text(
                        'Dapodik Sinkron',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
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
              Text(_inputHelper,
                  style: AppTypography.bodySm.copyWith(fontSize: 10)),

              const SizedBox(height: 14),

              // Password Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Kata Sandi Platform',
                      style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                  Text(
                    'PIN / Sandi Akun',
                    style: TextStyle(color: AppColors.outline, fontSize: 10),
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
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                            onChanged: (v) =>
                                setState(() => _rememberSession = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Ingat Sesi Perangkat',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Hubungi administrator untuk reset kata sandi.')));
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Lupa Sandi?',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Submit Button
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Masuk ke Sistem PKL',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // FIDO2 Quick Trigger
        InkWell(
          onTap: _handleLogin,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  ),
                  child: const Icon(Icons.fingerprint,
                      color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Verifikasi Biometrik Siswa Terdaftar',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Scan Sidik Jari / Face ID Terdaftar',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.outline),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Demo Sandbox Chips
        Row(
          children: const [
            Icon(Icons.swap_calls, color: AppColors.secondary, size: 14),
            SizedBox(width: 4),
            Text('AKUN UJI COBA DEMO SANDBOX',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildDemoChip('Siswa Fikri', Colors.blue, () {
              _loadDemo('0068492011', 'password123', 'siswa', 'NISN Siswa',
                  'Muhammad Fikri Pratama (XII TKJ 1)', Icons.badge_outlined);
            }),
            _buildDemoChip('Guru Wahyu', Colors.teal, () {
              _loadDemo(
                  '198402172009032004',
                  'password123',
                  'guru',
                  'NIP Guru Pembimbing',
                  'Dra. Sri Wahyuningsih, M.Pd.',
                  Icons.account_box_outlined);
            }),
            _buildDemoChip('Admin Hubin', Colors.purple, () {
              _loadDemo(
                  'admin_hubin',
                  'password123',
                  'admin',
                  'Username Administrator',
                  'Admin Hubin SMKN 3 Yogyakarta',
                  Icons.shield_outlined);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterCard(BuildContext context) {
    return const KeyedSubtree(
      key: ValueKey('register_card'),
      child: SizedBox(
        height: 780,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          child: RegisterScreen(),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'guru':
        return const Color(0xFF0F766E);
      case 'mitra':
        return const Color(0xFFB45309);
      case 'admin':
        return const Color(0xFF7E22CE);
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  Widget _buildRoleTab(String title, IconData icon, String role, String label,
      String helper, IconData inputIcon) {
    final isSelected = _selectedRole == role;
    final roleColor = _getRoleColor(role);

    return Expanded(
      child: InkWell(
        onTap: () => _setRole(role, label, helper, inputIcon),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? roleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      isSelected ? Colors.white : AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
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

  Widget _buildDemoChip(String title, Color dotColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 5),
            Text(title,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
