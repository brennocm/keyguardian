import 'package:cloud_firestore/cloud_firestore.dart';

class CredentialModel {
  final String? id; // O ID do documento no Firestore
  final String title;
  final String username;
  final String password; // O BLoC passará a senha Criptografada para cá
  final String category; // Para o requisito de "imagem com sentido"
  final String websiteUrl; // Opcional, mas útil

  CredentialModel({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.category,
    this.websiteUrl = '',
  });

  // Converte um objeto CredentialModel para um Map (para enviar ao Firestore)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'username': username,
      'password': password,
      'category': category,
      'websiteUrl': websiteUrl,
    };
  }

  // Converte um DocumentSnapshot (vindo do Firestore) para um CredentialModel
  factory CredentialModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CredentialModel(
      id: doc.id, // Pega o ID do documento
      title: data['title'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      category: data['category'] ?? 'Outro',
      websiteUrl: data['websiteUrl'] ?? '',
    );
  }
}