import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as enc; // Damos um apelido para não conflitar

// 1. O MODELO DE DADOS
class PasswordEntry {
  final String id; 
  final String title;
  final String url;
  final String username;
  final String encryptedPassword; 

  PasswordEntry({
    required this.id,
    required this.title,
    required this.url,
    required this.username,
    required this.encryptedPassword,
  });

  // Converte um "snapshot" do Firestore em um objeto PasswordEntry
  factory PasswordEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PasswordEntry(
      id: doc.id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      username: data['username'] ?? '',
      encryptedPassword: data['encryptedPassword'] ?? '',
    );
  }

  // Converte um objeto PasswordEntry em um Map para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'url': url,
      'username': username,
      'encryptedPassword': encryptedPassword,
    };
  }
}

// 2. O CONTROLADOR DO BANCO DE DADOS
class DatabaseController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- CORREÇÃO AQUI ---
  // Pega o App ID usando a sintaxe Dart correta
  final String _appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
  // --- FIM DA CORREÇÃO ---

  // --- SERVIÇO DE CRIPTOGRAFIA INTERNO ---
  
  // Prepara a chave de 32 bytes (necessária para AES-256)
  enc.Key _prepareKey(String masterKey) {
    String keyString = masterKey.padRight(32, '0').substring(0, 32);
    return enc.Key.fromUtf8(keyString);
  }

  // O IV (Vetor de Inicialização) é necessário para o AES.
  final enc.IV _iv = enc.IV.fromUtf8("0123456789ABCDEF");

  // Criptografa o texto
  String encrypt(String plainText, String masterKey) {
    if (plainText.isEmpty) return '';
    final key = _prepareKey(masterKey);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64; // Salva como texto Base64
  }

  // Descriptografa o texto
  String decrypt(String encryptedBase64, String masterKey) {
    if (encryptedBase64.isEmpty) return '';
    try {
      final key = _prepareKey(masterKey);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(enc.Encrypted.fromBase64(encryptedBase64), iv: _iv);
      return decrypted;
    } catch (e) {
      // Se a chave-mestra estiver errada, a descriptografia falha!
      print("Erro ao descriptografar (Chave-Mestra errada?): $e");
      return "******"; // Retorna censurado se a chave estiver errada
    }
  }

  // --- OPERAÇÕES DO BANCO DE DADOS (CRUD) ---

  // Caminho seguro para os dados privados do usuário
  CollectionReference<PasswordEntry> _getCredentialsCollection() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não está logado.");

    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('credentials')
        .withConverter<PasswordEntry>(
          fromFirestore: (snapshot, _) => PasswordEntry.fromFirestore(snapshot),
          toFirestore: (entry, _) => entry.toFirestore(),
        );
  }

  // Pegar (GET) todas as senhas
  Stream<List<PasswordEntry>> getCredentialsStream() {
    return _getCredentialsCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Adicionar (ADD) uma nova senha
  Future<void> addCredential({
    required String title,
    required String url,
    required String username,
    required String plainTextPassword,
    required String masterKey,
  }) async {
    final encryptedPassword = encrypt(plainTextPassword, masterKey);
    
    await _getCredentialsCollection().add(
      PasswordEntry(
        id: '', // O Firestore vai gerar o ID
        title: title,
        url: url,
        username: username,
        encryptedPassword: encryptedPassword,
      )
    );
  }

  // Atualizar (UPDATE) uma senha
  Future<void> updateCredential({
    required String docId,
    required String title,
    required String url,
    required String username,
    required String plainTextPassword,
    required String masterKey,
  }) async {
    final encryptedPassword = encrypt(plainTextPassword, masterKey);
    
     await _getCredentialsCollection().doc(docId).update({
      'title': title,
      'url': url,
      'username': username,
      'encryptedPassword': encryptedPassword,
    });
  }

  // Deletar (DELETE) uma senha
  Future<void> deleteCredential(String docId) async {
    await _getCredentialsCollection().doc(docId).delete();
  }
}