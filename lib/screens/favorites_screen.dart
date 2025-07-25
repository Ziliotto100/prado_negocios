import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/feed_product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Favoritos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productService.getFavoriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não adicionou favoritos.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final favoriteDocs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final product = ProductModel.fromFirestore(favoriteDocs[index]);
              return FeedProductCard(
                  key: ValueKey(product.id), product: product);
            },
          );
        },
      ),
    );
  }
}
