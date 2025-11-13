import 'package:flutter/material.dart';
import 'credential_details_screen.dart';
import 'password_generator_screen.dart';
import 'user_profile_screen.dart'; // Removido o aviso de "não usado"
import 'welcome_screen.dart';
import '../model/database_controller.dart';
import '../model/auth_controller.dart'; 

class HomeScreen extends StatefulWidget {
  final String masterKey;
  
  const HomeScreen({super.key, required this.masterKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  final AuthController _authController = AuthController();
  final DatabaseController _dbController = DatabaseController();

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

    return Scaffold(
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
                        // --- CORREÇÃO AQUI ---
                        // Adicionando o link para UserProfileScreen
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
                          builder: (context) => const PasswordGeneratorScreen()
                        )
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF212121)),
              title: const Text('Sair',
                  style: TextStyle(
                      color: Color(0xFF212121), fontWeight: FontWeight.bold)),
              onTap: _handleLogout, // Conectado
            ),
            const SizedBox(height: 20), 
          ],
        ),
      ),
      body: StreamBuilder<List<PasswordEntry>>(
        stream: _dbController.getCredentialsStream(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryTextColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ocorreu um erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma senha salva ainda.\nClique no botão + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final entries = snapshot.data!;

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final subtitleText =
                  entry.url.replaceAll('https://', '').replaceAll('www.', '');

              return ListTile(
                leading: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 16),
                title: Text(entry.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(subtitleText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CredentialDetailsScreen(
                        entry: entry,
                        masterKey: widget.masterKey, // Passamos a chave
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Criar a tela "add_credential_screen.dart"
          // Por enquanto, vamos adicionar um teste
          _dbController.addCredential(
            title: "Meu Site de Teste",
            url: "https://teste.com",
            username: "usuario@teste.com",
            plainTextPassword: "MinhaSenhaSuperSecreta123",
            masterKey: widget.masterKey,
          );
        },
        backgroundColor: const Color(0xFFF5B984),
        child: const Icon(Icons.add, color: Color(0xFF212121)),
      ),
    );
  }
}