// lib/features/auth/auth_controller.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  // Instância principal do Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STREAMS ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- GETTERS ---
  User? get currentUser => _auth.currentUser;

  // --- MÉTODOS DE AUTENTICAÇÃO ---

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- MÉTODOS DE PERFIL (NOVOS) ---

  /// Reautentica o usuário com a senha atual.
  /// (Necessário para operações sensíveis como trocar senha)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("Usuário não encontrado ou e-mail inválido.");
      }

      // Cria a credencial com a senha antiga
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      // Reautentica
      await user.reauthenticateWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e); // Reutiliza seu helper de erro
    }
  }

  /// Atualiza a senha de usuário do Firebase
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e); // Reutiliza seu helper de erro
    }
  }


  // --- TRATAMENTO DE ERROS ---

  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'A senha fornecida é muito fraca.';
        break;
      case 'email-already-in-use':
        message = 'Já existe uma conta para este e-mail.';
        break;
      case 'user-not-found':
        message = 'Nenhum usuário encontrado para este e-mail.';
        break;
      case 'wrong-password':
        message = 'Senha incorreta.';
        break;
      case 'invalid-email':
        message = 'O formato do e-mail é inválido.';
        break;
      case 'network-request-failed':
        message = 'Sem conexão com a internet.';
        break;
      // NOVO: Adiciona erro de reautenticação
      case 'requires-recent-login':
        message = 'Esta operação é sensível e requer login recente. Tente novamente.';
        break;
      default:
        message = 'Ocorreu um erro. Tente novamente.';
    }
    return Exception(message);
  }
}