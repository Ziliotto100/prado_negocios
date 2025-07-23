import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class BannedUsersScreen extends StatefulWidget {
  const BannedUsersScreen({super.key});

  @override
  State<BannedUsersScreen> createState() => _BannedUsersScreenState();
}

class _BannedUsersScreenState extends State<BannedUsersScreen> {
  final AuthService _authService = AuthService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilizadores Banidos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pesquisar por nome...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _authService.getBannedUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum utilizador banido.'));
                }

                // Filtra os resultados com base na pesquisa
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final user = UserModel.fromFirestore(doc);
                  return user.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                      child: Text('Nenhum resultado encontrado.'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final user = UserModel.fromFirestore(filteredDocs[index]);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              user.photoUrl != null && user.photoUrl!.isNotEmpty
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _authService.toggleBanStatus(user.id, true);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text('Desbanir'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
