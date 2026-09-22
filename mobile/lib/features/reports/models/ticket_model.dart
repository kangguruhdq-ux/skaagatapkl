class TicketMessageModel {
  final int id;
  final int ticketId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String? photoUrl;
  final DateTime createdAt;

  TicketMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.photoUrl,
    required this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: json['id'] as int,
      ticketId: json['ticket_id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] ?? 'Pengguna',
      senderRole: json['sender_role'] ?? 'USER',
      message: json['message'] ?? '',
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReportTicketModel {
  final int id;
  final String ticketNumber;
  final int userId;
  final String userName;
  final String userRole;
  final String? userDepartment;
  final String? userClass;
  final String title;
  final String category;
  final String priority;
  final String description;
  final String? photoUrl;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessageModel> messages;

  ReportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.userDepartment,
    this.userClass,
    required this.title,
    required this.category,
    required this.priority,
    required this.description,
    this.photoUrl,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory ReportTicketModel.fromJson(Map<String, dynamic> json) {
    var rawMessages = json['messages'] as List<dynamic>? ?? [];
    return ReportTicketModel(
      id: json['id'] as int,
      ticketNumber: json['ticket_number'] ?? '',
      userId: json['user_id'] as int,
      userName: json['user_name'] ?? 'Pengguna',
      userRole: json['user_role'] ?? 'USER',
      userDepartment: json['user_department'],
      userClass: json['user_class'],
      title: json['title'] ?? '',
      category: json['category'] ?? 'BUG',
      priority: json['priority'] ?? 'NORMAL',
      description: json['description'] ?? '',
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'PENDING',
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      messages: rawMessages
          .map((m) => TicketMessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
