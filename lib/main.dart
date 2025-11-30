import 'package:flutter/material.dart';
import 'package:atividade_01/features/auth/view/welcome_screen.dart';
import 'package:atividade_01/features/master_key/view/master_key_screen.dart'; 
import 'package:atividade_01/features/auth/auth_controller.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        fontFamily: 'Sans-serif',
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF333333),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

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
          return const MasterKeyScreen();
        }

        // Se o usuário está DESLOGADO
        return const WelcomeScreen(); 
      },
    );
  }
}