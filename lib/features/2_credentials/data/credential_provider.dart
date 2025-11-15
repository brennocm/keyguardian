import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 1. Importe o modelo que acabamos de criar
import 'package:atividade_01/core/models/credential_model.dart';

class CredentialProvider {
  // 2. Instâncias do Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 3. Helper para pegar o User ID (garante que só pegamos dados do usuário logado)
  String? _getUserId() {
    final User? user = _auth.currentUser;
    return user?.uid;
  }

  // 4. Referência principal para a sub-coleção de credenciais do usuário
  CollectionReference<Map<String, dynamic>>? _getCredentialsCollection() {
    final userId = _getUserId();
    if (userId == null) {
      // Isso não deve acontecer se a UI estiver protegida corretamente
      return null;
    }
    // ESTRUTURA: /users/{userId}/credentials/
    // Isso cumpre o requisito de "Autenticação Significativa"
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('credentials');
  }

  //
  // ====================================================================
  // IMPLEMENTAÇÃO DOS MÉTODOS DE CRUD
  // ====================================================================
  //

  /// CREATE: Adiciona uma nova credencial ao Firestore
  Future<void> addCredential(CredentialModel credential) async {
    try {
      final collection = _getCredentialsCollection();
      if (collection == null) throw Exception("Usuário não logado.");
      
      // O .add() cria um documento com ID automático no Firestore
      await collection.add(credential.toJson());
    } catch (e) {
      // O BLoC (Camada 2) vai tratar esse erro
      rethrow;
    }
  }

  /// READ: Ouve as mudanças na lista de credenciais em tempo real
  Stream<List<CredentialModel>> getCredentials() {
    final collection = _getCredentialsCollection();
    if (collection == null) {
      // Retorna um Stream vazio se o usuário estiver deslogado
      return Stream.value([]);
    }

    // O .snapshots() é o que nos dá o tempo real (Stream)
    return collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CredentialModel.fromFirestore(doc))
          .toList();
    });
  }

  /// UPDATE: Atualiza uma credencial existente
  Future<void> updateCredential(CredentialModel credential) async {
    try {
      final collection = _getCredentialsCollection();
      if (collection == null) throw Exception("Usuário não logado.");
      
      // O credential.id não pode ser nulo para atualizar
      if (credential.id == null) throw Exception("ID da credencial é nulo.");

      // Usa o ID do documento para saber qual item atualizar
      await collection.doc(credential.id).update(credential.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE: Apaga uma credencial do Firestore
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