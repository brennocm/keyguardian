import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class HibpService {
  static const String _apiUrl = 'https://api.pwnedpasswords.com/range/';
  Future<int> checkPassword(String password) async {
    try {
      final bytes = utf8.encode(password);
      final digest = sha1.convert(bytes);
      final hash = digest.toString().toUpperCase();
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);

      final response = await http.get(
        Uri.parse('$_apiUrl$prefix'),
        headers: {
          'User-Agent': 'KeyGuardian-Password-Manager',
          'Add-Padding': 'true', 
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao consultar API: ${response.statusCode}');
      }

      final lines = response.body.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length == 2 && parts[0].trim() == suffix) {
          return int.parse(parts[1].trim());
        }
      }
      return 0;
    } catch (e) {
      print('Erro ao verificar senha no HIBP: $e');
      return -1;
    }
  }

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
