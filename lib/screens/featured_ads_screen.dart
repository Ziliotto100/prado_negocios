import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class FeaturedAdsScreen extends StatefulWidget {
  const FeaturedAdsScreen({super.key});

  @override
  State<FeaturedAdsScreen> createState() => _FeaturedAdsScreenState();
}

class _FeaturedAdsScreenState extends State<FeaturedAdsScreen> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerir Anúncios Fixados'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productService.getFeaturedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum anúncio fixado.'));
          }

          final featuredDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: featuredDocs.length,
            itemBuilder: (context, index) {
              final product = ProductModel.fromFirestore(featuredDocs[index]);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: product.imageUrls.isNotEmpty
                        ? NetworkImage(product.imageUrls.first)
                        : null,
                  ),
                  title: Text(product.name),
                  subtitle: Text(product.category),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _productService.toggleFeaturedStatus(product.id!, true);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('Remover'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
