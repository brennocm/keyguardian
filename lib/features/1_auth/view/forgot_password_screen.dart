import 'package:flutter/material.dart';
// 1. Importe seu controlador
import 'package:atividade_01/model/auth_controller.dart';
// 'login_screen.dart' não é mais necessário aqui

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 2. Controlador de texto
  final _emailController = TextEditingController();

  // 3. Instância do AuthController
  final _authController = AuthController();

  // 4. Variável de estado
  bool _isLoading = false;

  // 5. Função para lidar com a redefinição
  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Por favor, insira seu e-mail.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 6. Chama o método do controller
      await _authController.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      // 7. Sucesso! Mostra uma mensagem e fecha a tela
      _showSuccessSnackbar('E-mail de redefinição enviado com sucesso!');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 8. Erro
      _showErrorSnackbar(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Helper de Erro
  void _showErrorSnackbar(String message) {
    final displayMessage = message.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Helper de Sucesso
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        // ... seu appbar ...
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ... sua imagem e título ...
                const SizedBox(height: 40),
                
                // --- CAMPO DE E-MAIL ATUALIZADO ---
                _buildTextField(
                  label: 'E-mail',
                  controller: _emailController, // Conectado
                  keyboardType: TextInputType.emailAddress,
                ),
                
                // Os campos de senha não são necessários aqui
                // const SizedBox(height: 20),
                // _buildPasswordField(...),
                // const SizedBox(height: 20),
                // _buildPasswordField(...),
                
                const SizedBox(height: 40),
                
                // --- BOTÃO ATUALIZADO ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordReset, // Conectado
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF212121),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
                          'Enviar e-mail de redefinição',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  // --- WIDGET ATUALIZADO ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller, // Adicionado
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
            // ... sua decoração ...
             filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF212121),
                width: 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF212121),
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF212121),
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }

  // O _buildPasswordField não é mais usado nesta tela
}