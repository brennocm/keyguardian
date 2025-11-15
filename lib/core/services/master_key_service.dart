import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atividade_01/core/services/encryption_service.dart';

class MasterKeyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService();
  static const String _verificationText = 'MASTER_KEY_VERIFICATION_2024';
  Future<void> createVerificationDocument(String masterKey) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("Usuário não logado.");
      final encryptedVerification = _encryptionService.encrypt(
        _verificationText,
        masterKey,
      );
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

  Future<bool> validateMasterKey(String masterKey) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
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

      final decrypted = _encryptionService.decrypt(
        encryptedVerification,
        masterKey,
      );
      return decrypted == _verificationText;
    } catch (e) {
      return false;
    }
  }
}