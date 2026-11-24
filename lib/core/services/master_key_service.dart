
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:atividade_01/core/crypto/vault_crypto.dart';

/// Creates and unlocks the vault.
///
/// `users/{uid}` holds the KDF parameters (salt, iterations) and a sealed
/// verification value. The master key itself is never stored or sent anywhere;
/// only the derived [VaultKey] leaves this service.
class MasterKeyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _verificationText = 'MASTER_KEY_VERIFICATION_2024';
  static const String _verificationPurpose = 'verification';
  static const String passwordPurpose = 'credential-password';

  /// Firestore batches accept at most 500 writes; one goes to the user doc.
  static const int _maxMigratedCredentials = 499;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado.');
    return uid;
  }

  /// Sets up a new vault and returns its key.
  Future<VaultKey> createVault(String masterKey) async {
    final uid = _requireUid();
    final params = KdfParams.generate();
    final key = await _deriveInBackground(masterKey, params);
    await _firestore.collection('users').doc(uid).set({
      'kdf': params.toJson(),
      'verification': VaultCrypto.encrypt(
        _verificationText,
        key,
        aad: VaultCrypto.aad(uid, _verificationPurpose),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return key;
  }

  /// Returns the vault key, or `null` when the master key is wrong.
  /// Vaults created before the `v2` format are migrated on first unlock.
  Future<VaultKey?> unlock(String masterKey) async {
    final uid = _requireUid();
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento de verificação não encontrado.');
    }
    final verification = data['verification'] as String?;
    if (verification == null) {
      throw Exception('Dados de verificação ausentes.');
    }

    final kdf = data['kdf'];
    if (kdf is Map<String, dynamic>) {
      final key = await _deriveInBackground(masterKey, KdfParams.fromJson(kdf));
      try {
        final plain = VaultCrypto.decrypt(verification, key,
            aad: VaultCrypto.aad(uid, _verificationPurpose));
        return plain == _verificationText ? key : null;
      } on VaultDecryptionException {
        return null;
      }
    }

    // Legacy vault: check the master key with the old scheme, then migrate.
    try {
      if (VaultCrypto.legacyDecrypt(verification, masterKey) != _verificationText) {
        return null;
      }
    } on VaultDecryptionException {
      return null;
    }
    return _migrateLegacyVault(uid, userRef, masterKey);
  }

  /// Re-encrypts the verification value and every credential with the v2
  /// scheme in one atomic batch, so the vault is never left half-migrated.
  Future<VaultKey> _migrateLegacyVault(
    String uid,
    DocumentReference<Map<String, dynamic>> userRef,
    String masterKey,
  ) async {
    final credentials = await userRef.collection('credentials').get();
    if (credentials.docs.length > _maxMigratedCredentials) {
      throw Exception(
          'Cofre com mais de $_maxMigratedCredentials credenciais: migração não suportada.');
    }
    final params = KdfParams.generate();
    final key = await _deriveInBackground(masterKey, params);
    final passwordAad = VaultCrypto.aad(uid, passwordPurpose);

    final batch = _firestore.batch();
    for (final doc in credentials.docs) {
      final sealed = doc.data()['password'] as String? ?? '';
      if (VaultCrypto.isV2(sealed)) continue;
      String plain;
      try {
        plain = VaultCrypto.legacyDecrypt(sealed, masterKey);
      } on VaultDecryptionException {
        continue; // unreadable before the migration; leave it untouched
      }
      batch.update(doc.reference, {
        'password': VaultCrypto.encrypt(plain, key, aad: passwordAad),
      });
    }
    batch.update(userRef, {
      'kdf': params.toJson(),
      'verification': VaultCrypto.encrypt(
        _verificationText,
        key,
        aad: VaultCrypto.aad(uid, _verificationPurpose),
      ),
    });
    await batch.commit();
    return key;
  }

  Future<VaultKey> _deriveInBackground(String masterKey, KdfParams params) async {
    final bytes = await compute(_deriveKey, _DeriveRequest(masterKey, params));
    return VaultKey(bytes);
  }
}

class _DeriveRequest {
  final String masterKey;
  final KdfParams params;
  const _DeriveRequest(this.masterKey, this.params);
}

Uint8List _deriveKey(_DeriveRequest request) =>
    VaultCrypto.deriveKeyBytes(request.masterKey, request.params);
