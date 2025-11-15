import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atividade_01/core/models/credential_model.dart';
import 'package:atividade_01/features/credentials/bloc/credential_bloc.dart';
import 'package:atividade_01/features/credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/credentials/bloc/credential_state.dart';
import 'package:atividade_01/core/services/hibp_service.dart';

class CredentialDetailsScreen extends StatefulWidget {
  final CredentialModel credential;
  final String masterKey;
  final CredentialBloc bloc;

  const CredentialDetailsScreen({
    super.key,
    required this.credential,
    required this.masterKey,
    required this.bloc,
  });

  @override
  State<CredentialDetailsScreen> createState() => _CredentialDetailsScreenState();
}

class _CredentialDetailsScreenState extends State<CredentialDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late String _selectedCategory;

  final List<String> _categories = ['Rede Social', 'Banco', 'Email', 'Trabalho', 'Outro'];
  
  bool _isPasswordVisible = false;
  bool _showSuccessMessage = false;
  bool _isCheckingHibp = false;
  int _hibpBreachCount = -1;
  final HibpService _hibpService = HibpService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.credential.title);
    _urlController = TextEditingController(text: widget.credential.websiteUrl);
    _usernameController = TextEditingController(text: widget.credential.username);
    _passwordController = TextEditingController(text: widget.credential.password);
    _selectedCategory = widget.credential.category;
    
    // Verifica a senha no HIBP ao abrir
    _checkPasswordSecurity();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkPasswordSecurity() async {
    setState(() => _isCheckingHibp = true);
    final count = await _hibpService.checkPassword(widget.credential.password);
    setState(() {
      _hibpBreachCount = count;
      _isCheckingHibp = false;
    });
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _handleUpdate() {
    final updatedCredential = CredentialModel(
      id: widget.credential.id,
      title: _titleController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      category: _selectedCategory,
      websiteUrl: _urlController.text,
    );

    widget.bloc.add(UpdateCredential(updatedCredential, widget.masterKey));
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja deletar esta credencial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo
              widget.bloc.add(DeleteCredential(widget.credential.id!));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    setState(() => _showSuccessMessage = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSuccessMessage = false);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFFF5B984);

    return BlocListener<CredentialBloc, CredentialState>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (state is CredentialOperationSuccess) {
          _showSuccess();
        }
        if (state is CredentialFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF212121),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: primaryTextColor),
          title: const Text(
            'Perfil de credencial',
            style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _handleDelete,
            )
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSecurityIndicator(),
                const SizedBox(height: 24),
                _buildInfoSection(),
                const Divider(color: Colors.white24, height: 40),
                _buildEditSection(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _handleUpdate,
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
            if (_showSuccessMessage)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
                        SizedBox(height: 16),
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityIndicator() {
    if (_isCheckingHibp) {
      return const Card(
        color: Color(0xFF2a2a2a),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
              SizedBox(width: 16),
              Text('Verificando segurança...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final level = _hibpService.getSecurityLevel(_hibpBreachCount);
    final message = _hibpService.getSecurityMessage(_hibpBreachCount);
    
    Color cardColor;
    IconData icon;
    
    switch (level) {
      case SecurityLevel.safe:
        cardColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case SecurityLevel.warning:
        cardColor = Colors.orange.shade800;
        icon = Icons.warning;
        break;
      case SecurityLevel.danger:
        cardColor = Colors.red.shade800;
        icon = Icons.dangerous;
        break;
      default:
        cardColor = const Color(0xFF2a2a2a);
        icon = Icons.help_outline;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCopyableField(label: 'Título', value: widget.credential.title),
        const SizedBox(height: 16),
        _buildCopyableField(label: 'URL', value: widget.credential.websiteUrl),
        const SizedBox(height: 16),
        _buildCopyableField(label: 'Usuário', value: widget.credential.username),
        const SizedBox(height: 16),
        _buildCopyableField(
          label: 'Senha',
          value: widget.credential.password,
          isPassword: true,
          isVisible: _isPasswordVisible,
          onVisibilityChanged: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
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
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildEditableField(label: 'Título:', controller: _titleController),
        const SizedBox(height: 16),
        _buildEditableField(label: 'URL:', controller: _urlController),
        const SizedBox(height: 16),
        _buildEditableField(label: 'Usuário:', controller: _usernameController),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Senha:',
          controller: _passwordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoria:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          dropdownColor: const Color(0xFF2a2a2a),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value ?? 'Outro');
          },
        ),
      ],
    );
  }

  Widget _buildCopyableField({
    required String label,
    required String value,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFF5B984), fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                isPassword && !isVisible ? '●' * value.length : value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (isPassword)
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white70,
                ),
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
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
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
