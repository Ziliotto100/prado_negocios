import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import '../models/product_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.getUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final isMyProfile = _authService.currentUser?.uid == widget.userId;

    // A tela inteira agora é construída com base no FutureBuilder
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        // Estado de Carregamento
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('A carregar...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Estado de Erro ou Sem Dados
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: const Center(child: Text('Utilizador não encontrado.')),
          );
        }

        // Estado de Sucesso: Constrói a tela completa
        final user = userSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(user.name), // Usa o nome do utilizador já carregado
            actions: [
              if (isMyProfile)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // A função já não precisa de ser 'async'
                    // Navega diretamente com os dados do utilizador já carregados
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        )
                        .then((_) => setState(() {
                              // Recarrega os dados ao voltar da tela de edição
                              _userFuture = _authService.getUser(widget.userId);
                            }));
                  },
                ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(user),
                )
              ];
            },
            body: StreamBuilder<QuerySnapshot>(
              stream: _productService.getProductsForUser(widget.userId),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!productSnapshot.hasData ||
                    productSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Este utilizador não tem anúncios.'),
                  );
                }
                final products = productSnapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = ProductModel.fromFirestore(products[index]);
                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (user.phone != null && user.phone!.isNotEmpty)
            _buildInfoRow(Icons.phone, user.phone!),
          if (user.address != null && user.address!.isNotEmpty)
            _buildInfoRow(Icons.location_on_outlined, user.address!),
          _buildInfoRow(Icons.email_outlined, user.email),
          const Divider(height: 32),
          const Text('Anúncios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
