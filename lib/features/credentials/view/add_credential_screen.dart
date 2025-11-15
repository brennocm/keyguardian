import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atividade_01/core/models/credential_model.dart';
import 'package:atividade_01/features/credentials/bloc/credential_bloc.dart';
import 'package:atividade_01/features/credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/credentials/bloc/credential_state.dart';
import 'package:atividade_01/core/services/hibp_service.dart';

class AddCredentialScreen extends StatefulWidget {
  final CredentialBloc bloc;
  final String masterKey;

  const AddCredentialScreen({
    super.key,
    required this.bloc,
    required this.masterKey,
  });

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedCategory = 'Outro';
  
  final HibpService _hibpService = HibpService();
  bool _isCheckingHibp = false;
  int _hibpBreachCount = -1;

  final List<String> _categories = [
    'Rede Social',
    'Banco',
    'Email',
    'Trabalho',
    'Outro'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkPasswordSecurity() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() => _isCheckingHibp = true);
    final count = await _hibpService.checkPassword(password);
    setState(() {
      _hibpBreachCount = count;
      _isCheckingHibp = false;
    });

    // Mostra um alerta se a senha estiver comprometida
    if (count > 0 && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Senha Comprometida'),
          content: Text(
            'Esta senha foi encontrada em $count vazamento(s) de dados!\n\n'
            'Recomendamos usar uma senha diferente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Usar mesmo assim'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _passwordController.clear();
              },
              child: const Text('Trocar senha', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _onSavePressed() async {
    if (_formKey.currentState!.validate()) {
      // Verifica a senha antes de salvar
      await _checkPasswordSecurity();

      final newCredential = CredentialModel(
        title: _titleController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        category: _selectedCategory,
        websiteUrl: _urlController.text,
      );

      widget.bloc.add(
        AddCredential(newCredential, widget.masterKey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CredentialBloc, CredentialState>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (state is CredentialOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credencial salva com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
        if (state is CredentialFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF212121),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Color(0xFFF5B984)),
          title: const Text(
            'Adicionar Nova Senha',
            style: TextStyle(
              color: Color(0xFFF5B984),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_isCheckingHibp)
                const Card(
                  color: Color(0xFF2a2a2a),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Verificando segurança da senha...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_hibpBreachCount >= 0 && !_isCheckingHibp)
                _buildSecurityIndicator(),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _titleController,
                label: 'Título',
                hint: 'Ex: Gmail, Facebook...',
                icon: Icons.label_outline,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Por favor, insira um título'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _usernameController,
                label: 'Nome de Usuário / Email',
                hint: 'seu@email.com',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _passwordController,
                label: 'Senha',
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Por favor, insira uma senha'
                    : null,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white70),
                  onPressed: _checkPasswordSecurity,
                  tooltip: 'Verificar segurança',
                ),
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _urlController,
                label: 'Site (URL)',
                hint: 'https://...',
                icon: Icons.link_outlined,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDAB9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Salvar',
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
      ),
    );
  }

  Widget _buildSecurityIndicator() {
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFF5B984)),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: const Color(0xFFF5B984)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2a2a2a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF5B984), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: const Color(0xFF2a2a2a),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Categoria',
        labelStyle: const TextStyle(color: Color(0xFFF5B984)),
        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFF5B984)),
        filled: true,
        fillColor: const Color(0xFF2a2a2a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF5B984), width: 2),
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value ?? 'Outro';
        });
      },
    );
  }
}
