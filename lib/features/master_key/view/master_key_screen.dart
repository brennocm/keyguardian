import 'package:flutter/material.dart';
import 'package:atividade_01/features/credentials/view/home_screen.dart';
import 'package:atividade_01/features/auth/auth_controller.dart';

class MasterKeyScreen extends StatefulWidget {
  const MasterKeyScreen({super.key});

  @override
  State<MasterKeyScreen> createState() => _MasterKeyScreenState();
}

class _MasterKeyScreenState extends State<MasterKeyScreen> {
  final _masterKeyController = TextEditingController();
  bool _isPasswordVisible = false;
  
  // 2. CRIAMOS A INSTÂNCIA DO AUTH CONTROLLER
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _masterKeyController.dispose();
    super.dispose();
  }
  
  // 3. FUNÇÃO DE LOGOUT (NOVO)
  Future<void> _handleLogout() async {
    // Chama o método de sair
    await _authController.signOut();
    // O AuthGate no main.dart vai detectar isso e trocar 
    // para a WelcomeScreen automaticamente.
  }

  // Função para destravar o cofre
  void _unlockVault() {
    final masterKey = _masterKeyController.text;

    if (masterKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite sua chave-mestra.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navega para a Home, passando a chave
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(masterKey: masterKey),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
         backgroundColor: Colors.transparent,
         elevation: 0,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
           // 4. CORRIGIMOS O BOTÃO "VOLTAR"
           // Em vez de Navigator.pop, chamamos o _handleLogout
           onPressed: _handleLogout,
         ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/icon-without-name.png',
                height: 80,
                color: const Color(0xFF212121),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chave-Mestre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Digite sua chave-mestra',
                style: TextStyle(
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              TextField(
                controller: _masterKeyController, // Conectado
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF212121),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trata-se da chave para descriptografar todas as suas senhas.',
                style: TextStyle(
                  color: Color(0xFF5a5a5a),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              
              ElevatedButton(
                onPressed: _unlockVault, // Conectado
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212121),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Próximo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}