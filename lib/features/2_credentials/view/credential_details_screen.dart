import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:atividade_01/model/database_controller.dart';

class CredentialDetailsScreen extends StatefulWidget {
  // 2. AGORA RECEBEMOS O PasswordEntry E A masterKey
  final PasswordEntry entry;
  final String masterKey;

  const CredentialDetailsScreen({
    super.key, 
    required this.entry,
    required this.masterKey,
  });

  @override
  State<CredentialDetailsScreen> createState() =>
      _CredentialDetailsScreenState();
}

class _CredentialDetailsScreenState extends State<CredentialDetailsScreen> {
  // 3. Instância do nosso controlador
  final _dbController = DatabaseController();
  
  // 4. Controladores de texto para os campos de "Editar"
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  bool _isPasswordVisible = false;
  bool _showSuccessMessage = false;

  // 5. Variável para guardar a senha descriptografada
  String _decryptedPassword = "";

  @override
  void initState() {
    super.initState();

    // 6. Pré-populamos os campos de texto com os dados da senha
    _titleController = TextEditingController(text: widget.entry.title);
    _urlController = TextEditingController(text: widget.entry.url);
    _usernameController = TextEditingController(text: widget.entry.username);
    
    // 7. DESCRIPTOGRAFAMOS A SENHA AO ABRIR A TELA
    _decryptedPassword = _dbController.decrypt(
      widget.entry.encryptedPassword, 
      widget.masterKey
    );
    _passwordController = TextEditingController(text: _decryptedPassword);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // 8. Função para COPIAR
  void _copyToClipboard(String text, String A_SENHA_FOI_COPIADA) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(A_SENHA_FOI_COPIADA)),
    );
  }
  
  // 9. Função para SALVAR MUDANÇAS
  Future<void> _handleUpdateCredential() async {
    try {
      await _dbController.updateCredential(
        docId: widget.entry.id, 
        title: _titleController.text, 
        url: _urlController.text, 
        username: _usernameController.text, 
        plainTextPassword: _passwordController.text, 
        masterKey: widget.masterKey
      );
      
      _showSuccess(); // Mostra o pop-up de sucesso

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 10. Função para DELETAR
  Future<void> _handleDeleteCredential() async {
    // TODO: Mostrar um pop-up de confirmação antes de deletar
    try {
      await _dbController.deleteCredential(widget.entry.id);
      if (mounted) {
        Navigator.of(context).pop(); // Volta para a HomeScreen
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar: $e'), backgroundColor: Colors.red),
      );
    }
  }


  // (Resto do seu código da tela de detalhes, atualizado para usar os controllers)
  // ... (build, _buildInfoSection, _buildEditSection, etc.)
  // O código abaixo é uma versão atualizada da sua tela
  // para usar os novos controllers e lógica
  
  // (Função de pop-up de sucesso)
  void _showSuccess() {
    setState(() => _showSuccessMessage = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSuccessMessage = false);
        Navigator.of(context).pop(); // Volta para a Home após o sucesso
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFFF5B984);

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: primaryTextColor),
        title: const Text(
          'Perfil de credencial',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botão de Deletar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _handleDeleteCredential,
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildInfoSection(),
                const Divider(color: Colors.white24, height: 40),
                _buildEditSection(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _handleUpdateCredential, // Botão para SALVAR
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDAB9),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Salvar Mudanças',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccessMessage)
             Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SALVO COM SUCESSO!',
                      style: TextStyle(
                        color: Color(0xFF212121),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    Icon(
                      Icons.lock_outline,
                      color: Color(0xFF212121),
                      size: 48,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCopyableField(
          label: 'Título',
          value: widget.entry.title,
          isPassword: false,
        ),
        const SizedBox(height: 16),
        _buildCopyableField(
          label: 'URL',
          value: widget.entry.url,
          isPassword: false,
        ),
         const SizedBox(height: 16),
        _buildCopyableField(
          label: 'Usuário',
          value: widget.entry.username,
          isPassword: false,
        ),
        const SizedBox(height: 16),
        _buildCopyableField(
          label: 'Senha',
          value: _decryptedPassword, // Mostra a senha descriptografada
          isPassword: true,
          isVisible: _isPasswordVisible,
          onVisibilityChanged: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Editar',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Título:',
          controller: _titleController,
        ),
        const SizedBox(height: 16),
         _buildEditableField(
          label: 'URL:',
          controller: _urlController,
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Usuário:',
          controller: _usernameController,
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Senha:',
          controller: _passwordController,
          isPassword: true
        ),
      ],
    );
  }

  Widget _buildCopyableField({
    required String label,
    required String value,
    required bool isPassword,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFF5B984), fontSize: 14)),
        Row(
          children: [
            Expanded(
              child: Text(
                isPassword && !isVisible ? '●' * value.length : value,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            if (isPassword)
              IconButton(
                icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white70),
                onPressed: onVisibilityChanged,
              ),
            IconButton(
              icon: const Icon(Icons.copy_outlined, color: Colors.white70),
              onPressed: () => _copyToClipboard(value, '$label copiado(a)!'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        TextField(
          controller: controller,
          obscureText: isPassword, // Usamos o controller, não precisamos de state
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Colors.grey[700]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}