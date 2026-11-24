// lib/features/credentials/view/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORTADO PARA O CHECK
import 'package:atividade_01/features/credentials/view/add_credential_screen.dart';
import 'package:atividade_01/features/credentials/view/credential_details_screen.dart';
import 'package:atividade_01/features/credentials/bloc/credential_bloc.dart';
import 'package:atividade_01/features/credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/credentials/bloc/credential_state.dart';
import 'package:atividade_01/features/credentials/data/credential_provider.dart';
import 'package:atividade_01/features/generator/view/password_generator_screen.dart';
import 'package:atividade_01/features/auth/view/user_profile_screen.dart';
import 'package:atividade_01/features/auth/view/welcome_screen.dart';
import 'package:atividade_01/features/auth/auth_controller.dart';
import 'package:atividade_01/core/crypto/vault_crypto.dart';

class HomeScreen extends StatefulWidget {
  final VaultKey vaultKey;
  const HomeScreen({super.key, required this.vaultKey});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  late final CredentialBloc _credentialBloc;
  @override
  void initState() {
    super.initState();
    _credentialBloc = CredentialBloc(provider: CredentialProvider());
    _credentialBloc.add(LoadCredentials(widget.vaultKey));
  }

  // Verifica se o BLoC não está fechado antes de fechar
  @override
  void dispose() {
    if (!_credentialBloc.isClosed) {
      _credentialBloc.close();
    }
    super.dispose();
  }

  // CFecha o BLoC *antes* de fazer o signOut
  Future<void> _handleLogout() async {
    if (!_credentialBloc.isClosed) {
      await _credentialBloc.close();
    }
    await _authController.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFFF5B984);
    return BlocProvider.value(
      value: _credentialBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFF212121),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: primaryTextColor),
          title: const Text(
            'Todas as entradas',
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFFFFDAB9),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFDAB9),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserProfileScreen(),
                                ),
                              );
                            },
                            child: Image.asset(
                              'assets/images/icon-without-name.png',
                              height: 80,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.vpn_key_outlined,
                        color: Color(0xFF212121),
                      ),
                      title: const Text(
                        'Todas as entradas',
                        style: TextStyle(
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.password_rounded,
                        color: Color(0xFF212121),
                      ),
                      title: const Text(
                        'Gerador de senhas',
                        style: TextStyle(
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PasswordGeneratorScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF212121)),
                title: const Text(
                  'Sair',
                  style: TextStyle(
                    color: Color(0xFF212121),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _handleLogout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        body: BlocConsumer<CredentialBloc, CredentialState>(
          //  Lógica do Listener para ignorar o erro de logout
          listener: (context, state) {
            if (state is CredentialFailure) {
              // Só mostra o SnackBar se o erro NÃO for de permissão
              final isPermissionDenied = state.error.toString().contains('permission-denied');
              final isSignedOut = FirebaseAuth.instance.currentUser == null;

              if (isPermissionDenied && isSignedOut) {
                // Erro esperado durante o logout, não faz nada.
                return;
              }
              
              // Para qualquer outro erro, mostre o SnackBar.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          buildWhen: (previous, current) {
            return current is CredentialInitial ||
                current is CredentialLoading ||
                current is CredentialLoaded ||
                current is CredentialFailure;
          },
          builder: (context, state) {
            // Loading ou estado inicial
            if (state is CredentialLoading || state is CredentialInitial) {
              return const Center(
                child: CircularProgressIndicator(color: primaryTextColor),
              );
            }
            // Falha
            if (state is CredentialFailure) {
              // Lógica do Builder para não mostrar erro durante o logout
              final msg = state.error.toString();
              final isPermissionDenied = msg.contains('permission-denied');
              final isSignedOut =
                  FirebaseAuth.instance.currentUser == null;
 
              // Se for o erro de permission-denied e o usuário já saiu,
              // simplesmente não mostra nada (a tela vai ser trocada pelo AuthGate)
              if (isPermissionDenied && isSignedOut) {
                return const SizedBox.shrink(); // Retorna widget vazio
              }
              
              // Mostra um erro genérico para outras falhas
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Não foi possível carregar suas senhas.\nVerifique sua chave-mestra ou tente novamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              );
            }
            // Lista carregada
            if (state is CredentialLoaded) {
              final credentials = state.credentials;
              if (credentials.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma senha salva ainda.\nClique no botão + para adicionar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                itemCount: credentials.length,
                itemBuilder: (context, index) {
                  final credential = credentials[index];
                  final IconData icon =
                      _getIconForCategory(credential.category);
                  final subtitleText = credential.websiteUrl
                      .replaceAll('https://', '')
                      .replaceAll('http://', '')
                      .replaceAll('www.', '');
                  return ListTile(
                    leading: Icon(icon, color: Colors.white70, size: 24),
                    title: Text(
                      credential.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      subtitleText.isEmpty ? 'Sem URL' : subtitleText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white30,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CredentialDetailsScreen(
                            credential: credential,
                            vaultKey: widget.vaultKey,
                            bloc: _credentialBloc,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }
            // Estado de transição
            return const Center(
              child: CircularProgressIndicator(color: primaryTextColor),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCredentialScreen(
                  bloc: _credentialBloc,
                  vaultKey: widget.vaultKey,
                ),
              ),
            );
          },
          backgroundColor: const Color(0xFFF5B984),
          child: const Icon(Icons.add, color: Color(0xFF212121)),
        ),
      ),
    );
  }
  // Helper para escolher ícone por categoria
  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'banco':
        return Icons.account_balance;
      case 'rede social':
        return Icons.people;
      case 'email':
        return Icons.mail;
      case 'trabalho':
        return Icons.work;
      default:
        return Icons.vpn_key;
    }
  }
}