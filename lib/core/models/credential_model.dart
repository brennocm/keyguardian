import 'package:cloud_firestore/cloud_firestore.dart';

class CredentialModel {
  final String? id; 
  final String title;
  final String username;
  final String password; 
  final String category; 
  final String websiteUrl;

  CredentialModel({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.category,
    this.websiteUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'username': username,
      'password': password,
      'category': category,
      'websiteUrl': websiteUrl,
    };
  }

  factory CredentialModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CredentialModel(
      id: doc.id, 
      title: data['title'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      category: data['category'] ?? 'Outro',
      websiteUrl: data['websiteUrl'] ?? '',
    );
  }
}