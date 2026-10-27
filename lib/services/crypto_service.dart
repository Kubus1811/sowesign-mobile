import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

class EvpKeyResult {
  final Uint8List key;
  final Uint8List iv;
  const EvpKeyResult(this.key, this.iv);
}

/// Service cryptographique reproduisant à l'identique les algorithmes SoWeSign
/// (CryptoJS AES-256-CBC avec dérivation OpenSSL EVP_BytesToKey MD5).
class CryptoService {
  /// Secret d'application pour les validations de balises / checkCode
  static const String checkCodeSecret =
      'PXFTS9y5zE8QmuBdU8kcmngTVinIlu2WVWPF5FHwIJaKf0jkidt4XyMOEgUxDBlu3VgvHOyb6hMCCI7xis5jsxVxg6yChezZaMk8shxqRRyMhMdN6z1vCHWXikOkwBqTaBzXPHlYsifXbakcP7A2cS';

  /// Secret d'application pour le chiffrement du payload de signature
  static const String signatureSecret =
      'LBJtKx7c0doXbD3MpQhghmO6GlpFDuz0NK05wWO9OfEU0TnNEwZqNyz9AndX51wH2CKMMdSuL0aNlrAdowsTMOEv40UkqwpQG2lF9MqqT9f6sDQfOWg6JV5jWWyFnfOVa1iilrejwcx5uHMFQYb0TU';

  /// Dérivation standard OpenSSL EVP_BytesToKey avec MD5
  static EvpKeyResult evpBytesToKey(
    List<int> password,
    Uint8List salt, {
    int keyLen = 32,
    int ivLen = 16,
  }) {
    final dt = <int>[];
    List<int> d = [];
    while (dt.length < (keyLen + ivLen)) {
      final input = <int>[...d, ...password, ...salt];
      d = crypto.md5.convert(input).bytes;
      dt.addAll(d);
    }
    final key = Uint8List.fromList(dt.sublist(0, keyLen));
    final iv = Uint8List.fromList(dt.sublist(keyLen, keyLen + ivLen));
    return EvpKeyResult(key, iv);
  }

  /// Chiffrement AES-256-CBC compatible CryptoJS.AES.encrypt().toString()
  static String encryptAES(
    String plaintext,
    String passphrase, {
    Uint8List? explicitSalt,
  }) {
    final salt = explicitSalt ?? _randomBytes(8);
    final keyIv = evpBytesToKey(utf8.encode(passphrase), salt);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params =
        PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
      ParametersWithIV<KeyParameter>(KeyParameter(keyIv.key), keyIv.iv),
      null,
    );
    cipher.init(true, params);

    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encryptedBytes = cipher.process(plainBytes);

    final prefix = utf8.encode('Salted__');
    final result =
        Uint8List(prefix.length + salt.length + encryptedBytes.length);
    result.setRange(0, prefix.length, prefix);
    result.setRange(prefix.length, prefix.length + salt.length, salt);
    result.setRange(prefix.length + salt.length, result.length, encryptedBytes);

    return base64.encode(result);
  }

  /// Déchiffrement AES-256-CBC compatible CryptoJS
  static String decryptAES(String base64Data, String passphrase) {
    final data = base64.decode(base64Data);
    if (data.length < 16) {
      throw Exception('Payload binaire chiffré trop court (< 16 octets)');
    }
    final prefix = utf8.decode(data.sublist(0, 8), allowMalformed: true);
    if (prefix != 'Salted__') {
      throw Exception('En-tête OpenSSL "Salted__" absent ou invalide');
    }

    final salt = Uint8List.fromList(data.sublist(8, 16));
    final ciphertext = Uint8List.fromList(data.sublist(16));
    final keyIv = evpBytesToKey(utf8.encode(passphrase), salt);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );
    final params =
        PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
      ParametersWithIV<KeyParameter>(KeyParameter(keyIv.key), keyIv.iv),
      null,
    );
    cipher.init(false, params);

    final decryptedBytes = cipher.process(ciphertext);
    return utf8.decode(decryptedBytes);
  }

  /// Chiffre le checkcode balise pour l'API SoWeSign
  static String encryptCheckCode(
    Map<String, dynamic> payload,
    int courseId,
    int studentId,
  ) {
    final passphrase = '$checkCodeSecret$courseId$studentId';
    return encryptAES(json.encode(payload), passphrase);
  }

  /// Chiffre le payload d'émargement de signature pour l'API SoWeSign
  static String encryptSignature(
    Map<String, dynamic> payload,
    int courseId,
    int studentId,
  ) {
    final passphrase = '$signatureSecret$studentId$courseId';
    return encryptAES(json.encode(payload), passphrase);
  }

  static Uint8List _randomBytes(int count) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(count, (_) => rng.nextInt(256)),
    );
  }
}
