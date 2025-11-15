import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class HomeScreen extends StatefulWidget {
  final String masterKey;

  const HomeScreen({super.key, required this.masterKey});

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
    _credentialBloc.add(LoadCredentials(widget.masterKey));
  }

  @override
  void dispose() {
    _credentialBloc.close();
    super.dispose();
  }

  Future<void> _handleLogout() async {
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
                                  builder: (context) => const UserProfileScreen(),
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
                            builder: (context) => const PasswordGeneratorScreen(),
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
          listener: (context, state) {
            if (state is CredentialFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro de stream: ${state.error}'),
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
            // Estado de Loading ou Inicial
            if (state is CredentialLoading || state is CredentialInitial) {
              return const Center(
                child: CircularProgressIndicator(color: primaryTextColor),
              );
            }

            // Estado de Falha
            if (state is CredentialFailure) {
              return Center(
                child: Text(
                  'Ocorreu um erro: ${state.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            // Estado de Sucesso (Lista Carregada)
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
                  final IconData icon = _getIconForCategory(credential.category);
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
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white30,
                      size: 16,
                    ),
                    onTap: () {
                      // Navega para a tela de detalhes
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CredentialDetailsScreen(
                            credential: credential,
                            masterKey: widget.masterKey,
                            bloc: _credentialBloc,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }

            // Estado de transição (ex: após OperationSuccess)
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
                  masterKey: widget.masterKey,
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

  // Método helper para ícones por categoria
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