import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class HibpService {
  static const String _apiUrl = 'https://api.pwnedpasswords.com/range/';

  /// Verifica se a senha foi comprometida usando k-anonymity
  /// Retorna o número de vezes que a senha apareceu em vazamentos
  /// Retorna 0 se a senha não foi encontrada
  Future<int> checkPassword(String password) async {
    try {
      // 1. Gera o hash SHA-1 da senha
      final bytes = utf8.encode(password);
      final digest = sha1.convert(bytes);
      final hash = digest.toString().toUpperCase();

      // 2. Separa os primeiros 5 caracteres do resto
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);

      // 3. Consulta a API com apenas os 5 primeiros caracteres (k-anonymity)
      final response = await http.get(
        Uri.parse('$_apiUrl$prefix'),
        headers: {
          'User-Agent': 'KeyGuardian-Password-Manager',
          'Add-Padding': 'true', // Adiciona padding para melhor privacidade
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao consultar API: ${response.statusCode}');
      }

      // 4. Procura o sufixo na resposta
      final lines = response.body.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length == 2 && parts[0].trim() == suffix) {
          return int.parse(parts[1].trim());
        }
      }

      // 5. Senha não foi encontrada nos vazamentos
      return 0;
    } catch (e) {
      // Em caso de erro de rede, retorna -1 para indicar que não foi possível verificar
      print('Erro ao verificar senha no HIBP: $e');
      return -1;
    }
  }

  /// Retorna uma mensagem amigável baseada no resultado
  String getSecurityMessage(int breachCount) {
    if (breachCount == -1) {
      return 'Não foi possível verificar a segurança da senha';
    } else if (breachCount == 0) {
      return 'Senha segura! Não encontrada em vazamentos conhecidos';
    } else if (breachCount < 10) {
      return 'ATENÇÃO: Senha encontrada em $breachCount vazamento(s)';
    } else {
      return 'PERIGO: Senha comprometida! Encontrada em $breachCount vazamentos';
    }
  }

  /// Retorna a cor para o indicador de segurança
  SecurityLevel getSecurityLevel(int breachCount) {
    if (breachCount == -1) {
      return SecurityLevel.unknown;
    } else if (breachCount == 0) {
      return SecurityLevel.safe;
    } else if (breachCount < 10) {
      return SecurityLevel.warning;
    } else {
      return SecurityLevel.danger;
    }
  }
}

enum SecurityLevel {
  safe,
  warning,
  danger,
  unknown,
}
