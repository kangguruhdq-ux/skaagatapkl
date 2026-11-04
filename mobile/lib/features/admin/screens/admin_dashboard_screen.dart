import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../submission/models/submission_model.dart';
import '../../submission/services/submission_service.dart';
import '../../reports/models/ticket_model.dart';
import '../../reports/services/ticket_service.dart';
import '../../../shared/widgets/animated_refresh_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<UserModel> _users = [];
  List<dynamic> _journals = [];
  List<dynamic> _auditLogs = [];
  List<dynamic> _companies = [];
  List<PklSubmissionModel> _submissions = [];
  List<Map<String, dynamic>> _companyProposals = [];
  List<ReportTicketModel> _tickets = [];

  String _selectedRoleFilter = 'semua';
  final _searchController = TextEditingController();
  final _auditSearchController = TextEditingController();
  String _auditRoleFilter = '';
  final _journalSearchCtrl = TextEditingController();
  String _selectedJournalStatus = 'semua';
  final _ticketSearchCtrl = TextEditingController();
  String _selectedTicketStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _auditSearchController.dispose();
    _journalSearchCtrl.dispose();
    _ticketSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchStats(),
        _fetchUsers(),
        _fetchJournals(),
        _fetchAuditLogs(),
        _fetchCompanies(),
        _fetchSubmissions(),
        _fetchCompanyProposals(),
        _fetchTickets(),
      ]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await TicketService.getTickets(
        status: _selectedTicketStatus != 'all' ? _selectedTicketStatus : null,
        query: _ticketSearchCtrl.text.trim().isNotEmpty
            ? _ticketSearchCtrl.text.trim()
            : null,
      );
      if (mounted) {
        setState(() {
          _tickets = tickets;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/stats');
      if (res.success && res.data != null) {
        _stats = res.data;
      }
    } catch (_) {}
  }

  Future<void> _fetchUsers([String? query, String? role]) async {
    try {
      String url = '${ApiEndpoints.baseUrl}/users?limit=100';
      if (role != null && role != 'semua') {
        url += '&role=$role';
      }
      if (query != null && query.isNotEmpty) {
        url += '&q=$query';
      }
      final res = await ApiClient.get(url);
      if (res.success && res.data != null) {
        List items = [];
        if (res.data is List) {
          items = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          items = res.data['items'] as List;
        }
        _users = items.map((u) => UserModel.fromJson(u)).toList();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _fetchJournals() async {
    try {
      final res = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/journals');
      if (res.success && res.data != null) {
        if (res.data is List) {
          _journals = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          _journals = res.data['items'] as List;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _fetchAuditLogs([String? q, String? role]) async {
    try {
      String url = ApiEndpoints.auditLogs;
      final params = <String>[];
      if (q != null && q.isNotEmpty) params.add('q=$q');
      if (role != null && role.isNotEmpty) params.add('role=$role');
      params.add('limit=50');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final res = await ApiClient.get(url);
      if (res.success && res.data != null) {
        if (res.data is List) {
          _auditLogs = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          _auditLogs = res.data['items'] as List;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _fetchCompanies() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.adminCompanies);
      if (res.success && res.data != null) {
        if (res.data is List) {
          _companies = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          _companies = res.data['items'] as List;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _fetchSubmissions() async {
    try {
      final subs = await SubmissionService.getSubmissions();
      _submissions = subs;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _fetchCompanyProposals() async {
    try {
      final props = await SubmissionService.getCompanyProposals();
      _companyProposals = props;
      if (mounted) setState(() {});
    } catch (_) {}
  }


  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password123');
    final classCtrl = TextEditingController(text: 'XII TKJ 1');
    final deptCtrl =
        TextEditingController(text: 'Teknik Komputer dan Jaringan');
    final phoneCtrl = TextEditingController();
    String roleVal = 'siswa';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.person_add, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Tambah Pengguna Baru', style: AppTypography.headlineSm),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: roleVal,
                      decoration: const InputDecoration(
                          labelText: 'Peran / Role Pengguna',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'siswa', child: Text('Siswa PKL')),
                        DropdownMenuItem(
                            value: 'guru', child: Text('Guru Pembimbing')),
                        DropdownMenuItem(
                            value: 'admin', child: Text('Admin PKL')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => roleVal = v ?? 'siswa'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: roleVal == 'siswa'
                            ? 'NISN (10 Digit)'
                            : roleVal == 'guru'
                                ? 'NIP Guru'
                                : 'ID / Username',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Kata Sandi Awal',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nomor HP / WhatsApp',
                          border: OutlineInputBorder()),
                    ),
                    if (roleVal == 'siswa') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: classCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Kelas (Rombel)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: deptCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Jurusan / Kompetensi',
                            border: OutlineInputBorder()),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (usernameCtrl.text.isEmpty ||
                        nameCtrl.text.isEmpty ||
                        passCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Harap lengkapi semua data wajib.'),
                            backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    final res = await ApiClient.post(
                      '${ApiEndpoints.baseUrl}/users',
                      body: {
                        'username': usernameCtrl.text.trim(),
                        'full_name': nameCtrl.text.trim(),
                        'password': passCtrl.text.trim(),
                        'role': roleVal,
                        'phone': phoneCtrl.text.trim(),
                        'student_class': classCtrl.text.trim(),
                        'department': deptCtrl.text.trim(),
                      },
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      if (res.success) {
                        if (res.data != null) {
                          final newUser = UserModel.fromJson(res.data);
                          setState(() {
                            _users.insert(0, newUser);
                          });
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Pengguna ${nameCtrl.text} berhasil didaftarkan!'),
                              backgroundColor: AppColors.success),
                        );
                        _fetchUsers(
                            _searchController.text, _selectedRoleFilter);
                        _fetchStats();
                        _fetchAuditLogs();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  res.error ?? 'Gagal menambahkan pengguna.'),
                              backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan Pengguna'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final classCtrl = TextEditingController(text: user.studentClass ?? '');
    final deptCtrl = TextEditingController(text: user.department ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:
              Text('Edit: ${user.fullName}', style: AppTypography.headlineSm),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nomor HP', border: OutlineInputBorder()),
                ),
                if (user.role == 'siswa') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: classCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Kelas', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Jurusan', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final res = await ApiClient.put(
                  '${ApiEndpoints.baseUrl}/users/${user.id}',
                  body: {
                    'full_name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'student_class': classCtrl.text.trim(),
                    'department': deptCtrl.text.trim(),
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  if (res.success) {
                    if (res.data != null) {
                      final updatedUser = UserModel.fromJson(res.data);
                      setState(() {
                        final idx = _users.indexWhere((u) => u.id == user.id);
                        if (idx != -1) {
                          _users[idx] = updatedUser;
                        }
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Data pengguna berhasil diperbarui!'),
                          backgroundColor: AppColors.success),
                    );
                    _fetchUsers(_searchController.text, _selectedRoleFilter);
                    _fetchAuditLogs();
                  }
                }
              },
              child: const Text('Perbarui'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hapus Pengguna', style: AppTypography.headlineSm),
          content: Text(
              'Apakah Anda yakin ingin menghapus "${user.fullName}" (${user.username}) dari sistem?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final res = await ApiClient.delete(
                    '${ApiEndpoints.baseUrl}/users/${user.id}');
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  if (res.success) {
                    setState(() {
                      _users.removeWhere((u) => u.id == user.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Pengguna ${user.fullName} telah dihapus.'),
                          backgroundColor: AppColors.primary),
                    );
                    _fetchStats();
                    _fetchAuditLogs();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(res.error ?? 'Gagal menghapus pengguna.'),
                          backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  // --- COMPANY CRUD ---
  void _showAddCompanyDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final sectorCtrl = TextEditingController(text: 'Telekomunikasi & Jaringan');
    final cpCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final quotaCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.add_business, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Tambah Mitra DUDI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nama Perusahaan',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: sectorCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Bidang Industri / Sektor',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: addrCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: cpCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Contact Person / HRD',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                        labelText: 'No. Telepon Perusahaan',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: quotaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Kuota Siswa PKL',
                        border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Nama perusahaan wajib diisi.')));
                  return;
                }
                final res = await ApiClient.post(
                  ApiEndpoints.adminCompanies,
                  body: {
                    'name': nameCtrl.text.trim(),
                    'division': sectorCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'mentor_name': cpCtrl.text.trim(),
                    'mentor_phone': phoneCtrl.text.trim(),
                    'latitude': -7.7854,
                    'longitude': 110.3722,
                    'geofence_radius': 100.0,
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  if (res.success) {
                    if (res.data != null && res.data is Map) {
                      setState(() {
                        _companies.insert(0, res.data);
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Mitra industri berhasil ditambahkan!'),
                        backgroundColor: AppColors.success));
                    _fetchCompanies();
                    _fetchStats();
                    _fetchAuditLogs();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.error ?? 'Gagal menambahkan mitra industri.'),
                        backgroundColor: AppColors.error));
                  }
                }
              },
              child: const Text('Simpan Mitra'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCompanyDialog(dynamic company) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Mitra Industri'),
          content: Text(
              'Hapus perusahaan "${company['name']}" dari daftar mitra aktif?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final res = await ApiClient.delete(
                    '${ApiEndpoints.adminCompanies}/${company['id']}');
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  if (res.success) {
                    setState(() {
                      _companies.removeWhere((c) => c['id'] == company['id']);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Mitra berhasil dihapus.')));
                    _fetchStats();
                    _fetchAuditLogs();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.error ?? 'Gagal menghapus mitra.'),
                        backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCompanyDialog(dynamic company) {
    final nameCtrl = TextEditingController(text: company['name'] ?? '');
    final addrCtrl = TextEditingController(text: company['address'] ?? '');
    final sectorCtrl = TextEditingController(
        text: company['industry_sector'] ?? company['division'] ?? '');
    final cpCtrl = TextEditingController(
        text: company['contact_person'] ?? company['mentor_name'] ?? '');
    final phoneCtrl = TextEditingController(
        text: company['phone'] ?? company['mentor_phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.edit_note, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Edit Mitra DUDI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sectorCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Bidang Industri / Divisi',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Alamat Lengkap',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cpCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Mentor / PIC Perusahaan',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'No. Telepon Perusahaan',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Nama perusahaan wajib diisi.')));
                  return;
                }
                final res = await ApiClient.put(
                  '${ApiEndpoints.adminCompanies}/${company['id']}',
                  body: {
                    'name': nameCtrl.text.trim(),
                    'division': sectorCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'mentor_name': cpCtrl.text.trim(),
                    'mentor_phone': phoneCtrl.text.trim(),
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  if (res.success) {
                    if (res.data != null && res.data is Map) {
                      setState(() {
                        final idx = _companies.indexWhere((c) => c['id'] == company['id']);
                        if (idx != -1) {
                          _companies[idx] = res.data;
                        }
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data mitra berhasil diperbarui!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _fetchCompanies();
                    _fetchAuditLogs();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              res.error ?? 'Gagal memperbarui data mitra.'),
                          backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetailModal(UserModel u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.fullName,
                            style: AppTypography.headlineSm
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            u.role.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(Icons.badge_outlined, 'Username / ID', u.username),
              if (u.phone != null && u.phone!.isNotEmpty)
                _buildDetailRow(Icons.phone_outlined, 'No. Telepon', u.phone!),
              if (u.studentClass != null && u.studentClass!.isNotEmpty)
                _buildDetailRow(Icons.class_outlined, 'Kelas', u.studentClass!),
              if (u.department != null && u.department!.isNotEmpty)
                _buildDetailRow(
                    Icons.school_outlined, 'Jurusan', u.department!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditUserDialog(u);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Data'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteUserDialog(u);
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Hapus Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: Text(val,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- JOURNAL REVIEW & DELETIONS ---
  Future<void> _reviewJournalAction(int journalId, String action,
      [String? notes]) async {
    final res = await ApiClient.patch(
      '${ApiEndpoints.baseUrl}/admin/journals/$journalId/review?action=$action${notes != null ? "&notes=$notes" : ""}',
    );
    if (mounted) {
      if (res.success) {
        setState(() {
          for (var item in _journals) {
            if (item['id'] == journalId) {
              item['status'] = action == 'approve' ? 'approved' : 'revision_required';
              if (notes != null) item['revision_notes'] = notes;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve'
                ? 'Jurnal disetujui!'
                : 'Jurnal dikembalikan untuk revisi.'),
            backgroundColor:
                action == 'approve' ? AppColors.success : AppColors.error,
          ),
        );
        _fetchJournals();
        _fetchStats();
        _fetchAuditLogs();
      }
    }
  }

  Future<void> _deleteJournal(int journalId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jurnal Siswa'),
        content: Text('Apakah Anda yakin ingin menghapus entri jurnal #$journalId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiClient.delete('${ApiEndpoints.journals}/$journalId');
    if (mounted) {
      if (res.success) {
        setState(() {
          _journals.removeWhere((j) => j['id'] == journalId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jurnal siswa berhasil dihapus.'), backgroundColor: AppColors.primary),
        );
        _fetchStats();
        _fetchAuditLogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal menghapus jurnal.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteSingleAuditLog(int logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Log Audit'),
        content: Text('Hapus log audit #$logId dari jejak sistem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiClient.delete('${ApiEndpoints.baseUrl}/audit/logs/$logId');
    if (mounted) {
      if (res.success) {
        setState(() {
          _auditLogs.removeWhere((l) => l['id'] == logId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log audit berhasil dihapus.'), backgroundColor: AppColors.primary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal menghapus log audit.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _clearAllAuditLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bersihkan Semua Log Audit'),
        content: const Text('Apakah Anda yakin ingin menghapus seluruh jejak audit sistem? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Bersihkan Semua'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiClient.delete('${ApiEndpoints.baseUrl}/audit/logs');
    if (mounted) {
      if (res.success) {
        setState(() {
          _auditLogs.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seluruh riwayat audit telah dibersihkan.'), backgroundColor: AppColors.primary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal membersihkan log audit.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // --- SUBMISSION & APPROVAL PKL ACTIONS (ADMIN) ---
  Future<void> _reviewSubmission(PklSubmissionModel sub, String status,
      [String? notes]) async {
    final idx = _submissions.indexWhere((s) => s.id == sub.id);
    if (idx != -1) {
      setState(() {
        _submissions[idx] = PklSubmissionModel(
          id: sub.id,
          studentId: sub.studentId,
          companyId: sub.companyId,
          companyName: sub.companyName,
          address: sub.address,
          status: status,
          proposalLetterUrl: sub.proposalLetterUrl,
          changeReason: sub.changeReason,
          targetCompanyId: sub.targetCompanyId,
          supervisorNotes: notes ?? sub.supervisorNotes,
          notes: notes ?? sub.notes,
          companyLatitude: sub.companyLatitude,
          companyLongitude: sub.companyLongitude,
          submittedAt: sub.submittedAt,
          reviewedAt: DateTime.now(),
          studentName: sub.studentName,
          studentNisn: sub.studentNisn,
          studentClass: sub.studentClass,
        );
      });
    }

    final res = await SubmissionService.reviewSubmission(
      submissionId: sub.id,
      status: status,
      supervisorNotes: notes,
    );
    if (mounted) {
      if (res.success) {
        _fetchSubmissions();
        _fetchStats();
        _fetchAuditLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'APPROVED'
                  ? 'Pengajuan PKL berhasil disetujui (ACC)!'
                  : (status == 'REJECTED'
                      ? 'Pengajuan PKL telah ditolak.'
                      : 'Pengajuan PKL diminta untuk direvisi.'),
            ),
            backgroundColor: status == 'APPROVED'
                ? AppColors.success
                : (status == 'REJECTED' ? AppColors.error : AppColors.warning),
          ),
        );
      } else {
        if (idx != -1) {
          setState(() {
            _submissions[idx] = sub;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Gagal memproses pengajuan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSubmissionNotesDialog(PklSubmissionModel sub, String action) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            action == 'REJECTED'
                ? 'Tolak Pengajuan PKL'
                : 'Minta Perbaikan / Revisi',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Siswa: ${sub.studentName ?? "Siswa"}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Instansi: ${sub.companyName ?? "Perusahaan"}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              const Text('Catatan & Arahan Admin Hubin:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Tuliskan catatan perbaikan atau alasan penolakan...',
                  hintStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _reviewSubmission(sub, action, notesCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'REJECTED' ? AppColors.error : AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text(
                  action == 'REJECTED' ? 'Tolak Pengajuan' : 'Kirim Catatan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSubmission(PklSubmissionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Riwayat Pengajuan PKL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data pengajuan PKL siswa "${sub.studentName ?? "Siswa"}" di "${sub.companyName ?? "Mitra"}"? Tindakan ini permanen.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final removedIndex = _submissions.indexWhere((s) => s.id == sub.id);
              if (removedIndex != -1) {
                setState(() {
                  _submissions.removeAt(removedIndex);
                });
              }
              final res = await SubmissionService.deleteSubmission(sub.id);
              if (mounted) {
                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Riwayat pengajuan/approval PKL berhasil dihapus oleh Admin.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  if (removedIndex != -1) {
                    setState(() {
                      _submissions.insert(removedIndex, sub);
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Gagal menghapus pengajuan PKL.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveCompanyProposal(int id) async {
    setState(() => _isLoading = true);
    final res = await SubmissionService.approveCompanyProposal(id);
    if (mounted) {
      if (res.success) {
        setState(() {
          _companyProposals.removeWhere((c) => c['id'] == id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usulan mitra PKL disetujui (ACC) & diaktifkan ke sistem!'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchCompanies();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal menyetujui usulan mitra.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectCompanyProposal(int id) async {
    setState(() => _isLoading = true);
    final res = await SubmissionService.rejectCompanyProposal(id);
    if (mounted) {
      if (res.success) {
        setState(() {
          _companyProposals.removeWhere((c) => c['id'] == id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usulan mitra PKL ditolak & dihapus.'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal menolak usulan.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return AppColors.success;
      case 'CHANGE_REQUESTED':
      case 'REVISION_REQUIRED':
      case 'REVISION':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Disetujui (ACC)';
      case 'VERIFIED':
        return 'Sudah Diverifikasi';
      case 'CHANGE_REQUESTED':
        return 'Pindah Lokasi';
      case 'REVISION_REQUIRED':
      case 'REVISION':
        return 'Perlu Revisi';
      case 'REJECTED':
        return 'Ditolak';
      case 'PENDING':
      case 'SUBMITTED':
      case 'UPLOADED':
      case 'UNDER_REVIEW':
        return 'Menunggu';
      default:
        return status;
    }
  }

  // --- CONFIG BACKEND URL DIALOG (ADMIN GLOBAL) ---
  void _showBackendUrlConfigDialog() {
    final hostCtrl = TextEditingController(text: ApiEndpoints.baseUrl.replaceAll('/api/v1', ''));
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.settings_ethernet, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text('Konfigurasi Global Backend URL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin dapat mengganti alamat server backend API yang digunakan oleh aplikasi secara global dan tersimpan permanen.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Host Server Backend:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: hostCtrl,
                      decoration: const InputDecoration(
                        hintText: 'http://127.0.0.1:8000 atau https://api.smkn3jogja.sch.id',
                        hintStyle: TextStyle(fontSize: 11),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isTesting = true;
                                    testResult = 'Menghubungi server...';
                                    testSuccess = null;
                                  });
                                  final testHost = hostCtrl.text.trim();
                                  final pingUrl = testHost.endsWith('/api/v1')
                                      ? '$testHost/docs'
                                      : '${testHost.replaceAll(RegExp(r"/+$"), "")}/api/v1/dashboard/summary';
                                  try {
                                    final res = await ApiClient.get(pingUrl);
                                    setDialogState(() {
                                      isTesting = false;
                                      testSuccess = res.success;
                                      testResult = testSuccess == true
                                          ? 'Koneksi ke backend berhasil!'
                                          : 'Gagal terhubung (${res.error ?? "Respon tidak berhasil"})';
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      isTesting = false;
                                      testSuccess = false;
                                      testResult = 'Error: $e';
                                    });
                                  }
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check, size: 14),
                          label: const Text('Tes Koneksi', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            hostCtrl.text = ApiEndpoints.defaultHost;
                            setDialogState(() {
                              testResult = null;
                              testSuccess = null;
                            });
                          },
                          child: const Text('Reset Default', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: testSuccess == true ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: testSuccess == true ? AppColors.success : AppColors.error,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              testSuccess == true ? Icons.check_circle : Icons.error_outline,
                              size: 14,
                              color: testSuccess == true ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: testSuccess == true ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newHost = hostCtrl.text.trim();
                    if (newHost.isEmpty) return;
                    ApiEndpoints.setCustomHost(newHost);
                    await LocalStorage.saveCustomHost(newHost);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Backend URL diperbarui secara global ke: ${ApiEndpoints.baseUrl}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadAllAdminData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Terapkan Secara Global'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PORTAL ADMIN HUBIN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Text('SMKN 3 Yogyakarta • BKK & DUDI',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: Colors.white),
            tooltip: 'Konfigurasi Backend API Global',
            onPressed: _showBackendUrlConfigDialog,
          ),
          AnimatedRefreshButton(
            onRefresh: _loadAllAdminData,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profil Admin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFDA4AF)),
            tooltip: 'Keluar Akun',
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          isScrollable: true,
          tabs: [
            const Tab(
                icon: Icon(Icons.analytics_outlined, size: 16),
                text: 'Ringkasan & Grafik'),
            Tab(
                icon: const Icon(Icons.people_alt_outlined, size: 16),
                text: 'Pengguna (${_users.isNotEmpty ? _users.length : (_stats['total_users'] ?? 25)})'),
            Tab(
                icon: const Icon(Icons.security, size: 16),
                text: 'Audit Logs (${_auditLogs.length})'),
            Tab(
                icon: const Icon(Icons.apartment, size: 16),
                text: 'Mitra DUDI (${_companies.isNotEmpty ? _companies.length : (_stats['total_placements'] ?? 4)})'),
            Tab(
                icon: const Icon(Icons.approval, size: 16),
                text: 'Approval PKL (${_submissions.length + _companyProposals.length})'),
            Tab(
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                text: 'Jurnal (${_journals.length})'),
            Tab(
                icon: const Icon(Icons.support_agent_rounded, size: 16),
                text: 'Tiket & Laporan (${_tickets.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildAuditLogsTab(),
                _buildCompaniesTab(),
                _buildPklApprovalTab(),
                _buildJournalsTab(),
                _buildTicketsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddUserDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah User',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : _tabController.index == 3
              ? FloatingActionButton.extended(
                  onPressed: _showAddCompanyDialog,
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add_business, color: Colors.white),
                  label: const Text('Tambah Mitra',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
    );
  }

  // TAB 1: OVERVIEW & VECTOR CHARTS
  Widget _buildOverviewTab() {
    final userDist = _stats['user_distribution'] as Map<String, dynamic>? ?? {};
    final pklDist =
        _stats['pkl_status_distribution'] as Map<String, dynamic>? ?? {};
    final monthly = _stats['monthly_activity'] as List<dynamic>? ?? [];

    // User counts with strict database fallback
    final int siswaCount = (userDist['Siswa'] ??
            userDist['siswa'] ??
            _stats['total_students'] ??
            _users.where((u) => u.role.toLowerCase() == 'siswa').length)
        as int;
    final int guruCount = (userDist['Guru'] ??
            userDist['guru'] ??
            _stats['total_teachers'] ??
            _users.where((u) => u.role.toLowerCase() == 'guru').length)
        as int;
    final int mitraCount = (userDist['Mitra'] ??
            userDist['mitra'] ??
            _stats['total_mentors'] ??
            _companies.length)
        as int;
    final int adminCount = (userDist['Admin'] ??
            userDist['admin'] ??
            _stats['total_admins'] ??
            _users.where((u) => u.role.toLowerCase() == 'admin').length)
        as int;
    final int dudiCompaniesCount = (_stats['total_placements'] ??
            _stats['total_companies'] ??
            (_companies.isNotEmpty ? _companies.length : 4)) as int;
    final int totalUsers = (_stats['total_users'] as int?) ??
        (_users.isNotEmpty ? _users.length : (siswaCount + guruCount + mitraCount + adminCount));
    final int effectiveTotalUsers = totalUsers > 0
        ? totalUsers
        : ((siswaCount + guruCount + mitraCount + adminCount) > 0
            ? (siswaCount + guruCount + mitraCount + adminCount)
            : 1);

    // PKL Status counts
    final int approvedPkl = (pklDist['APPROVED'] ??
            pklDist['Disetujui'] ??
            _submissions.where((s) => s.status.toUpperCase() == 'APPROVED').length)
        as int;
    final int pendingPkl = (pklDist['PENDING'] ??
            pklDist['SUBMITTED'] ??
            pklDist['Menunggu'] ??
            _submissions
                .where((s) =>
                    s.status.toUpperCase() == 'SUBMITTED' ||
                    s.status.toUpperCase() == 'PENDING')
                .length)
        as int;
    final int changePkl = (pklDist['CHANGE_REQUESTED'] ??
            pklDist['Pindah Lokasi'] ??
            _submissions
                .where((s) => s.status.toUpperCase() == 'CHANGE_REQUESTED')
                .length)
        as int;
    final int rejectedPkl = ((pklDist['REVISION_REQUIRED'] ?? 0) +
            (pklDist['REJECTED'] ?? 0) +
            (pklDist['Ditolak'] ?? 0) +
            _submissions
                .where((s) =>
                    s.status.toUpperCase() == 'REJECTED' ||
                    s.status.toUpperCase() == 'REVISION_REQUIRED')
                .length)
        as int;
    final int totalSubmissions = approvedPkl + pendingPkl + changePkl + rejectedPkl;
    final int effectiveTotalSubs = totalSubmissions > 0 ? totalSubmissions : 1;

    // Tickets counts
    final int totalTickets = _tickets.length;
    final int pendingTickets =
        _tickets.where((t) => t.status.toUpperCase() == 'PENDING').length;
    final int inProgressTickets =
        _tickets.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;
    final int resolvedTickets =
        _tickets.where((t) => t.status.toUpperCase() == 'RESOLVED').length;
    final int closedTickets =
        _tickets.where((t) => t.status.toUpperCase() == 'CLOSED').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sistem Telemetri PKL Aktif',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('ONLINE • WS LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Tahun Ajaran 2024/2025 Semester Gasal',
                    style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Siswa PKL', '$siswaCount', Icons.school),
                    const SizedBox(width: 8),
                    _buildStatCard(
                        'Mitra DUDI', '$dudiCompaniesCount', Icons.apartment),
                    const SizedBox(width: 8),
                    _buildStatCard(
                        'Presensi',
                        '${_stats['overall_attendance_rate'] ?? 98.4}%',
                        Icons.how_to_reg),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // GRAFIK 1: User Distribution Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAFIK 1: DISTRIBUSI PENGGUNA TERDAFTAR (DATABASE)',
                  style:
                      AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
              Text('$effectiveTotalUsers Akun Aktif',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented visual proportional bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        if (siswaCount > 0)
                          Expanded(
                            flex: siswaCount,
                            child: Container(color: Colors.blue),
                          ),
                        if (guruCount > 0)
                          Expanded(
                            flex: guruCount,
                            child: Container(color: Colors.teal),
                          ),
                        if (mitraCount > 0)
                          Expanded(
                            flex: mitraCount,
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                        if (adminCount > 0)
                          Expanded(
                            flex: adminCount,
                            child: Container(color: Colors.purple),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDistributionBar('Siswa PKL', siswaCount, effectiveTotalUsers,
                    Colors.blue, Icons.school),
                const SizedBox(height: 10),
                _buildDistributionBar('Guru Pembimbing', guruCount,
                    effectiveTotalUsers, Colors.teal, Icons.person_search),
                const SizedBox(height: 10),
                _buildDistributionBar('Mitra DUDI / Industri', mitraCount,
                    effectiveTotalUsers, const Color(0xFFF59E0B), Icons.business),
                const SizedBox(height: 10),
                _buildDistributionBar('Administrator Hubin', adminCount,
                    effectiveTotalUsers, Colors.purple, Icons.admin_panel_settings),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // GRAFIK 2: PKL Status Analytics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAFIK 2: STATUS PENGAJUAN & PENEMPATAN PKL',
                  style:
                      AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
              Text('$totalSubmissions Pengajuan',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusMetric('Disetujui', '$approvedPkl', AppColors.success),
                    _buildStatusMetric('Menunggu', '$pendingPkl', const Color(0xFFF59E0B)),
                    _buildStatusMetric('Ganti Lokasi', '$changePkl', const Color(0xFF3B82F6)),
                    _buildStatusMetric('Revisi/Tolak', '$rejectedPkl', AppColors.error),
                  ],
                ),
                const SizedBox(height: 14),
                // Segmented bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (approvedPkl > 0)
                          Expanded(
                            flex: approvedPkl,
                            child: Container(color: AppColors.success),
                          ),
                        if (pendingPkl > 0)
                          Expanded(
                            flex: pendingPkl,
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                        if (changePkl > 0)
                          Expanded(
                            flex: changePkl,
                            child: Container(color: const Color(0xFF3B82F6)),
                          ),
                        if (rejectedPkl > 0)
                          Expanded(
                            flex: rejectedPkl,
                            child: Container(color: AppColors.error),
                          ),
                        if (totalSubmissions == 0)
                          Expanded(
                            child: Container(color: const Color(0xFFE2E8F0)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildDistributionBar(
                    'Disetujui (Approved)', approvedPkl, effectiveTotalSubs, AppColors.success, Icons.check_circle_outline),
                const SizedBox(height: 8),
                _buildDistributionBar(
                    'Menunggu Verifikasi', pendingPkl, effectiveTotalSubs, const Color(0xFFF59E0B), Icons.hourglass_top_outlined),
                const SizedBox(height: 8),
                _buildDistributionBar(
                    'Permohonan Pindah Tempat', changePkl, effectiveTotalSubs, const Color(0xFF3B82F6), Icons.sync_alt),
                const SizedBox(height: 8),
                _buildDistributionBar(
                    'Perlu Revisi / Ditolak', rejectedPkl, effectiveTotalSubs, AppColors.error, Icons.cancel_outlined),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // GRAFIK 3: Monthly Activity Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAFIK 3: TREN AKTIVITAS BULANAN (PRESENSI & JURNAL)',
                  style:
                      AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Presensi', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Jurnal', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: monthly.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada histori data bulanan.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthly.map((m) {
                      final monthName = m['month'] ?? '';
                      final journals = (m['journals'] ?? 0) as int;
                      final presences = (m['presences'] ?? m['attendances'] ?? 0) as int;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                children: [
                                  Text('$presences',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 16,
                                    height: (presences * 2.0).clamp(10.0, 90.0),
                                    decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Column(
                                children: [
                                  Text('$journals',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary)),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 16,
                                    height: (journals * 3.0).clamp(10.0, 90.0),
                                    decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(monthName,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B))),
                        ],
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          // GRAFIK 4: HELPDESK & LAPORAN BUG TELEMETRI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAFIK 4: STATUS TIKET & LAPORAN BUG KENDALA',
                  style:
                      AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
              InkWell(
                onTap: () => _tabController.animateTo(6),
                child: const Row(
                  children: [
                    Text('Buka Tiket',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusMetric('Menunggu', '$pendingTickets', const Color(0xFFF59E0B)),
                    _buildStatusMetric('Diproses', '$inProgressTickets', const Color(0xFF2563EB)),
                    _buildStatusMetric('Selesai', '$resolvedTickets', const Color(0xFF10B981)),
                    _buildStatusMetric('Ditutup', '$closedTickets', const Color(0xFF64748B)),
                  ],
                ),
                if (totalTickets > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (pendingTickets > 0)
                            Expanded(
                              flex: pendingTickets,
                              child: Container(color: const Color(0xFFF59E0B)),
                            ),
                          if (inProgressTickets > 0)
                            Expanded(
                              flex: inProgressTickets,
                              child: Container(color: const Color(0xFF2563EB)),
                            ),
                          if (resolvedTickets > 0)
                            Expanded(
                              flex: resolvedTickets,
                              child: Container(color: const Color(0xFF10B981)),
                            ),
                          if (closedTickets > 0)
                            Expanded(
                              flex: closedTickets,
                              child: Container(color: const Color(0xFF64748B)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(6),
                    icon: const Icon(Icons.support_agent_rounded, size: 16),
                    label: Text('Kelola & Chat Laporan ($totalTickets Tiket)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(
      String role, int val, int total, Color color, IconData icon) {
    final double pct = total > 0 ? (val / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(role,
                    style:
                        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            Text('$val Pengguna (${(pct * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFFE2E8F0), fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: USER MANAGEMENT
  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari NISN, NIP, atau nama...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: (q) => _fetchUsers(q, _selectedRoleFilter),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Tambah', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Peran Pengguna:',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant)),
                  DropdownButton<String>(
                    value: _selectedRoleFilter,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'semua', child: Text('Semua')),
                      DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                      DropdownMenuItem(value: 'guru', child: Text('Guru')),
                      DropdownMenuItem(value: 'mitra', child: Text('Mitra')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedRoleFilter = val ?? 'semua');
                      _fetchUsers(_searchController.text, val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final u = _users[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showUserDetailModal(u),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: u.role == 'admin'
                              ? Colors.purple.shade100
                              : u.role == 'guru'
                                  ? Colors.teal.shade100
                                  : u.role == 'mitra'
                                      ? Colors.amber.shade100
                                      : Colors.blue.shade100,
                          child: Icon(
                            u.role == 'admin'
                                ? Icons.shield
                                : u.role == 'guru'
                                    ? Icons.school
                                    : u.role == 'mitra'
                                        ? Icons.apartment
                                        : Icons.person,
                            color: u.role == 'admin'
                                ? Colors.purple
                                : u.role == 'guru'
                                    ? Colors.teal
                                    : u.role == 'mitra'
                                        ? Colors.amber.shade800
                                        : Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${u.role.toUpperCase()} • ID: ${u.username}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B))),
                              if (u.studentClass != null &&
                                  u.studentClass!.isNotEmpty)
                                Text('Kelas: ${u.studentClass}',
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.primary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined,
                              size: 18, color: Color(0xFF64748B)),
                          onPressed: () => _showUserDetailModal(u),
                          tooltip: 'Lihat Detail',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 18, color: AppColors.primary),
                          onPressed: () => _showEditUserDialog(u),
                          tooltip: 'Edit Data',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          onPressed: () => _showDeleteUserDialog(u),
                          tooltip: 'Hapus Pengguna',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 3: AUDIT LOGS
  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _auditSearchController,
            decoration: InputDecoration(
              hintText: 'Cari jejak audit (Aktor, Aksi, Modul)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (q) => _fetchAuditLogs(q, _auditRoleFilter),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_auditLogs.length} jejak audit',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B)),
              ),
              if (_auditLogs.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAllAuditLogs,
                  icon: const Icon(Icons.delete_sweep,
                      size: 16, color: AppColors.error),
                  label: const Text('Bersihkan Semua Log',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _auditLogs.isEmpty
              ? const Center(child: Text('Belum ada jejak audit tercatat.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _auditLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = _auditLogs[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log['action'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    log['created_at'] != null
                                        ? log['created_at']
                                            .toString()
                                            .substring(0, 19)
                                            .replaceAll('T', ' ')
                                        : '',
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _deleteSingleAuditLog(log['id']),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.delete_outline,
                                          size: 16, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.account_circle,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${log['actor_name'] ?? 'System'} (${log['actor_role'] ?? ''})',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                    color: AppColors.surfaceHigh,
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text('Modul: ${log['module'] ?? ''}',
                                    style: const TextStyle(fontSize: 9)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log['description'] ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 4: MITRA INDUSTRI (DUDI) CRUD
  Widget _buildCompaniesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Mitra Industri DUDI (${_companies.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCompanyDialog,
                icon: const Icon(Icons.add_business, size: 16),
                label: const Text('Tambah Mitra', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _companies.isEmpty
              ? const Center(child: Text('Belum ada mitra industri terdaftar.'))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _companies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = _companies[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  c['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.primary),
                                    onPressed: () => _showEditCompanyDialog(c),
                                    tooltip: 'Edit Mitra',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.error),
                                    onPressed: () =>
                                        _showDeleteCompanyDialog(c),
                                    tooltip: 'Hapus Mitra',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                              c['industry_sector'] ??
                                  c['division'] ??
                                  'Sektor DUDI',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(c['address'] ?? '',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_pin,
                                  size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                  'PIC: ${c['mentor_name'] ?? c['contact_person'] ?? '-'}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              const Icon(Icons.phone,
                                  size: 14, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text(c['phone'] ?? c['mentor_phone'] ?? '-',
                                  style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- JOURNAL INSPECTOR & MODALS ---
  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Gagal memuat gambar dokumentasi.',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminRevisionDialog(Map<String, dynamic> j) {
    final notesCtrl = TextEditingController();
    final studentName = j['student_name'] ?? j['reviewer_name'] ?? 'Siswa';
    final workSummary = j['work_summary'] ?? j['activity_description'] ?? 'Log teknis';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? errorText;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.rule_folder_outlined, color: AppColors.warning, size: 22),
                  SizedBox(width: 8),
                  Text('Minta Revisi Jurnal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Siswa: $studentName',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Tanggal: ${j['date'] ?? "-"} • Day ${j['day_number'] ?? "-"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Text(
                            workSummary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Alasan / Arahan Perbaikan (Wajib Diisi):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Rincian topologi dan laporan konfigurasi belum dilampirkan...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: const OutlineInputBorder(),
                        errorText: errorText,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = notesCtrl.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() {
                        errorText = 'Catatan / alasan revisi wajib diisi!';
                      });
                      return;
                    }
                    Navigator.pop(ctx);
                    _reviewJournalAction(j['id'], 'revision', text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kirim Arahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJournalDetailDialog(Map<String, dynamic> j) {
    final status = (j['status'] ?? 'pending').toString().toUpperCase();
    final studentName = j['student_name'] ?? j['reviewer_name'] ?? 'Siswa Bimbingan';
    final workSummary = j['work_summary'] ?? j['activity_description'] ?? 'Log pekerjaan PKL';
    final notes = j['revision_notes'] ?? j['mentor_notes'];
    final photo = j['photo_url'];

    List<dynamic> skills = [];
    if (j['ai_extracted_skills'] != null) {
      try {
        if (j['ai_extracted_skills'] is List) {
          skills = j['ai_extracted_skills'];
        } else if (j['ai_extracted_skills'] is String) {
          skills = jsonDecode(j['ai_extracted_skills']);
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jurnal: $studentName',
                              style: AppTypography.headlineSm
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              'Tanggal: ${j['date'] ?? "-"} • Day ${j['day_number'] ?? "-"} • ${j['hours_spent'] ?? 8.0} Jam',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'APPROVED' || status == 'VERIFIED'
                            ? AppColors.success.withOpacity(0.12)
                            : status == 'REVISION_REQUIRED' || status == 'REVISION'
                                ? AppColors.warning.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: status == 'APPROVED' || status == 'VERIFIED'
                              ? AppColors.success
                              : status == 'REVISION_REQUIRED' || status == 'REVISION'
                                  ? AppColors.warning
                                  : AppColors.primary,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'APPROVED' || status == 'VERIFIED'
                              ? AppColors.success
                              : status == 'REVISION_REQUIRED' || status == 'REVISION'
                                  ? AppColors.warning
                                  : AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (photo != null && photo.toString().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        InkWell(
                          onTap: () => _showFullImageDialog(
                              context, ApiEndpoints.getImageUrl(photo.toString())),
                          child: Image.network(
                            ApiEndpoints.getImageUrl(photo.toString()),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: AppColors.surfaceHigh,
                              child: const Center(
                                  child: Icon(Icons.broken_image, size: 36)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Lihat Foto Penuh',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Uraian Log Pekerjaan Teknis',
                    style: AppTypography.labelMd
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(workSummary,
                      style: AppTypography.bodyMd.copyWith(height: 1.5)),
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Kompetensi Teknis AI Terdeteksi (${skills.length})',
                      style: AppTypography.labelSm
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skills.map((s) {
                      final name = s is Map ? (s['name'] ?? '') : s.toString();
                      final score = s is Map ? (s['score'] ?? '') : '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(score.toString().isNotEmpty ? '$name ($score%)' : name,
                            style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ],
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assignment_late,
                                color: AppColors.warning, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Catatan Evaluasi / Alasan Revisi:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(notes.toString(),
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAdminRevisionDialog(j);
                        },
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Minta Revisi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reviewJournalAction(j['id'], 'approve', 'Disetujui Admin Hubin.');
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Setujui Jurnal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteJournal(j['id']);
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  label: const Text('Hapus Jurnal Siswa', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(38),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 5: JOURNALS REVIEW & INSPECTION
  Widget _buildJournalsTab() {
    final query = _journalSearchCtrl.text.toLowerCase().trim();
    final filtered = _journals.where((j) {
      final student = (j['student_name'] ?? j['reviewer_name'] ?? '').toString().toLowerCase();
      final summary = (j['work_summary'] ?? j['activity_description'] ?? '').toString().toLowerCase();
      final status = (j['status'] ?? '').toString().toLowerCase();

      final matchesQuery = query.isEmpty || student.contains(query) || summary.contains(query);
      final matchesStatus = _selectedJournalStatus == 'semua' ||
          (_selectedJournalStatus == 'menunggu' && (status == 'submitted' || status == 'review' || status == 'resubmitted')) ||
          (_selectedJournalStatus == 'disetujui' && (status == 'approved' || status == 'verified')) ||
          (_selectedJournalStatus == 'revisi' && (status == 'revision' || status == 'revision_required'));

      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _journalSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama siswa atau uraian pekerjaan teknis...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _journalSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _journalSearchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildJournalFilterChip('semua', 'Semua (${_journals.length})'),
                    const SizedBox(width: 6),
                    _buildJournalFilterChip('menunggu', 'Menunggu Validasi'),
                    const SizedBox(width: 6),
                    _buildJournalFilterChip('disetujui', 'Disetujui'),
                    const SizedBox(width: 6),
                    _buildJournalFilterChip('revisi', 'Perlu Revisi'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 48, color: AppColors.outline),
                      const SizedBox(height: 8),
                      Text('Tidak ada jurnal kegiatan ditemukan.',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final j = filtered[index];
                    final status = (j['status'] ?? 'pending').toString().toLowerCase();
                    final studentName = j['student_name'] ?? j['reviewer_name'] ?? 'Siswa PKL';
                    final workSummary = j['work_summary'] ?? j['activity_description'] ?? 'Log pekerjaan PKL';
                    final notes = j['revision_notes'] ?? j['mentor_notes'];
                    final photo = j['photo_url'];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      studentName,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(j['date'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B))),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'approved' || status == 'verified'
                                      ? const Color(0xFFECFDF5)
                                      : status == 'revision' || status == 'revision_required'
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'approved' || status == 'verified'
                                        ? const Color(0xFF059669)
                                        : status == 'revision' || status == 'revision_required'
                                            ? Colors.amber.shade800
                                            : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (photo != null && photo.toString().isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiEndpoints.getImageUrl(photo.toString()),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  workSummary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: AppColors.onSurface),
                                ),
                              ),
                            ],
                          ),
                          if (notes != null && notes.toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('Catatan: $notes',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF475569))),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showJournalDetailDialog(j),
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('Lihat Detail',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                tooltip: 'Hapus Jurnal Siswa',
                                onPressed: () => _deleteJournal(j['id']),
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton(
                                onPressed: () => _showAdminRevisionDialog(j),
                                child: const Text('Revisi',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () => _reviewJournalAction(
                                    j['id'], 'approve', 'Disetujui Admin Hubin'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                child: const Text('Setujui',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJournalFilterChip(String key, String label) {
    final isSelected = _selectedJournalStatus == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.onSurface)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLow,
      onSelected: (_) {
        setState(() => _selectedJournalStatus = key);
      },
    );
  }

  // TAB: APPROVAL PKL, PINDAH TEMPAT, & USULAN MITRA (ADMIN)
  Widget _buildPklApprovalTab() {
    final pendingCount = _submissions.where((s) => s.status == 'SUBMITTED' || s.status == 'CHANGE_REQUESTED').length;
    final approvedCount = _submissions.where((s) => s.status == 'APPROVED').length;
    final rejectedCount = _submissions.where((s) => s.status == 'REJECTED').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard Approval PKL Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FULL ACCESS HUBIN',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verifikasi & Kelola Pengajuan PKL Siswa, Usulan Industri Baru, dan Permohonan Pindah PKL',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAdminStatCol('Total Pengajuan', '${_submissions.length}'),
                    _buildAdminStatCol('Menunggu ACC', '$pendingCount'),
                    _buildAdminStatCol('Disetujui', '$approvedCount'),
                    _buildAdminStatCol('Ditolak', '$rejectedCount'),
                    _buildAdminStatCol('Usulan Mitra', '${_companyProposals.length}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 1: Usulan Tempat Mitra PKL Baru dari Siswa
          if (_companyProposals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_business, color: Color(0xFF0F766E), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'USULAN MITRA PKL BARU DARI SISWA (${_companyProposals.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _companyProposals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final prop = _companyProposals[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'USULAN MITRA BARU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          Text(
                            prop['division'] ?? 'Sektor DUDI',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prop['name'] ?? 'Nama Industri',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prop['address'] ?? '-',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      if (prop['mentor_name'] != null || prop['mentor_phone'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'PIC: ${prop['mentor_name'] ?? "-"} • Telp: ${prop['mentor_phone'] ?? "-"}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                      if (prop['notes'] != null && prop['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Catatan: "${prop['notes']}"',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectCompanyProposal(prop['id']),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Tolak & Hapus', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveCompanyProposal(prop['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('ACC & Aktifkan',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Section 2: Submissions & Change Requests
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.approval, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'PERMOHONAN PENEMPATAN & PINDAH PKL (${_submissions.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_submissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('Tidak ada permohonan penempatan PKL.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _submissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = _submissions[index];
                final isChangeRequest = sub.status == 'CHANGE_REQUESTED';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isChangeRequest
                          ? AppColors.warning
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isChangeRequest
                                  ? AppColors.warningContainer
                                  : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isChangeRequest ? 'PERMOHONAN GANTI PKL' : 'PENGAJUAN PKL BARU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isChangeRequest
                                    ? AppColors.onWarningContainer
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(sub.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatStatusLabel(sub.status),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(sub.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        sub.studentName ?? 'Siswa PKL',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'NISN: ${sub.studentNisn ?? "-"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perusahaan Tujuan: ${sub.companyName ?? "-"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              sub.address ?? '-',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            if (sub.changeReason != null && sub.changeReason!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Alasan Pindah: "${sub.changeReason}"',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                            if (sub.supervisorNotes != null && sub.supervisorNotes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Catatan Guru/Admin: "${sub.supervisorNotes}"',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action buttons: Revisi, Tolak, Setujui, and Trash (Hapus)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showSubmissionNotesDialog(sub, 'REVISION_REQUIRED'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Revisi', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showSubmissionNotesDialog(sub, 'REJECTED'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Tolak', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _reviewSubmission(
                                sub,
                                'APPROVED',
                                isChangeRequest
                                    ? 'Perpindahan PKL disetujui Admin Hubin'
                                    : 'Disetujui oleh Admin Hubin',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                isChangeRequest ? 'ACC Pindah' : 'Setujui',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                              tooltip: 'Hapus Riwayat Pengajuan/Approval Ini',
                              onPressed: () => _confirmDeleteSubmission(sub),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 7: TIKET LAPORAN & HELPDESK BUG
  Widget _buildTicketsTab() {
    final query = _ticketSearchCtrl.text.toLowerCase().trim();
    final filtered = _tickets.where((t) {
      final matchesStatus = _selectedTicketStatus == 'all' ||
          t.status.toUpperCase() == _selectedTicketStatus.toUpperCase();
      final matchesQuery = query.isEmpty ||
          t.ticketNumber.toLowerCase().contains(query) ||
          t.userName.toLowerCase().contains(query) ||
          t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    final pendingCount =
        _tickets.where((t) => t.status.toUpperCase() == 'PENDING').length;
    final inProgressCount =
        _tickets.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;
    final resolvedCount =
        _tickets.where((t) => t.status.toUpperCase() == 'RESOLVED').length;

    return Column(
      children: [
        // Filter & Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _ticketSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nomor tiket, nama siswa/guru, atau judul kendala...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _ticketSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _ticketSearchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLowest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTicketStatusFilterChip('all', 'Semua (${_tickets.length})'),
                    const SizedBox(width: 6),
                    _buildTicketStatusFilterChip('PENDING', 'Menunggu ($pendingCount)',
                        color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _buildTicketStatusFilterChip('IN_PROGRESS', 'Diproses ($inProgressCount)',
                        color: const Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    _buildTicketStatusFilterChip('RESOLVED', 'Selesai ($resolvedCount)',
                        color: const Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    _buildTicketStatusFilterChip('CLOSED', 'Ditutup',
                        color: const Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of tickets
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_chat_unread_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak ada tiket kendala ditemukan.',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Siswa dan Guru dapat melaporkan bug atau kendala melalui menu Lapor.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final ticket = filtered[idx];
                    return _buildAdminTicketCard(ticket);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTicketStatusFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedTicketStatus == key;
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTicketStatus = key;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTicketCard(ReportTicketModel ticket) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getTicketCategoryColor(ticket.category).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTicketCategoryColor(ticket.category),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                _buildTicketPriorityBadge(ticket.priority),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getTicketStatusColor(ticket.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getTicketStatusColor(ticket.status)),
                  ),
                  child: Text(
                    _getTicketStatusLabel(ticket.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTicketStatusColor(ticket.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Submitter Info
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: ticket.userRole.toLowerCase() == 'guru'
                      ? Colors.teal.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    ticket.userRole.toLowerCase() == 'guru'
                        ? Icons.person_search
                        : Icons.school,
                    size: 14,
                    color: ticket.userRole.toLowerCase() == 'guru'
                        ? Colors.teal.shade800
                        : Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ticket.userName} (${ticket.userRole})${ticket.userClass != null && ticket.userClass!.isNotEmpty ? " • ${ticket.userClass}" : ""}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569)),
                  ),
                ),
                Text(
                  '${ticket.createdAt.toLocal().toString().split(".")[0].substring(0, 16)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Description
            Text(
              ticket.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),

            // Attachment photo thumbnail
            if (ticket.photoUrl != null && ticket.photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _showImagePreviewDialog(
                      context, ApiEndpoints.getImageUrl(ticket.photoUrl)),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        ApiEndpoints.getImageUrl(ticket.photoUrl),
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 60,
                          color: const Color(0xFFF1F5F9),
                          alignment: Alignment.center,
                          child: const Text('Foto tidak dapat dimuat',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Perbesar Foto',
                                style: TextStyle(fontSize: 9, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Admin notes box
            if (ticket.adminNotes != null && ticket.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.assignment_turned_in, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Solusi Hubin: "${ticket.adminNotes}"',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons Row
            Row(
              children: [
                // Chat badge / button
                OutlinedButton.icon(
                  onPressed: () => _openAdminTicketChat(ticket),
                  icon: const Icon(Icons.chat_bubble_outline, size: 15),
                  label: Text(
                    ticket.messages.isEmpty
                        ? 'Balas'
                        : '${ticket.messages.length} Diskusi',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),

                // Change status button
                ElevatedButton.icon(
                  onPressed: () => _showChangeStatusDialog(ticket),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Ubah Status', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const Spacer(),

                // Delete Button (In-place smooth)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  tooltip: 'Hapus Tiket Laporan',
                  onPressed: () => _deleteTicketInPlace(ticket),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPriorityBadge(String priority) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF64748B);
    String label = 'NORMAL';

    if (priority.toUpperCase() == 'MENDESAK' || priority.toUpperCase() == 'URGENT') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      label = 'MENDESAK';
    } else if (priority.toUpperCase() == 'TINGGI' || priority.toUpperCase() == 'HIGH') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      label = 'TINGGI';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Color _getTicketStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB);
      case 'RESOLVED':
        return const Color(0xFF10B981);
      case 'CLOSED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _getTicketStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'MENUNGGU';
      case 'IN_PROGRESS':
        return 'SEDANG DIPROSES';
      case 'RESOLVED':
        return 'SELESAI';
      case 'CLOSED':
        return 'DITUTUP';
      default:
        return status.toUpperCase();
    }
  }

  Color _getTicketCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'BUG':
        return const Color(0xFFEF4444);
      case 'PRESENSI':
        return const Color(0xFF3B82F6);
      case 'PENEMPATAN':
        return const Color(0xFF8B5CF6);
      case 'JURNAL':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // DIALOG UBAH STATUS TIKET
  Future<void> _showChangeStatusDialog(ReportTicketModel ticket) async {
    String newStatus = ticket.status.toUpperCase();
    final notesCtrl = TextEditingController(text: ticket.adminNotes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Tindak Lanjut #${ticket.ticketNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kendala: ${ticket.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Pelapor: ${ticket.userName} (${ticket.userRole})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                const Text('Pilih Status Tindak Lanjut:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: newStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'PENDING', child: Text('MENUNGGU (PENDING)')),
                    DropdownMenuItem(
                        value: 'IN_PROGRESS',
                        child: Text('SEDANG DIPROSES (IN_PROGRESS)')),
                    DropdownMenuItem(
                        value: 'RESOLVED',
                        child: Text('SELESAI DITANGANI (RESOLVED)')),
                    DropdownMenuItem(
                        value: 'CLOSED', child: Text('DITUTUP (CLOSED)')),
                  ],
                  onChanged: (v) =>
                      setDlgState(() => newStatus = v ?? 'PENDING'),
                ),
                const SizedBox(height: 14),
                const Text('Catatan Solusi / Tanggapan Admin:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Tulis catatan penyelesaian atau petunjuk teknis untuk pelapor...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan Status'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final res = await TicketService.updateTicketStatus(
        ticketId: ticket.id,
        status: newStatus,
        adminNotes: notesCtrl.text.trim().isNotEmpty
            ? notesCtrl.text.trim()
            : null,
      );
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Status tiket #${ticket.ticketNumber} berhasil diperbarui!'),
              backgroundColor: AppColors.success,
            ),
          );
          await _fetchTickets();
          await _fetchStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.error ?? 'Gagal mengubah status tiket.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // DIALOG CHAT ADMIN DENGAN PELAPOR
  void _openAdminTicketChat(ReportTicketModel ticket) async {
    final fresh = await TicketService.getTicketDetail(ticket.id) ?? ticket;
    if (!mounted) return;

    final msgCtrl = TextEditingController();
    Uint8List? replyBytes;
    String? msgPhotoUrl;
    bool isUploadingMsgPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getTicketCategoryColor(fresh.category)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fresh.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getTicketCategoryColor(fresh.category),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fresh.ticketNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _showChangeStatusDialog(fresh);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTicketStatusColor(fresh.status)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _getTicketStatusColor(fresh.status)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getTicketStatusLabel(fresh.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getTicketStatusColor(fresh.status),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit,
                                  size: 11,
                                  color: _getTicketStatusColor(fresh.status)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fresh.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pelapor: ${fresh.userName} (${fresh.userRole})${fresh.userClass != null ? " • ${fresh.userClass}" : ""}',
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 16),

                  // Original ticket description & initial photo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Uraian Kendala Pelapor:',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(fresh.description,
                            style: const TextStyle(fontSize: 12)),
                        if (fresh.photoUrl != null &&
                            fresh.photoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => _showImagePreviewDialog(
                                  context,
                                  ApiEndpoints.getImageUrl(fresh.photoUrl)),
                              child: Image.network(
                                ApiEndpoints.getImageUrl(fresh.photoUrl),
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Text(
                                    'Gagal memuat foto lampiran.'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Percakapan & Solusi Admin:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        tooltip: 'Segarkan Percakapan',
                        onPressed: () async {
                          final updated =
                              await TicketService.getTicketDetail(fresh.id);
                          if (updated != null) {
                            setSheetState(() {
                              fresh.messages.clear();
                              fresh.messages.addAll(updated.messages);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Messages list
                  Expanded(
                    child: fresh.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada percakapan. Kirim instruksi solusi atau balasan di bawah.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: fresh.messages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final msg = fresh.messages[idx];
                              final isAdmin =
                                  msg.senderRole.toUpperCase() == 'ADMIN';
                              return Align(
                                alignment: isAdmin
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.78,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isAdmin
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            msg.senderName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isAdmin
                                                  ? AppColors.primary
                                                  : const Color(0xFF0F766E),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${msg.senderRole})',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(msg.message,
                                          style:
                                              const TextStyle(fontSize: 12)),
                                      if (msg.photoUrl != null &&
                                          msg.photoUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: InkWell(
                                            onTap: () => _showImagePreviewDialog(
                                                context,
                                                ApiEndpoints.getImageUrl(
                                                    msg.photoUrl)),
                                            child: Image.network(
                                              ApiEndpoints.getImageUrl(
                                                  msg.photoUrl),
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Text('Gagal memuat foto.'),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${msg.createdAt.toLocal().toString().split(".")[0].substring(0, 16)}',
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 8),

                  // Image attachment preview if selected
                  if (replyBytes != null) ...[
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                replyBytes!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (isUploadingMsgPhoto)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isUploadingMsgPhoto
                                ? 'Mengunggah foto solusi...'
                                : (msgPhotoUrl != null
                                    ? 'Foto solusi siap dikirim'
                                    : 'Gagal mengunggah foto'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isUploadingMsgPhoto
                                  ? AppColors.warning
                                  : (msgPhotoUrl != null
                                      ? AppColors.success
                                      : AppColors.error),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => setSheetState(() {
                            replyBytes = null;
                            msgPhotoUrl = null;
                            isUploadingMsgPhoto = false;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Input row
                  Row(
                    children: [
                      IconButton(
                        icon: isUploadingMsgPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.attach_file, color: Color(0xFF64748B)),
                        tooltip: 'Lampirkan Foto Solusi',
                        onPressed: isUploadingMsgPhoto
                            ? null
                            : () async {
                                final res = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (res != null &&
                                    res.files.isNotEmpty &&
                                    res.files.first.bytes != null) {
                                  final file = res.files.first;
                                  setSheetState(() {
                                    replyBytes = file.bytes;
                                    isUploadingMsgPhoto = true;
                                    msgPhotoUrl = null;
                                  });
                                  final url = await TicketService.uploadTicketPhoto(
                                      file.bytes!, file.name);
                                  setSheetState(() {
                                    msgPhotoUrl = url;
                                    isUploadingMsgPhoto = false;
                                  });
                                  if (url == null && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Gagal mengunggah foto lampiran. Pastikan format valid (JPG/PNG/WEBP).'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      Expanded(
                        child: TextField(
                          controller: msgCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Tulis solusi atau instruksi...',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppColors.primary),
                        onPressed: () async {
                          if (isUploadingMsgPhoto) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Foto sedang diunggah, mohon tunggu sebentar...')),
                            );
                            return;
                          }
                          final text = msgCtrl.text.trim();
                          if (text.isEmpty && msgPhotoUrl == null) return;
                          msgCtrl.clear();
                          final pUrl = msgPhotoUrl;
                          setSheetState(() {
                            replyBytes = null;
                            msgPhotoUrl = null;
                          });

                          final res = await TicketService.sendMessage(
                            ticketId: fresh.id,
                            message: text.isNotEmpty
                                ? text
                                : 'Mengirim lampiran foto solusi teknis.',
                            photoUrl: pUrl,
                          );

                          if (res.success) {
                            final updated =
                                await TicketService.getTicketDetail(fresh.id);
                            if (updated != null) {
                              setSheetState(() {
                                fresh.messages.clear();
                                fresh.messages.addAll(updated.messages);
                              });
                            }
                            _fetchTickets();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // SMOOTH IN-PLACE DELETE TIKET
  Future<void> _deleteTicketInPlace(ReportTicketModel ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Tiket'),
        content: Text(
            'Apakah Anda yakin ingin menghapus tiket #${ticket.ticketNumber} "${ticket.title}" beserta seluruh percakapan di dalamnya?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Instant in-place smooth removal without full reload
    setState(() {
      _tickets.removeWhere((t) => t.id == ticket.id);
    });

    final res = await TicketService.deleteTicket(ticket.id);
    if (mounted) {
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tiket #${ticket.ticketNumber} berhasil dihapus.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        _fetchStats();
      } else {
        await _fetchTickets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Gagal menghapus tiket.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // DIALOG PREVIEW FOTO FULLSCREEN
  void _showImagePreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Gagal memuat gambar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatCol(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }
}
