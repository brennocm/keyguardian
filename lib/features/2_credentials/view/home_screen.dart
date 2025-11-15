import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 1. Import BLoC
import 'package:atividade_01/features/2_credentials/view/add_credential_screen.dart';

// 2. Importe os arquivos BLoC
import 'package:atividade_01/features/2_credentials/bloc/credential_bloc.dart';
import 'package:atividade_01/features/2_credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/2_credentials/bloc/credential_state.dart';
import 'package:atividade_01/features/2_credentials/data/credential_provider.dart';

// 3. Importe as outras telas (como você já tinha)
import 'credential_details_screen.dart'; // TODO: Esta tela também precisará ser refatorada
import 'package:atividade_01/features/4_generator/view/password_generator_screen.dart';
import 'package:atividade_01/features/1_auth/view/user_profile_screen.dart';
import 'package:atividade_01/features/1_auth/view/welcome_screen.dart';
import 'package:atividade_01/model/auth_controller.dart'; // Podemos manter o logout por enquanto

class HomeScreen extends StatefulWidget {
  final String masterKey;

  const HomeScreen({super.key, required this.masterKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 4. Mantenha seu AuthController APENAS para o logout por agora
  final AuthController _authController = AuthController();
  
  // 5. CRIE O BLoC!
  late final CredentialBloc _credentialBloc;

  @override
  void initState() {
    super.initState();
    // 6. Instancie o BLoC e injete o Provedor
    _credentialBloc = CredentialBloc(provider: CredentialProvider());

    // 7. DISPARE O EVENTO!
    // Mande a "ordem" para o BLoC carregar os dados,
    // passando a masterKey
    _credentialBloc.add(LoadCredentials(widget.masterKey));
  }

  @override
  void dispose() {
    // 8. Feche o BLoC quando a tela for destruída
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

    // 9. FORNEÇA O BLoC para a árvore de widgets
    return BlocProvider.value(
      value: _credentialBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFF212121),
        appBar: AppBar(
          // ... (Seu AppBar está perfeito, não mude nada) ...
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
          // ... (Seu Drawer está perfeito, não mude nada) ...
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
                              Navigator.pop(context); // Fecha o drawer
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const UserProfileScreen()));
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
                      leading: const Icon(Icons.vpn_key_outlined,
                          color: Color(0xFF212121)),
                      title: const Text('Todas as entradas',
                          style: TextStyle(
                              color: Color(0xFF212121),
                              fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.password_rounded,
                          color: Color(0xFF212121)),
                      title: const Text('Gerador de senhas',
                          style: TextStyle(
                              color: Color(0xFF212121),
                              fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PasswordGeneratorScreen()));
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF212121)),
                title: const Text('Sair',
                    style: TextStyle(
                        color: Color(0xFF212121),
                        fontWeight: FontWeight.bold)),
                onTap: _handleLogout, // Conectado
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        
        // 10. A GRANDE MUDANÇA: Substitua o StreamBuilder pelo BlocBuilder
// ... dentro do seu Scaffold na home_screen.dart

        // 10. A GRANDE MUDANÇA: Substitua o BlocBuilder por BlocConsumer
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
          // O buildWhen está correto, vamos mantê-lo
          buildWhen: (previous, current) {
            return current is CredentialInitial ||
                   current is CredentialLoading ||
                   current is CredentialLoaded ||
                   current is CredentialFailure;
          },
          builder: (context, state) {
            
            // --- ESTADO DE LOADING (OU INICIAL) ---
            if (state is CredentialLoading || state is CredentialInitial) {
              return const Center(
                child: CircularProgressIndicator(color: primaryTextColor),
              );
            }

            // --- ESTADO DE FALHA ---
            if (state is CredentialFailure) {
              return Center(
                child: Text(
                  'Ocorreu um erro: ${state.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            // --- ESTADO DE SUCESSO (LISTA CARREGADA) ---
            if (state is CredentialLoaded) {
              // ... (O seu ListView.builder fica aqui,
              // exatamente como estava, sem nenhuma mudança)
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
                       .replaceAll('www.', '');

                   return ListTile(
                     leading: Icon(icon, color: Colors.white70, size: 24),
                     title: Text(credential.title,
                         style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold)),
                     subtitle: Text(subtitleText,
                         style: const TextStyle(
                             color: Colors.white70, fontSize: 12)),
                     onTap: () {
                       // TODO: (Isto ainda está pendente, como esperado)
                     },
                   );
                 },
               );
            }

            // ⬇️⬇️ A CORREÇÃO ESTÁ AQUI ⬇️⬇️
            // Se o estado não for nenhum dos acima (ex: é OperationSuccess),
            // significa que o stream ainda não atualizou.
            // Apenas mostre o loading, pois o estado 'Loaded'
            // está a caminho.
            return const Center(
              child: CircularProgressIndicator(color: primaryTextColor),
            );
          },
        ),

// ... resto do seu Scaffold
        
floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCredentialScreen(
                  // Passa o BLoC e a Chave-Mestre para a nova tela
                  bloc: _credentialBloc, // Passa a instância ATIVA do BLoC
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

  // MÉTODO HELPER (PARA O REQUISITO DA IMAGEM)
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
        return Icons.vpn_key; // Ícone padrão
    }
  }
}