class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String role;
  final String? department;
  final String? studentClass;
  final String? phone;
  final String? avatarUrl;
  final String? deviceId;
  final String? deviceModel;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    required this.role,
    this.department,
    this.studentClass,
    this.phone,
    this.avatarUrl,
    this.deviceId,
    this.deviceModel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'siswa',
      department: json['department'],
      studentClass: json['student_class'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      deviceId: json['device_id'],
      deviceModel: json['device_model'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'role': role,
      'department': department,
      'student_class': studentClass,
      'phone': phone,
      'avatar_url': avatarUrl,
      'device_id': deviceId,
      'device_model': deviceModel,
    };
  }
}
