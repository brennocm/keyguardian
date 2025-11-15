import 'package:flutter/material.dart';
import 'package:atividade_01/features/auth/auth_controller.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthController _authController = AuthController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _email;
  bool _isUserPasswordVisible = false;
  bool _isMasterKeyVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _email = _authController.currentUser?.email ?? 'E-mail não encontrado';
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _handleUpdatePassword() async {
    if (_isLoading) return;

    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

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
      await _authController.reauthenticateWithPassword(oldPass);
      await _authController.updateUserPassword(newPass);
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
        _buildInfoField(
          label: 'E-mail de usuário', 
          value: _email, 
        ),
        const SizedBox(height: 24),
        _buildInfoField(
          label: 'Senha de usuário',
          value: '●●●●●●●●●●●●', 
          isObscured: true,
          isVisible: _isUserPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isUserPasswordVisible = !_isUserPasswordVisible),
        ),
        const SizedBox(height: 24),
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
          'Editar Senha de Acesso', 
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildEditableField(
          label: 'Senha antiga:',
          controller: _oldPasswordController,
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Senha nova:',
          controller: _newPasswordController, 
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Confirmar senha nova:',
          controller: _confirmPasswordController,
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleUpdatePassword, 
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

  Widget _buildEditableField({
    required String label, 
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField( 
          controller: controller, 
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