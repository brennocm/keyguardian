import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Pure-Dart vault cryptography (no Flutter imports, so it is unit-testable).
///
/// Scheme (format `v2`):
/// * The vault key is derived from the master key with PBKDF2-HMAC-SHA256,
///   a random 16-byte per-user salt and [KdfParams.defaultIterations].
/// * Each value is sealed with AES-256-GCM: random 96-bit nonce, 128-bit tag,
///   and associated data that binds the ciphertext to its owner and purpose,
///   so a ciphertext cannot be swapped into another user's or field's slot.
/// * Stored as `v2:<base64 nonce>:<base64 ciphertext||tag>`.
///
/// The previous scheme (AES-CBC, key = master key padded with '0', no MAC) is
/// kept only in [VaultCrypto.legacyDecrypt] to migrate existing vaults.
class VaultCrypto {
  VaultCrypto._();

  static const String _v2Prefix = 'v2:';
  static const int _nonceLength = 12;
  static const int _tagBits = 128;
  static const int keyLength = 32;

  static final Random _random = Random.secure();

  static Uint8List randomBytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => _random.nextInt(256)));

  /// Derives the 256-bit vault key. Slow on purpose: run it off the UI thread.
  static Uint8List deriveKeyBytes(String masterKey, KdfParams params) =>
      Pbkdf2HmacSha256.derive(
          Uint8List.fromList(utf8.encode(masterKey)), params.salt, params.iterations);

  static VaultKey deriveKey(String masterKey, KdfParams params) =>
      VaultKey(deriveKeyBytes(masterKey, params));

  /// Associated data for a sealed value. [purpose] names the field, e.g.
  /// `verification` or `credential-password`.
  static String aad(String userId, String purpose) =>
      'keyguardian:v2:$userId:$purpose';

  static String encrypt(String plainText, VaultKey key, {required String aad}) {
    final nonce = randomBytes(_nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key.bytes), _tagBits, nonce,
          Uint8List.fromList(utf8.encode(aad))));
    final sealed = cipher.process(Uint8List.fromList(utf8.encode(plainText)));
    return '$_v2Prefix${base64Encode(nonce)}:${base64Encode(sealed)}';
  }

  /// Throws [VaultDecryptionException] on a wrong key, a tampered value, a
  /// mismatched [aad] or an unknown format.
  static String decrypt(String data, VaultKey key, {required String aad}) {
    if (data.isEmpty) return ''; // legacy vaults stored empty values as ''
    if (!data.startsWith(_v2Prefix)) {
      throw const VaultDecryptionException('Unsupported or legacy format');
    }
    final parts = data.substring(_v2Prefix.length).split(':');
    if (parts.length != 2) {
      throw const VaultDecryptionException('Malformed value');
    }
    try {
      final nonce = base64Decode(parts[0]);
      final sealed = base64Decode(parts[1]);
      if (nonce.length != _nonceLength) {
        throw const VaultDecryptionException('Malformed nonce');
      }
      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key.bytes), _tagBits, nonce,
            Uint8List.fromList(utf8.encode(aad))));
      return utf8.decode(cipher.process(sealed));
    } on VaultDecryptionException {
      rethrow;
    } catch (_) {
      throw const VaultDecryptionException('Wrong key or tampered data');
    }
  }

  static bool isV2(String data) => data.startsWith(_v2Prefix);

  /// Decrypts a value written by the old scheme. Migration only.
  static String legacyDecrypt(String data, String masterKey) {
    if (data.isEmpty) return '';
    final parts = data.split(':');
    if (parts.length != 2) {
      throw const VaultDecryptionException('Malformed legacy value');
    }
    try {
      final keyBytes = Uint8List.fromList(
          utf8.encode(masterKey.padRight(32, '0').substring(0, 32)));
      final cipher = PaddedBlockCipherImpl(
          PKCS7Padding(), CBCBlockCipher(AESEngine()))
        ..init(
            false,
            PaddedBlockCipherParameters<CipherParameters, CipherParameters?>(
                ParametersWithIV<KeyParameter>(
                    KeyParameter(keyBytes), base64Decode(parts[0])),
                null));
      return utf8.decode(cipher.process(base64Decode(parts[1])));
    } catch (_) {
      throw const VaultDecryptionException('Wrong key or corrupted legacy data');
    }
  }
}

/// KDF settings stored next to the vault. Not secret.
class KdfParams {
  static const String algorithm = 'pbkdf2-hmac-sha256';

  /// OWASP Password Storage Cheat Sheet value for PBKDF2-HMAC-SHA256.
  static const int defaultIterations = 600000;

  /// Refuse weaker settings read from the database, so whoever can write the
  /// user document cannot downgrade the KDF to speed up guessing.
  static const int minIterations = 600000;

  final Uint8List salt;
  final int iterations;

  const KdfParams({required this.salt, required this.iterations});

  factory KdfParams.generate({int iterations = defaultIterations}) =>
      KdfParams(salt: VaultCrypto.randomBytes(16), iterations: iterations);

  Map<String, Object> toJson() => {
        'alg': algorithm,
        'salt': base64Encode(salt),
        'iterations': iterations,
      };

  factory KdfParams.fromJson(Map<String, dynamic> json) {
    if (json['alg'] != algorithm) {
      throw FormatException('Unsupported KDF: ${json['alg']}');
    }
    final iterations = json['iterations'];
    if (iterations is! int || iterations < minIterations) {
      throw const FormatException('KDF iteration count below the minimum');
    }
    final salt = base64Decode(json['salt'] as String);
    if (salt.length < 16) {
      throw const FormatException('KDF salt too short');
    }
    return KdfParams(salt: salt, iterations: iterations);
  }
}

/// The derived 256-bit vault key. Never printed.
class VaultKey {
  final Uint8List bytes;

  VaultKey(this.bytes) {
    if (bytes.length != VaultCrypto.keyLength) {
      throw ArgumentError('Vault key must be ${VaultCrypto.keyLength} bytes');
    }
  }

  @override
  String toString() => 'VaultKey(<redacted>)';
}

class VaultDecryptionException implements Exception {
  final String message;
  const VaultDecryptionException(this.message);

  @override
  String toString() => 'VaultDecryptionException: $message';
}

/// PBKDF2-HMAC-SHA256 producing one 32-byte block (RFC 8018).
///
/// pointycastle's generic HMAC re-hashes both pads on every iteration and
/// allocates per call, which made 600k iterations take ~7 s on a desktop CPU.
/// Here the ipad/opad states are computed once and every iteration is exactly
/// two SHA-256 compressions on preallocated word buffers. Verified against the
/// RFC 7914 vectors and against pointycastle in test/vault_crypto_test.dart.
class Pbkdf2HmacSha256 {
  Pbkdf2HmacSha256._();

  static Uint8List derive(Uint8List password, Uint8List salt, int iterations) {
    if (iterations < 1) throw ArgumentError('iterations must be >= 1');
    var key = password;
    if (key.length > 64) key = SHA256Digest().process(key);
    final ipad = Uint8List(64), opad = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      final k = i < key.length ? key[i] : 0;
      ipad[i] = k ^ 0x36;
      opad[i] = k ^ 0x5c;
    }
    final w = Uint32List(64);
    final inner = Uint32List.fromList(_iv);
    final outer = Uint32List.fromList(_iv);
    _compress(inner, _words(ipad, 0), w);
    _compress(outer, _words(opad, 0), w);

    // U1 = HMAC(P, S || INT(1)): the message has arbitrary length.
    final msg = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..[salt.length + 3] = 1;
    final u = Uint32List(8);
    _hmacGeneric(inner, outer, msg, u, w);
    final t = Uint32List.fromList(u);

    // U2..Uc: the message is the previous 32-byte U, so each hash is one block.
    final block = Uint32List(16);
    final st = Uint32List(8);
    for (var j = 1; j < iterations; j++) {
      // inner = SHA256(ipadState, U || pad) ; total length (64 + 32) bytes
      block.setAll(0, u);
      block[8] = 0x80000000;
      for (var i = 9; i < 15; i++) {
        block[i] = 0;
      }
      block[15] = (64 + 32) * 8;
      st.setAll(0, inner);
      _compress(st, block, w);
      // outer = SHA256(opadState, inner || pad)
      block.setAll(0, st);
      st.setAll(0, outer);
      _compress(st, block, w);
      for (var i = 0; i < 8; i++) {
        u[i] = st[i];
        t[i] ^= st[i];
      }
    }
    final out = Uint8List(32);
    for (var i = 0; i < 8; i++) {
      out[i * 4] = t[i] >> 24;
      out[i * 4 + 1] = (t[i] >> 16) & 0xff;
      out[i * 4 + 2] = (t[i] >> 8) & 0xff;
      out[i * 4 + 3] = t[i] & 0xff;
    }
    return out;
  }

  /// HMAC over an arbitrary message, starting from precomputed pad states.
  static void _hmacGeneric(Uint32List inner, Uint32List outer, Uint8List msg,
      Uint32List out, Uint32List w) {
    final st = Uint32List.fromList(inner);
    _hashTail(st, msg, 64, w);
    final block = Uint32List(16)..setAll(0, st);
    block[8] = 0x80000000;
    block[15] = (64 + 32) * 8;
    out.setAll(0, outer);
    _compress(out, block, w);
  }

  /// Finishes SHA-256 of `prefixLen` already-compressed bytes followed by [data].
  static void _hashTail(Uint32List st, Uint8List data, int prefixLen, Uint32List w) {
    final total = prefixLen + data.length;
    final padded = Uint8List(((data.length + 9 + 63) ~/ 64) * 64)
      ..setAll(0, data)
      ..[data.length] = 0x80;
    final bits = total * 8;
    final n = padded.length;
    for (var i = 0; i < 8; i++) {
      padded[n - 1 - i] = (bits >> (8 * i)) & 0xff;
    }
    for (var off = 0; off < n; off += 64) {
      _compress(st, _words(padded, off), w);
    }
  }

  static Uint32List _words(Uint8List b, int off) {
    final out = Uint32List(16);
    for (var i = 0; i < 16; i++) {
      final p = off + i * 4;
      out[i] = (b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3];
    }
    return out;
  }

  static const List<int> _iv = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  static final Uint32List _k = Uint32List.fromList(const [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ]);

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

  /// One SHA-256 compression of a 16-word [block] into [st].
  static void _compress(Uint32List st, Uint32List block, Uint32List w) {
    for (var i = 0; i < 16; i++) {
      w[i] = block[i];
    }
    for (var i = 16; i < 64; i++) {
      final x = w[i - 15], y = w[i - 2];
      final s0 = _rotr(x, 7) ^ _rotr(x, 18) ^ (x >> 3);
      final s1 = _rotr(y, 17) ^ _rotr(y, 19) ^ (y >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }
    var a = st[0], b = st[1], c = st[2], d = st[3];
    var e = st[4], f = st[5], g = st[6], h = st[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e) & 0xffffffff & g);
      final t1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & 0xffffffff;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xffffffff;
    }
    st[0] = (st[0] + a) & 0xffffffff;
    st[1] = (st[1] + b) & 0xffffffff;
    st[2] = (st[2] + c) & 0xffffffff;
    st[3] = (st[3] + d) & 0xffffffff;
    st[4] = (st[4] + e) & 0xffffffff;
    st[5] = (st[5] + f) & 0xffffffff;
    st[6] = (st[6] + g) & 0xffffffff;
    st[7] = (st[7] + h) & 0xffffffff;
  }
}
