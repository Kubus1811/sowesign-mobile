import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_profile.dart';

/// Service de stockage persistant pour les préférences et identifiants étudiants.
class StorageService {
  static const String _keyProfile = 'sowesign_student_profile';

  /// Charge le profil sauvegardé ou renvoie un profil par défaut sécurisé
  static Future<StudentProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyProfile);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(raw);
        return StudentProfile.fromJson(data);
      }
    } catch (_) {
      // En cas d'erreur de lecture, retour au profil par défaut
    }

    return const StudentProfile(
      institutionCode: '6109',
      email: '',
      refreshToken: '',
      isDryRun: true, // Toujours actif par défaut pour la sécurité
    );
  }

  /// Sauvegarde le profil utilisateur
  static Future<bool> saveProfile(StudentProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(profile.toJson());
      return await prefs.setString(_keyProfile, raw);
    } catch (_) {
      return false;
    }
  }

  /// Efface les données stockées
  static Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyProfile);
    } catch (_) {
      return false;
    }
  }
}
