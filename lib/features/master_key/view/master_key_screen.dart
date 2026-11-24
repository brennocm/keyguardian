import 'package:flutter/material.dart';
import 'package:atividade_01/features/credentials/view/home_screen.dart';
import 'package:atividade_01/features/auth/auth_controller.dart';
import 'package:atividade_01/core/services/master_key_service.dart';
import 'package:atividade_01/features/auth/view/welcome_screen.dart'; 

class MasterKeyScreen extends StatefulWidget {
  const MasterKeyScreen({super.key});

  @override
  State<MasterKeyScreen> createState() => _MasterKeyScreenState();
}

class _MasterKeyScreenState extends State<MasterKeyScreen> {
  final _masterKeyController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  final AuthController _authController = AuthController();
  final MasterKeyService _masterKeyService = MasterKeyService();

  @override
  void dispose() {
    _masterKeyController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogout() async {
    await _authController.signOut();
    
    // Redireciona o usuário de volta à tela inicial após o logout
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _unlockVault() async {
    final masterKey = _masterKeyController.text;

    if (masterKey.isEmpty) {
      _showError('Por favor, digite sua chave-mestra.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vaultKey = await _masterKeyService.unlock(masterKey);

      if (vaultKey == null) {
        if (mounted) {
          _showError('Chave-mestra incorreta. Tente novamente.');
        }
        // Resetar o loading no caso de falha
        setState(() => _isLoading = false); 
        return;
      }

      _masterKeyController.clear();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(vaultKey: vaultKey),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao validar chave-mestra: $e');
      }
    } finally {
      if (mounted && _isLoading) { // Só muda se ainda estiver carregando
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
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
          onPressed: _isLoading ? null : _handleLogout,
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
                controller: _masterKeyController,
                obscureText: !_isPasswordVisible,
                enabled: !_isLoading,
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
                onPressed: _isLoading ? null : _unlockVault,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212121),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
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