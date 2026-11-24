import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' hide Padding, State;
import 'package:atividade_01/core/crypto/vault_crypto.dart';

// Low iteration count keeps the suite fast; production uses KdfParams.defaultIterations.
KdfParams _fastParams() => KdfParams(salt: Uint8List(16), iterations: 1000);

void main() {
  const uid = 'user-123';
  final aad = VaultCrypto.aad(uid, 'credential-password');

  group('key derivation', () {
    test('matches the RFC 7914 PBKDF2-HMAC-SHA256 test vector', () {
      // RFC 7914 §11: P="passwd", S="salt", c=1, dkLen=64 (first 32 bytes here).
      final key = VaultCrypto.deriveKeyBytes(
        'passwd',
        KdfParams(salt: Uint8List.fromList(utf8.encode('salt')), iterations: 1),
      );
      expect(
        key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    test('matches the RFC 7914 vector with 80,000 iterations', () {
      // RFC 7914 §11: P="Password", S="NaCl", c=80000 (first 32 bytes).
      final key = VaultCrypto.deriveKeyBytes(
        'Password',
        KdfParams(salt: Uint8List.fromList(utf8.encode('NaCl')), iterations: 80000),
      );
      expect(
        key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56',
      );
    });

    test('agrees with pointycastle on random passwords and salts', () {
      final rnd = Random(42);
      Uint8List bytes(int n) =>
          Uint8List.fromList(List<int>.generate(n, (_) => rnd.nextInt(256)));
      // Covers passwords longer than a block (hashed first) and salts that
      // push the first HMAC message across one or two padding blocks.
      for (final (pwLen, saltLen) in [(0, 0), (8, 16), (63, 51), (64, 52), (65, 55), (200, 120)]) {
        final pw = bytes(pwLen), salt = bytes(saltLen);
        for (final c in [1, 2, 7]) {
          final reference = (PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
                ..init(Pbkdf2Parameters(salt, c, 32)))
              .process(pw);
          expect(Pbkdf2HmacSha256.derive(pw, salt, c), reference,
              reason: 'pw=$pwLen salt=$saltLen c=$c');
        }
      }
    });

    test('is deterministic for the same salt and differs across salts', () {
      final p = _fastParams();
      final a = VaultCrypto.deriveKeyBytes('correct horse', p);
      final b = VaultCrypto.deriveKeyBytes('correct horse', p);
      final c = VaultCrypto.deriveKeyBytes(
          'correct horse', KdfParams(salt: Uint8List(16)..[0] = 1, iterations: 1000));
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('v2 sealing', () {
    final key = VaultCrypto.deriveKey('correct horse', _fastParams());

    test('round-trips, including empty and non-ASCII values', () {
      for (final s in ['hunter2', '', 'senha çãõ 🔑']) {
        final sealed = VaultCrypto.encrypt(s, key, aad: aad);
        expect(VaultCrypto.isV2(sealed), isTrue);
        expect(VaultCrypto.decrypt(sealed, key, aad: aad), s);
      }
    });

    test('uses a fresh nonce for every value', () {
      final a = VaultCrypto.encrypt('same', key, aad: aad);
      final b = VaultCrypto.encrypt('same', key, aad: aad);
      expect(a, isNot(b));
    });

    test('rejects a wrong key', () {
      final sealed = VaultCrypto.encrypt('secret', key, aad: aad);
      final other = VaultCrypto.deriveKey('wrong horse', _fastParams());
      expect(() => VaultCrypto.decrypt(sealed, other, aad: aad),
          throwsA(isA<VaultDecryptionException>()));
    });

    test('rejects a tampered ciphertext', () {
      final sealed = VaultCrypto.encrypt('secret', key, aad: aad);
      final parts = sealed.split(':');
      final body = base64Decode(parts[2])..[0] ^= 0x01;
      final tampered = '${parts[0]}:${parts[1]}:${base64Encode(body)}';
      expect(() => VaultCrypto.decrypt(tampered, key, aad: aad),
          throwsA(isA<VaultDecryptionException>()));
    });

    test('rejects a value moved to another user or field', () {
      final sealed = VaultCrypto.encrypt('secret', key, aad: aad);
      expect(
          () => VaultCrypto.decrypt(sealed, key,
              aad: VaultCrypto.aad('someone-else', 'credential-password')),
          throwsA(isA<VaultDecryptionException>()));
      expect(
          () => VaultCrypto.decrypt(sealed, key,
              aad: VaultCrypto.aad(uid, 'verification')),
          throwsA(isA<VaultDecryptionException>()));
    });

    test('rejects malformed and legacy-format input', () {
      for (final bad in ['v2:', 'v2:abc', 'v2:!!:!!', 'aXY=:Y3Q=']) {
        expect(() => VaultCrypto.decrypt(bad, key, aad: aad),
            throwsA(isA<VaultDecryptionException>()));
      }
    });
  });

  group('legacy migration', () {
    // Produced by the previous EncryptionService (encrypt 5.0.3, AES-CBC,
    // key = master key padded with '0' to 32 chars) for master key "masterkey1".
    const legacyMasterKey = 'masterkey1';
    const legacyPlain = 'MASTER_KEY_VERIFICATION_2024';
    const legacySealed = 'IXp7ZzQQSqi5lWKnl2nUGg==:wihuDzFenfAfuuzG3dV8ae366MX3hUPovBNXWJTzR/U=';

    test('decrypts values written by the old scheme', () {
      expect(VaultCrypto.legacyDecrypt(legacySealed, legacyMasterKey), legacyPlain);
      expect(VaultCrypto.legacyDecrypt('', legacyMasterKey), '');
    });

    test('rejects the wrong master key', () {
      expect(() => VaultCrypto.legacyDecrypt(legacySealed, 'not-the-key'),
          throwsA(isA<VaultDecryptionException>()));
    });
  });

  group('KDF parameters from storage', () {
    test('round-trip through JSON', () {
      final p = KdfParams.generate();
      final back = KdfParams.fromJson(Map<String, dynamic>.from(p.toJson()));
      expect(back.salt, p.salt);
      expect(back.iterations, KdfParams.defaultIterations);
    });

    test('refuse a downgraded iteration count or unknown algorithm', () {
      final salt = base64Encode(Uint8List(16));
      expect(() => KdfParams.fromJson({'alg': KdfParams.algorithm, 'salt': salt, 'iterations': 1000}),
          throwsFormatException);
      expect(() => KdfParams.fromJson({'alg': 'md5', 'salt': salt, 'iterations': 600000}),
          throwsFormatException);
    });
  });

  test('VaultKey never prints its bytes', () {
    expect(VaultKey(Uint8List(32)).toString(), 'VaultKey(<redacted>)');
  });
}
