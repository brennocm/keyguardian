import 'package:firebase_auth/firebase_auth.dart';

// Esta é a classe "Model" (ou Controller) que sua UI vai usar
// para falar com o Firebase.

class AuthController {
  // Instância principal do Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STREAMS ---
  // Um "ouvinte" que avisa o app se o usuário fez login ou logout
  // O AuthGate usa isso.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- GETTERS ---
  // Pega o usuário logado atualmente
  User? get currentUser => _auth.currentUser;

  // --- MÉTODOS DE AUTENTICAÇÃO ---

  // Criar conta (SignUp)
  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Lança a exceção para ser tratada na UI (create_account_screen)
      throw _handleAuthException(e);
    }
  }

  // Fazer login (SignIn)
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Lança a exceção para ser tratada na UI (login_screen)
      throw _handleAuthException(e);
    }
  }

  // Enviar email de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Fazer logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- TRATAMENTO DE ERROS ---

  // Método privado para traduzir os códigos de erro do Firebase
  // para mensagens amigáveis.
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
      default:
        message = 'Ocorreu um erro. Tente novamente.';
    }
    // Retorna uma Exceção padrão com a mensagem tratada
    return Exception(message);
  }
}