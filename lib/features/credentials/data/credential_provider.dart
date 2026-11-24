import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atividade_01/core/models/credential_model.dart';
import 'package:atividade_01/core/crypto/vault_crypto.dart';
import 'package:atividade_01/core/services/master_key_service.dart';

class CredentialProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _getUserId() {
    final User? user = _auth.currentUser;
    return user?.uid;
  }

  /// Binds each sealed password to its owner, so it cannot be moved elsewhere.
  String _passwordAad() =>
      VaultCrypto.aad(_getUserId() ?? '', MasterKeyService.passwordPurpose);

  CollectionReference<Map<String, dynamic>>? _getCredentialsCollection() {
    final userId = _getUserId();
    if (userId == null) {
      return null;
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('credentials');
  }

  /// CREATE: Adiciona uma nova credencial criptografada
  Future<void> addCredential(CredentialModel credential, VaultKey vaultKey) async {
    try {
      final collection = _getCredentialsCollection();
      if (collection == null) throw Exception("Usuário não logado.");
      
      // Criptografa a senha antes de salvar
      final encryptedPassword = VaultCrypto.encrypt(
        credential.password,
        vaultKey,
        aad: _passwordAad(),
      );
      
      // Cria uma nova credencial com a senha criptografada
      final encryptedCredential = CredentialModel(
        id: credential.id,
        title: credential.title,
        username: credential.username,
        password: encryptedPassword,
        category: credential.category,
        websiteUrl: credential.websiteUrl,
      );
      
      await collection.add(encryptedCredential.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// READ: Retorna as credenciais descriptografadas em tempo real
  Stream<List<CredentialModel>> getCredentials(VaultKey vaultKey) {
    final collection = _getCredentialsCollection();
    if (collection == null) {
      return Stream.value([]);
    }

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final credential = CredentialModel.fromFirestore(doc);
        
        // Descriptografa a senha
        try {
          final decryptedPassword = VaultCrypto.decrypt(
            credential.password,
            vaultKey,
            aad: _passwordAad(),
          );
          
          return CredentialModel(
            id: credential.id,
            title: credential.title,
            username: credential.username,
            password: decryptedPassword,
            category: credential.category,
            websiteUrl: credential.websiteUrl,
          );
        } catch (e) {
          // Se a descriptografia falhar, retorna com senha censurada
          return CredentialModel(
            id: credential.id,
            title: credential.title,
            username: credential.username,
            password: '******',
            category: credential.category,
            websiteUrl: credential.websiteUrl,
          );
        }
      }).toList();
    });
  }

  /// UPDATE: Atualiza uma credencial criptografada
  Future<void> updateCredential(CredentialModel credential, VaultKey vaultKey) async {
    try {
      final collection = _getCredentialsCollection();
      if (collection == null) throw Exception("Usuário não logado.");
      
      if (credential.id == null) throw Exception("ID da credencial é nulo.");

      // Criptografa a senha antes de atualizar
      final encryptedPassword = VaultCrypto.encrypt(
        credential.password,
        vaultKey,
        aad: _passwordAad(),
      );
      
      final encryptedCredential = CredentialModel(
        id: credential.id,
        title: credential.title,
        username: credential.username,
        password: encryptedPassword,
        category: credential.category,
        websiteUrl: credential.websiteUrl,
      );

      await collection.doc(credential.id).update(encryptedCredential.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE: Remove uma credencial
  Future<void> deleteCredential(String credentialId) async {
    try {
      final collection = _getCredentialsCollection();
      if (collection == null) throw Exception("Usuário não logado.");

      await collection.doc(credentialId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
