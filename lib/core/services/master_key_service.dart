import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atividade_01/core/services/encryption_service.dart';

class MasterKeyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService();

  // Valor fixo usado para verificar se a chave-mestra está correta
  static const String _verificationText = 'MASTER_KEY_VERIFICATION_2024';

  /// Cria o documento de verificação ao criar a conta
  Future<void> createVerificationDocument(String masterKey) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("Usuário não logado.");

      // Criptografa o texto de verificação
      final encryptedVerification = _encryptionService.encrypt(
        _verificationText,
        masterKey,
      );

      // Salva no Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
            'verification': encryptedVerification,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Erro ao criar documento de verificação: $e');
    }
  }

  /// Valida se a chave-mestra está correta
  Future<bool> validateMasterKey(String masterKey) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Busca o documento de verificação
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception('Documento de verificação não encontrado.');
      }

      final data = doc.data()!;
      final encryptedVerification = data['verification'] as String?;

      if (encryptedVerification == null) {
        throw Exception('Dados de verificação ausentes.');
      }

      // Tenta descriptografar
      final decrypted = _encryptionService.decrypt(
        encryptedVerification,
        masterKey,
      );

      // Verifica se o texto descriptografado é o esperado
      return decrypted == _verificationText;
      
    } catch (e) {
      // Qualquer erro de descriptografia significa chave incorreta
      return false;
    }
  }
}