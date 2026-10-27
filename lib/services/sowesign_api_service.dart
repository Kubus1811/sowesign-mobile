import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/student_profile.dart';
import 'crypto_service.dart';
import 'png_encoder_service.dart';

class SigningResult {
  final bool success;
  final bool isDryRun;
  final String message;
  final Map<String, dynamic>? rawResponse;

  const SigningResult({
    required this.success,
    required this.isDryRun,
    required this.message,
    this.rawResponse,
  });
}

/// Service réseau gérant les échanges avec l'API officielle SoWeSign
class SoWeSignApiService {
  static const String baseUrl = 'https://app.sowesign.com/api';

  static const Map<String, String> _baseHeaders = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'fr-FR,fr;q=0.9',
    'Origin': 'capacitor://student.sowesign.com',
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
    'x-version': '1.0.16',
  };

  /// Rafraîchit la session en échangeant le refreshToken contre un token d'accès frais
  static Future<StudentProfile> refreshSession(StudentProfile profile) async {
    if (profile.refreshToken.trim().isEmpty) {
      throw Exception('Aucun jeton de rafraîchissement (refreshToken) renseigné');
    }

    final url = Uri.parse('$baseUrl/login/refresh-token');
    final response = await http.post(
      url,
      headers: {
        ..._baseHeaders,
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: json.encode({'refreshToken': profile.refreshToken.trim()}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur d\'authentification (Code HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final accessToken = data['token'] as String?;
    final newRefreshToken = data['refreshToken'] as String? ?? profile.refreshToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('L\'API n\'a pas retourné de jeton d\'accès valide.');
    }

    var updated = profile.copyWith(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
    );

    // Récupération des informations complémentaires du profil
    try {
      final profileInfo = await fetchProfile(updated);
      updated = updated.copyWith(
        studentId: profileInfo['id'] as int?,
        firstName: profileInfo['firstname'] as String?,
        lastName: profileInfo['lastname'] as String?,
        email: profileInfo['email'] as String? ?? profile.email,
      );
    } catch (_) {
      // Les infos de profil sont optionnelles pour la suite
    }

    return updated;
  }

  /// Récupère le profil de l'étudiant
  static Future<Map<String, dynamic>> fetchProfile(StudentProfile profile) async {
    final token = profile.accessToken;
    if (token == null) throw Exception('Session non initialisée');

    final url = Uri.parse('$baseUrl/student/profile');
    final response = await http.get(
      url,
      headers: {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Impossible de charger le profil (${response.statusCode})');
  }

  /// Récupère la liste des cours pour une date donnée (par défaut aujourd'hui)
  static Future<List<Course>> fetchDailyCourses(
    StudentProfile profile, {
    DateTime? date,
  }) async {
    final token = profile.accessToken;
    if (token == null) {
      throw Exception('Session expirée ou non connectée. Veuillez rafraîchir.');
    }

    final targetDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
    final url = Uri.parse('$baseUrl/student/courses?date=$dateStr');

    final response = await http.get(
      url,
      headers: {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors du chargement des cours (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    final coursesList = <Course>[];

    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          coursesList.add(Course.fromJson(item));
        }
      }
    }

    // Tri chronologique des cours de la journée
    coursesList.sort((a, b) => a.startTime.compareTo(b.startTime));
    return coursesList;
  }

  /// Requêtes accessoires cosmétiques identiques à l'application mobile
  static Future<void> performCosmeticRequests(StudentProfile profile) async {
    final token = profile.accessToken;
    if (token == null) return;
    final headers = {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };

    try {
      await http.get(Uri.parse('$baseUrl/student/app/logo'), headers: headers);
      await http.get(Uri.parse('$baseUrl/config/client'), headers: headers);
      await http.get(Uri.parse('$baseUrl/recoveries'), headers: headers);
      await http.get(Uri.parse('$baseUrl/presenttokens'), headers: headers);
    } catch (_) {
      // Ignoré volontairement (requêtes cosmétiques non bloquantes)
    }
  }

  /// Exécute le processus complet d'émargement conforme
  static Future<SigningResult> submitAttendance({
    required StudentProfile profile,
    required Course course,
    Uint8List? customSignaturePng,
  }) async {
    if (profile.accessToken == null) {
      throw Exception('Session non connectée.');
    }
    final studentId = profile.studentId ?? 22946;

    // Exécution des requêtes préparatoires WebKit
    await performCosmeticRequests(profile);

    // 1. Génération de l'image de signature conforme 1-bit WebKit
    final pngBytes = customSignaturePng ??
        PngEncoderService.generateOrganicSignaturePng();
    final signatureBase64 =
        'data:image/png;base64,${base64.encode(pngBytes)}';

    // 2. Chiffrement du checkCode balise
    final checkCodePayload = {
      'course_id': course.id,
      'student_id': studentId,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    final encryptedCheckCode = CryptoService.encryptCheckCode(
      checkCodePayload,
      course.id,
      studentId,
    );

    // 3. Construction du payload de signature
    final signaturePayload = {
      'course_id': course.id,
      'student_id': studentId,
      'signature': signatureBase64,
      'checkCode': encryptedCheckCode,
      'beacon_mode': 'auto',
      'device': 'iPhone16,1',
      'date': DateTime.now().toUtc().toIso8601String(),
    };

    // 4. GARDE-FOU STRICT : VÉRIFICATION DU MODE DRY-RUN / SIMULATION
    if (profile.isDryRun) {
      return SigningResult(
        success: true,
        isDryRun: true,
        message:
            '[SIMULATION SÉCURISÉE RÉUSSIE] Toutes les étapes ont été validées sans envoi réel au serveur.\n'
            '• CheckCode chiffré : ${encryptedCheckCode.substring(0, 24)}...\n'
            '• Signature WebKit 1-bit générée (${pngBytes.length} octets)\n'
            '• Aucune modification de présence sur les serveurs SoWeSign.',
        rawResponse: {
          'dry_run': true,
          'course_id': course.id,
          'student_id': studentId,
          'payload_bytes': pngBytes.length,
        },
      );
    }

    // 5. MODE RÉEL (Exécuté uniquement si isDryRun == false)
    final encryptedEnvelope = CryptoService.encryptSignature(
      signaturePayload,
      course.id,
      studentId,
    );

    final response = await http.post(
      Uri.parse('$baseUrl/signatures'),
      headers: {
        ..._baseHeaders,
        'Authorization': 'Bearer ${profile.accessToken}',
        'Content-Type': 'application/json;charset=utf-8',
      },
      body: json.encode({'data': encryptedEnvelope}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      return SigningResult(
        success: true,
        isDryRun: false,
        message: 'Émargement enregistré avec succès sur SoWeSign.',
        rawResponse: decoded is Map<String, dynamic> ? decoded : {'status': 'success'},
      );
    } else {
      throw Exception(
        'Erreur serveur lors de l\'émargement (${response.statusCode}): ${response.body}',
      );
    }
  }
}
