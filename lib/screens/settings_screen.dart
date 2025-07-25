import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'update_email_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUserEmail = authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da Conta'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Redefinir senha'),
            subtitle: const Text(
                'Confira sua caixa de entrada e de spam.'), // <-- TEXTO ALTERADO
            onTap: () async {
              final success =
                  await authService.sendPasswordResetEmail(currentUserEmail);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'E-mail de redefinição enviado com sucesso!'
                        : 'Ocorreu um erro.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Alterar E-mail'),
            subtitle: const Text(
                'Será necessário seu e-mail atual.'), // <-- TEXTO ALTERADO
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const UpdateEmailScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
