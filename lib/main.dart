import 'package:flutter/material.dart';
import 'package:atividade_01/features/1_auth/view/welcome_screen.dart'; // Você já tem
import 'package:atividade_01/features/2_credentials/view/home_screen.dart'; // Você já tem
import 'model/auth_controller.dart'; // Usando seu caminho
import 'package:firebase_core/firebase_core.dart'; // Importe este
import 'firebase_options.dart'; // Importe o arquivo que acabou de ser criado
import 'package:firebase_auth/firebase_auth.dart'; // Importe este

// 1. Torne o main assíncrono
void main() async {
  // 2. Garanta que o Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Inicialize o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Rode o app
  runApp(const KeyGuardianApp());
}

class KeyGuardianApp extends StatelessWidget {
  const KeyGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyGuardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ... seu tema
        fontFamily: 'Sans-serif',
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF333333),
          ),
        ),
      ),
      // 5. Use o AuthGate para decidir a tela inicial
      home: const AuthGate(),
    );
  }
}

// 6. Adicione este widget de "Portão de Autenticação" no final do arquivo
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController(); // Instancia seu controller

    return StreamBuilder<User?>(
      stream: authController.authStateChanges, // Ouve as mudanças de login
      builder: (context, snapshot) {
        // Adicionando um check de conexão
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o usuário está LOGADO
        if (snapshot.hasData) {
          // --- ESTA É A CORREÇÃO ---
          // Em vez de ir para a HomeScreen, vá para a MasterKeyScreen
          // para "destrancar" o cofre.
          return const MasterKeyScreen();
        }

        // Se o usuário está DESLOGADO
        return const WelcomeScreen(); // Vai para a tela de boas-vindas
      },
    );
  }
}