import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class NotificationItemModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? actionRoute;
  final bool isRead;
  final String createdAt;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.actionRoute,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      actionRoute: json['action_route'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItemModel> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final res = await ApiClient.get(ApiEndpoints.notifications);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          final list = res.data as List;
          _notifications =
              list.map((item) => NotificationItemModel.fromJson(item)).toList();
        }
      });
    }
  }

  Future<void> _markRead(int id) async {
    await ApiClient.patch('${ApiEndpoints.notifications}/$id/read');
    _fetchNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    final prev = List<NotificationItemModel>.from(_notifications);
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    final res = await ApiClient.delete('${ApiEndpoints.notifications}/$id');
    if (!res.success && mounted) {
      setState(() => _notifications = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'Gagal menghapus notifikasi.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi berhasil dihapus.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Semua Notifikasi?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Semua riwayat notifikasi dan log telemetri Anda akan dihapus secara permanen dari server.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final res = await ApiClient.delete(ApiEndpoints.notifications);
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  if (res.success) {
                    _notifications.clear();
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.success
                        ? 'Semua notifikasi berhasil dibersihkan.'
                        : (res.error ?? 'Gagal menghapus notifikasi.')),
                    backgroundColor:
                        res.success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Pusat Notifikasi & Telemetri',
            style: AppTypography.headlineSm),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Hapus Semua Notifikasi',
              onPressed: _confirmClearAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 48, color: AppColors.outline),
                      const SizedBox(height: 12),
                      Text('Tidak ada notifikasi baru',
                          style: AppTypography.bodyMd),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return InkWell(
                      onTap: item.isRead ? null : () => _markRead(item.id),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? AppColors.surfaceLowest
                              : AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.type == 'revision'
                                    ? AppColors.warningContainer
                                    : item.type == 'attendance'
                                        ? AppColors.successContainer
                                        : AppColors.surfaceHigh,
                              ),
                              child: Icon(
                                item.type == 'revision'
                                    ? Icons.assignment_late
                                    : item.type == 'attendance'
                                        ? Icons.verified
                                        : Icons.info_outline,
                                size: 18,
                                color: item.type == 'revision'
                                    ? AppColors.onWarningContainer
                                    : item.type == 'attendance'
                                        ? AppColors.success
                                        : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: AppTypography.labelMd.copyWith(
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead) ...[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: Color(0xFF94A3B8)),
                                        tooltip: 'Hapus Notifikasi',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _deleteNotification(item.id),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.message,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

