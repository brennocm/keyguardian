// lib/features/master_key/view/create_master_key_screen.dart

import 'package:flutter/material.dart';
import 'package:atividade_01/core/services/master_key_service.dart';
import 'package:atividade_01/features/credentials/view/home_screen.dart';

// --- CORREÇÃO: IMPORTS ADICIONADOS ---
import 'package:atividade_01/features/auth/auth_controller.dart';
import 'package:atividade_01/features/auth/view/welcome_screen.dart';

class CreateMasterKeyScreen extends StatefulWidget {
  const CreateMasterKeyScreen({super.key});

  @override
  State<CreateMasterKeyScreen> createState() => _CreateMasterKeyScreenState();
}

class _CreateMasterKeyScreenState extends State<CreateMasterKeyScreen> {
  final _masterKeyController = TextEditingController();
  final _confirmMasterKeyController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final MasterKeyService _masterKeyService = MasterKeyService();
  // --- CORREÇÃO: CONTROLLER ADICIONADO ---
  final AuthController _authController = AuthController();


  @override
  void dispose() {
    _masterKeyController.dispose();
    _confirmMasterKeyController.dispose();
    super.dispose();
  }

  // --- CORREÇÃO: NOVA FUNÇÃO DE CANCELAR/LOGOUT ---
  Future<void> _handleCancelAndLogout() async {
    await _authController.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _createMasterKey() async {
    final masterKey = _masterKeyController.text;
    final confirmKey = _confirmMasterKeyController.text;

    // Validações
    if (masterKey.isEmpty || confirmKey.isEmpty) {
      _showError('Por favor, preencha todos os campos.');
      return;
    }

    if (masterKey != confirmKey) {
      _showError('As chaves-mestras não coincidem.');
      return;
    }

    if (masterKey.length < 8) {
      _showError('A chave-mestra deve ter pelo menos 8 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cria o documento de verificação
      await _masterKeyService.createVerificationDocument(masterKey);

      if (mounted) {
        // Navega para a tela principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(masterKey: masterKey)),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao criar chave-mestra: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
          // --- CORREÇÃO: ONPRESSED ATUALIZADO ---
          onPressed: _isLoading ? null : _handleCancelAndLogout,
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
                Image.asset('assets/images/icon-without-name.png', height: 80),
                const SizedBox(height: 24),
                const Text(
                  'Crie sua Chave-Mestra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta chave será usada para criptografar todas as suas senhas. Não a perca!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF5a5a5a)),
                ),
                const SizedBox(height: 40),

                _buildPasswordField(
                  label: 'Chave-Mestra',
                  controller: _masterKeyController,
                  isObscured: !_isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),

                const SizedBox(height: 20),

                _buildPasswordField(
                  label: 'Confirme a Chave-Mestra',
                  controller: _confirmMasterKeyController,
                  isObscured: !_isConfirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _createMasterKey,
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
                          'Criar Chave-Mestra',
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
          controller: controller,
          obscureText: isObscured,
          enabled: !_isLoading,
          decoration: InputDecoration(
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
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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