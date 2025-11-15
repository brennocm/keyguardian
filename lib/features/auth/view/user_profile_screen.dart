// lib/features/auth/view/user_profile_screen.dart

import 'package:flutter/material.dart';
// 1. IMPORTES (REMOVEMOS O MASTER KEY, ADICIONAMOS O AUTH CONTROLLER)
import 'package:atividade_01/features/auth/auth_controller.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // 2. CONTROLADORES E ESTADO
  final AuthController _authController = AuthController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _email;
  bool _isUserPasswordVisible = false;
  bool _isMasterKeyVisible = false; // (Este é apenas para a UI, por enquanto)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 3. BUSCA O E-MAIL REAL DO USUÁRIO
    _email = _authController.currentUser?.email ?? 'E-mail não encontrado';
  }

  @override
  void dispose() {
    // 4. LIMPA OS CONTROLADORES
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 5. FUNÇÃO PRINCIPAL PARA ATUALIZAR SENHA
  Future<void> _handleUpdatePassword() async {
    if (_isLoading) return;

    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Validações
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showErrorSnackbar('Preencha todos os campos de senha.');
      return;
    }
    if (newPass != confirmPass) {
      _showErrorSnackbar('As novas senhas não coincidem.');
      return;
    }
    if (newPass.length < 6) {
      _showErrorSnackbar('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Passo 1: Reautenticar com a senha antiga
      await _authController.reauthenticateWithPassword(oldPass);
      
      // Passo 2: Se a reautenticação for bem-sucedida, atualiza a senha
      await _authController.updateUserPassword(newPass);

      // Sucesso
      _showSuccessSnackbar('Senha atualizada com sucesso!');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 6. HELPERS DE SNACKBAR
  void _showErrorSnackbar(String message) {
    final displayMessage = message.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        title: const Text(
          'Perfil de usuário',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(),
            const SizedBox(height: 24),
            const Divider(color: Colors.grey),
            const SizedBox(height: 24),
            _buildEditSection(),
            const SizedBox(height: 32),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 7. E-MAIL REAL CONECTADO
        _buildInfoField(
          label: 'E-mail de usuário', 
          value: _email, // <-- MODIFICADO
        ),
        const SizedBox(height: 24),
        _buildInfoField(
          label: 'Senha de usuário',
          value: '●●●●●●●●●●●●', // (Valor estático é OK)
          isObscured: true,
          isVisible: _isUserPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isUserPasswordVisible = !_isUserPasswordVisible),
        ),
        const SizedBox(height: 24),
        // (A Chave-Mestra não é salva, apenas usada para descriptografar)
        _buildInfoField(
          label: 'Chave-mestra de usuário',
          value: '●●●●●●●●●●●●●●●●●●',
          isObscured: true,
          isVisible: _isMasterKeyVisible,
          onToggleVisibility: () =>
              setState(() => _isMasterKeyVisible = !_isMasterKeyVisible),
        ),
      ],
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Editar Senha de Acesso', // Título atualizado
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        // 8. CONTROLADORES CONECTADOS
        _buildEditableField(
          label: 'Senha antiga:',
          controller: _oldPasswordController, // <-- MODIFICADO
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Senha nova:',
          controller: _newPasswordController, // <-- MODIFICADO
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Confirmar senha nova:',
          controller: _confirmPasswordController, // <-- MODIFICADO
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // 9. BOTÃO CONECTADO
        onPressed: _isLoading ? null : _handleUpdatePassword, // <-- MODIFICADO
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFDAB9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading 
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF212121),
              ),
            )
          : const Text(
              'Confirmar Mudança',
              style: TextStyle(
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    bool isObscured = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                isObscured && !isVisible ? '●' * value.length : value,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            if (isObscured)
              IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              ),
          ],
        ),
      ],
    );
  }

  // MODIFICADO para aceitar um controller
  Widget _buildEditableField({
    required String label, 
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField( // <-- MODIFICADO de const TextField
          controller: controller, // <-- MODIFICADO
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '●●●●●●●●●●●●',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}