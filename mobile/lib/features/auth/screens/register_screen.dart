import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nisnController = TextEditingController();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'siswa';
  String _selectedJurusan = 'Teknik Komputer dan Jaringan';
  bool _isVerifyingDapodik = false;
  String? _dapodikMessage;
  int _currentStep = 1;

  final List<String> _jurusanList = [
    'Teknik Komputer dan Jaringan',
    'Teknik Pemesinan',
    'Teknik Instalasi Tenaga Listrik',
    'Teknik Kendaraan Ringan',
    'Desain Komunikasi Visual',
    'Teknik Audio Video',
  ];

  Future<void> _verifyDapodik() async {
    final nisn = _nisnController.text.trim();
    if (nisn.isEmpty) return;

    setState(() {
      _isVerifyingDapodik = true;
      _dapodikMessage = null;
    });

    final res = await AuthService.verifyDapodik(nisn);

    if (!mounted) return;

    setState(() {
      _isVerifyingDapodik = false;
      if (res.success && res.data != null) {
        final data = res.data!;
        _nameController.text = data['full_name'] ?? _nameController.text;
        _selectedJurusan = data['department'] ?? _selectedJurusan;
        _classController.text = data['student_class'] ?? _classController.text;
        _dapodikMessage = res.message ??
            'Terverifikasi Otomatis di Pangkalan Data SMKN 3 Yogyakarta';
      } else {
        _dapodikMessage =
            res.error ?? 'NISN tidak terdaftar di Dapodik SMKN 3 Yogyakarta.';
      }
    });
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      username: _nisnController.text.trim(),
      fullName: _nameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      department: _selectedJurusan,
      studentClass: _classController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Gagal mendaftar.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo_SMKN3Yk.JPG.png',
              height: 32,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.school, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register',
                  style: AppTypography.headlineSm
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'SKAGATA PKL',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero block
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLowest,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Logo_SMKN3Yk.JPG.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.school,
                            size: 32, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'TAHUN AJARAN 2024/2025',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registrasi Akun PKL',
                    style: AppTypography.headlineXlMobile
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'SMKN 3 Yogyakarta — Portal Terintegrasi Telemetri',
                    style: AppTypography.bodySm,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Multi-step Stepper Ribbon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildStepItem(
                      stepNumber: 1,
                      label: 'Data Induk',
                      isActive: _currentStep == 1,
                      isCompleted: _currentStep > 1),
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: _currentStep > 1
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  _buildStepItem(
                      stepNumber: 2,
                      label: 'Kredensial',
                      isActive: _currentStep == 2,
                      isCompleted: _currentStep > 2),
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: _currentStep > 2
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  _buildStepItem(
                      stepNumber: 3,
                      label: 'Verif GPS',
                      isActive: _currentStep == 3,
                      isCompleted: false,
                      icon: Icons.my_location),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Role selection cards
            Text(
              'DAFTAR SEBAGAI PERAN',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoleCard(
              role: 'siswa',
              title: 'Siswa Kelas XII PKL',
              subtitle: 'Sinkronisasi NISN & penugasan industri DUDI',
              icon: Icons.school_outlined,
              isSelected: _selectedRole == 'siswa',
            ),
            const SizedBox(height: 8),
            _buildRoleCard(
              role: 'guru',
              title: 'Guru Pembimbing Sekolah',
              subtitle: 'Monitoring logbook & validasi mingguan',
              icon: Icons.supervisor_account_outlined,
              isSelected: _selectedRole == 'guru',
            ),
            const SizedBox(height: 8),
            _buildRoleCard(
              role: 'mentor',
              title: 'Mentor Industri DUDI',
              subtitle: 'Supervisor lapangan, evaluasi presensi & task',
              icon: Icons.precision_manufacturing_outlined,
              isSelected: _selectedRole == 'mentor',
            ),

            const SizedBox(height: 20),

            // Form inputs card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kelengkapan Data Pokok',
                          style: AppTypography.headlineSm
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // NISN Field with Live Dapodik Lookup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('NISN Siswa (10 Digit)',
                              style: AppTypography.labelMd)),
                      Text('Sesuai Kartu Pelajar', style: AppTypography.bodySm),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nisnController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          style: AppTypography.bodyMd,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.pin, size: 20),
                            hintText: '0061234890',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isVerifyingDapodik ? null : _verifyDapodik,
                        icon: _isVerifyingDapodik
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.verified, size: 16),
                        label: const Text('Dapodik'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                          minimumSize: const Size(90, 48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_dapodikMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync,
                              color: AppColors.secondary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _dapodikMessage!,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Full Name
                  Text('Nama Lengkap Siswa', style: AppTypography.labelMd),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: AppTypography.bodyMd,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      hintText: 'Masukkan nama sesuai rapor',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Jurusan Dropdown
                  Text('Konsentrasi Keahlian (Jurusan)',
                      style: AppTypography.labelMd),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedJurusan,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: _jurusanList.map((j) {
                      return DropdownMenuItem(
                        value: j,
                        child: Text(
                          j,
                          style: AppTypography.bodyMd,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedJurusan = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Class field
                  Text('Kelas', style: AppTypography.labelMd),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _classController,
                    style: AppTypography.bodyMd,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.class_outlined, size: 20),
                      hintText: 'XII TKJ 1',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Password
                  Text('Kata Sandi', style: AppTypography.labelMd),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: AppTypography.bodyMd,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                      hintText: 'Minimal 8 karakter',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Confirm Password
                  Text('Konfirmasi Kata Sandi', style: AppTypography.labelMd),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: AppTypography.bodyMd,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                      hintText: 'Ulangi kata sandi',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Selesaikan Pendaftaran PKL',
                            style: AppTypography.labelLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    IconData? icon,
  }) {
    Color bg =
        isCompleted || isActive ? AppColors.primary : const Color(0xFFE2E8F0);
    Color fg =
        isCompleted || isActive ? Colors.white : AppColors.onSurfaceVariant;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 16, color: fg)
              : Text('$stepNumber',
                  style: AppTypography.labelMd
                      .copyWith(color: fg, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withOpacity(0.15)
                    : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.labelLg
                          .copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: AppTypography.bodySm,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
