import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  enc.Key _prepareKey(String masterKey) {
    String keyString = masterKey.padRight(32, '0').substring(0, 32);
    return enc.Key.fromUtf8(keyString);
  }

  String encrypt(String plainText, String masterKey) {
    if (plainText.isEmpty) return '';
    try {
      final key = _prepareKey(masterKey);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      return '${iv.base64}:${encrypted.base64}';
      
    } catch (e) {
      throw Exception('Erro ao criptografar: $e');
    }
  }

  String decrypt(String encryptedData, String masterKey) {
    if (encryptedData.isEmpty) return '';
    try {
      final key = _prepareKey(masterKey);
      final parts = encryptedData.split(':');

      if (parts.length != 2) throw Exception('Formato de dados inválido.');
      
      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedBase64 = parts[1];
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(
        enc.Encrypted.fromBase64(encryptedBase64),
        iv: iv, 
      );
      return decrypted;
      
    } catch (e) {
      throw Exception('Chave-mestra incorreta ou dados corrompidos');
    }
  }
}