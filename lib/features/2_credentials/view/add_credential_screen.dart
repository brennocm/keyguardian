import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atividade_01/core/models/credential_model.dart';
import 'package:atividade_01/features/2_credentials/bloc/credential_bloc.dart';
import 'package:atividade_01/features/2_credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/2_credentials/bloc/credential_state.dart';

class AddCredentialScreen extends StatefulWidget {
  // 1. Recebe o BLoC e a Chave-Mestre da HomeScreen
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
  // 2. Controladores para os campos do formulário
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedCategory = 'Outro'; // Valor padrão

  final List<String> _categories = [
    'Rede Social',
    'Banco',
    'Email',
    'Trabalho',
    'Outro'
  ];

  @override
  void dispose() {
    // Limpe os controladores
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    // 5. O botão 'Salvar' valida o formulário
    if (_formKey.currentState!.validate()) {
      // Cria o modelo com os dados
      final newCredential = CredentialModel(
        title: _titleController.text,
        username: _usernameController.text,
        password: _passwordController.text, // TODO: Criptografar!
        category: _selectedCategory,
        websiteUrl: _urlController.text,
      );

      // 6. DISPARA O EVENTO!
      // Envia a ordem para o BLoC, que vai chamar o Provider
      widget.bloc.add(
        AddCredential(newCredential, widget.masterKey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. O 'BlocListener' reage ao sucesso/falha
    // Ele não constrói UI, apenas "ouve"
    return BlocListener<CredentialBloc, CredentialState>(
      bloc: widget.bloc, // Ouve o BLoC que recebemos
      listener: (context, state) {
        if (state is CredentialOperationSuccess) {
          // Sucesso! Mostra um aviso e fecha a tela
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credencial salva com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Volta para a HomeScreen
        }
        if (state is CredentialFailure) {
          // Erro! Mostra um aviso de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Adicionar Nova Senha'),
          // Você pode estilizar a AppBar aqui para combinar com o app
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Por favor, insira um título'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nome de Usuário / Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Por favor, insira uma senha'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Site (URL)'),
              ),
              const SizedBox(height: 12),
              
              // 4. O Dropdown para a Categoria (REQUISITO DA DISCIPLINA)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoria'),
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
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onSavePressed,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}