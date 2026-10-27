import 'dart:convert';

/// Modèle représentant les identifiants et le profil de l'étudiant.
class StudentProfile {
  final String institutionCode;
  final String email;
  final String refreshToken;
  final int? studentId;
  final String? firstName;
  final String? lastName;
  final String? accessToken;
  final bool isDryRun;

  const StudentProfile({
    required this.institutionCode,
    required this.email,
    required this.refreshToken,
    this.studentId,
    this.firstName,
    this.lastName,
    this.accessToken,
    this.isDryRun = true,
  });

  StudentProfile copyWith({
    String? institutionCode,
    String? email,
    String? refreshToken,
    int? studentId,
    String? firstName,
    String? lastName,
    String? accessToken,
    bool? isDryRun,
  }) {
    return StudentProfile(
      institutionCode: institutionCode ?? this.institutionCode,
      email: email ?? this.email,
      refreshToken: refreshToken ?? this.refreshToken,
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      accessToken: accessToken ?? this.accessToken,
      isDryRun: isDryRun ?? this.isDryRun,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institutionCode': institutionCode,
      'email': email,
      'refreshToken': refreshToken,
      'studentId': studentId,
      'firstName': firstName,
      'lastName': lastName,
      'isDryRun': isDryRun,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      institutionCode: json['institutionCode'] as String? ?? '',
      email: json['email'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      studentId: json['studentId'] as int?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      isDryRun: json['isDryRun'] as bool? ?? true,
    );
  }

  bool get isConfigured =>
      institutionCode.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      refreshToken.trim().isNotEmpty;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return email.isNotEmpty ? email : 'Non configuré';
  }
}
