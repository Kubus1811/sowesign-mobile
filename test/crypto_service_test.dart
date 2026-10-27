import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sowesign_mobile_app/services/crypto_service.dart';
import 'package:sowesign_mobile_app/models/course.dart';

void main() {
  group('CryptoService & OpenSSL EVP_BytesToKey Tests', () {
    test('OpenSSL EVP_BytesToKey derivation with MD5', () {
      final password = utf8.encode('test_password');
      final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final keyIv = CryptoService.evpBytesToKey(password, salt);

      expect(keyIv.key.length, equals(32));
      expect(keyIv.iv.length, equals(16));

      // Vérification du vecteur de référence
      final keyHex = keyIv.key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(keyHex, equals('b7b820228c95c5451c71fbb7632c37da73df2b2cc636f45afc1c182d3a8d33a0'));
    });

    test('Chiffrement et Déchiffrement symétrique AES-256-CBC', () {
      const plaintext = '{"test": 123, "course_id": 8888}';
      const passphrase = 'SuperSecretKey123';

      final ciphertext = CryptoService.encryptAES(plaintext, passphrase);
      expect(ciphertext.startsWith('U2FsdGVkX1'), isTrue); // "Salted__" en base64

      final decrypted = CryptoService.decryptAES(ciphertext, passphrase);
      expect(decrypted, equals(plaintext));
    });
  });

  group('Course Model & Time Windows Tests', () {
    test('Calcul dynamique du statut émargement', () {
      final now = DateTime.now();
      
      // Cours à venir (début dans 2 heures)
      final upcomingCourse = Course(
        id: 1,
        title: 'Algorithmique Avancée',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 4)),
        openingDelayMinutes: 15,
        closingDelayMinutes: 15,
      );
      expect(upcomingCourse.currentStatus, equals(CourseSigningStatus.upcoming));

      // Cours en cours d'émargement (début dans 5 minutes, ouverture 15 min avant)
      final openCourse = Course(
        id: 2,
        title: 'Systèmes Distribués',
        startTime: now.add(const Duration(minutes: 5)),
        endTime: now.add(const Duration(hours: 2)),
        openingDelayMinutes: 15,
        closingDelayMinutes: 15,
      );
      expect(openCourse.currentStatus, equals(CourseSigningStatus.open));

      // Cours déjà signé
      final signedCourse = Course(
        id: 3,
        title: 'Anglais Technique',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 1)),
        isSigned: true,
      );
      expect(signedCourse.currentStatus, equals(CourseSigningStatus.alreadySigned));
    });
  });
}
