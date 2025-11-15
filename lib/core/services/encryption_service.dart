// lib/core/services/encryption_service.dart

import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // Prepara a chave de 32 bytes (necessária para AES-256)
  enc.Key _prepareKey(String masterKey) {
    String keyString = masterKey.padRight(32, '0').substring(0, 32);
    return enc.Key.fromUtf8(keyString);
  }

  /// Criptografa o texto usando AES-256 com um IV aleatório
  String encrypt(String plainText, String masterKey) {
    if (plainText.isEmpty) return '';
    try {
      final key = _prepareKey(masterKey);
      
      // 1. GERA UM IV ALEATÓRIO E SEGURO (16 bytes para AES)
      final iv = enc.IV.fromSecureRandom(16);
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // 2. RETORNA O IV JUNTO COM A SENHA, SEPARADOS POR UM ':'
      //    (Base64 é seguro para salvar no Firestore)
      return '${iv.base64}:${encrypted.base64}';
      
    } catch (e) {
      throw Exception('Erro ao criptografar: $e');
    }
  }

  /// Descriptografa o texto
  String decrypt(String encryptedData, String masterKey) {
    if (encryptedData.isEmpty) return '';
    try {
      final key = _prepareKey(masterKey);
      
      // 1. SEPARA O IV DO TEXTO CRIPTOGRAFADO
      final parts = encryptedData.split(':');
      if (parts.length != 2) throw Exception('Formato de dados inválido.');
      
      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedBase64 = parts[1];
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(
        enc.Encrypted.fromBase64(encryptedBase64),
        iv: iv, // 2. USA O IV QUE VEIO DO FIRESTORE
      );
      return decrypted;
      
    } catch (e) {
      // Se a chave-mestra estiver errada, a descriptografia falha
      throw Exception('Chave-mestra incorreta ou dados corrompidos');
    }
  }
}