import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'feed_product_card.dart';

class ProductsList extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedCity;
  final String sortBy;
  final bool sortDescending;

  const ProductsList({
    super.key,
    this.selectedCategory,
    this.selectedCity,
    required this.sortBy,
    required this.sortDescending,
  });

  @override
  State<ProductsList> createState() => ProductsListState();
}

class ProductsListState extends State<ProductsList> {
  late Stream<QuerySnapshot> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = _getProductsStream();
  }

  @override
  void didUpdateWidget(covariant ProductsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory ||
        widget.selectedCity != oldWidget.selectedCity ||
        widget.sortBy != oldWidget.sortBy ||
        widget.sortDescending != oldWidget.sortDescending) {
      setState(() {
        _productsStream = _getProductsStream();
      });
    }
  }

  Stream<QuerySnapshot> _getProductsStream() {
    Query productsQuery = FirebaseFirestore.instance.collection('products');

    if (widget.selectedCategory != null) {
      productsQuery =
          productsQuery.where('category', isEqualTo: widget.selectedCategory);
    }

    if (widget.selectedCity != null) {
      productsQuery =
          productsQuery.where('city', isEqualTo: widget.selectedCity);
    }

    productsQuery =
        productsQuery.orderBy(widget.sortBy, descending: widget.sortDescending);

    return productsQuery.snapshots();
  }

  void refresh() {
    setState(() {
      _productsStream = _getProductsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('Ocorreu um erro ao carregar os produtos.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum produto encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          // CORRIGIDO: Adiciona uma chave para guardar a posição do scroll
          key: const PageStorageKey('products_list'),
          padding: const EdgeInsets.all(0),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = ProductModel.fromFirestore(products[index]);
            return FeedProductCard(
              key: ValueKey(product.id),
              product: product,
            );
          },
        );
      },
    );
  }
}
