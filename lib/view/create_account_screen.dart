import 'package:flutter/material.dart';
// 1. Importe seu controlador de autenticação
import '../model/auth_controller.dart'; 

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // 2. Crie os controladores de texto para ler os campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 3. Crie uma instância do seu AuthController
  final _authController = AuthController();

  // 4. Variáveis de estado da UI
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false; // Para controlar o "carregando"

  // 5. Limpe os controladores quando a tela for fechada
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 6. Função principal para lidar com a criação da conta
  Future<void> _handleCreateAccount() async {
    // Validação simples
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('As senhas não coincidem.');
      return;
    }

    // Inicia o loading
    setState(() {
      _isLoading = true;
    });

    try {
      // 7. Chama o método do seu controller!
      await _authController.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 8. Sucesso! O AuthGate vai lidar com a navegação para a HomeScreen
      //    automaticamente. Nós só precisamos fechar esta tela.
      if (mounted) {
        // Volta para a WelcomeScreen (e o AuthGate vai agir)
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      // 9. Se der erro, mostre o snackbar
      _showErrorSnackbar(e.toString());
    }

    // Para o loading, independentemente de sucesso ou erro
    setState(() {
      _isLoading = false;
    });
  }

  // Helper para mostrar mensagens de erro
  void _showErrorSnackbar(String message) {
    // Remove "Exception: " da mensagem
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/icon-without-name.png',
                  height: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 40),
                
                // --- CAMPO DE E-MAIL ATUALIZADO ---
                _buildTextField(
                  label: 'E-mail',
                  controller: _emailController, // Conectado
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 20),
                
                // --- CAMPO DE SENHA ATUALIZADO ---
                _buildPasswordField(
                  label: 'Senha',
                  controller: _passwordController, // Conectado
                  isObscured: _isPasswordObscured,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // --- CAMPO DE REPETIR SENHA ATUALIZADO ---
                _buildPasswordField(
                  label: 'Repita a senha',
                  controller: _confirmPasswordController, // Conectado
                  isObscured: _isConfirmPasswordObscured,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  },
                ),
                
                const SizedBox(height: 40),
                
                // --- BOTÃO ATUALIZADO ---
                ElevatedButton(
                  // Desabilita o botão se estiver carregando
                  onPressed: _isLoading ? null : _handleCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF212121),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox( // Mostra o "loading"
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text( // Mostra o texto normal
                          'Próximo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET ATUALIZADO PARA ACEITAR UM CONTROLLER ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Conectado
          keyboardType: keyboardType,
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
      ],
    );
  }

  // --- WIDGET ATUALIZADO PARA ACEITAR UM CONTROLLER ---
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Conectado
          obscureText: isObscured,
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
                  isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}