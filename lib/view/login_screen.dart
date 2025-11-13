import 'package:flutter/material.dart';
// 1. Importe seu controlador
import '../model/auth_controller.dart';
// A MasterKeyScreen não é mais chamada aqui, o AuthGate vai cuidar disso
// import 'master_key_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 2. Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 3. Instância do AuthController
  final _authController = AuthController();

  // 4. Variáveis de estado da UI
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 5. Função para lidar com o login
  Future<void> _handleLogin() async {
    // Inicia o loading
    setState(() {
      _isLoading = true;
    });

    try {
      // 6. Chama o método de login do controller
      await _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 7. Sucesso! O AuthGate vai navegar para a HomeScreen.
      // Apenas fechamos a tela de login.
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 8. Se der erro, mostre o snackbar
      _showErrorSnackbar(e.toString());
    }

    // Para o loading
    setState(() {
      _isLoading = false;
    });
  }

  // Helper para mostrar erros
  void _showErrorSnackbar(String message) {
    final displayMessage = message.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/icon-without-name.png',
              height: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Entre em sua conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              'E-mail',
              style: TextStyle(
                color: Color(0xFF212121),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // --- CAMPO DE E-MAIL ATUALIZADO ---
            TextField(
              controller: _emailController, // Conectado
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF212121), width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF212121), width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF212121), width: 2.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Senha',
              style: TextStyle(
                color: Color(0xFF212121),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // --- CAMPO DE SENHA ATUALIZADO ---
            TextField(
              controller: _passwordController, // Conectado
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF212121), width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF212121), width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF212121), width: 2.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined // Inverti os ícones
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // --- BOTÃO ATUALIZADO ---
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin, // Conectado
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF212121),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Próximo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}