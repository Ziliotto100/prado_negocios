import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../screens/product_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';

class FeedProductCard extends StatefulWidget {
  final ProductModel product;
  const FeedProductCard({super.key, required this.product});

  @override
  State<FeedProductCard> createState() => _FeedProductCardState();
}

class _FeedProductCardState extends State<FeedProductCard> {
  final AuthService _authService = AuthService();
  Future<UserModel?>? _sellerFuture;

  @override
  void initState() {
    super.initState();
    // Define a localização para o pacote timeago
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _sellerFuture = _authService.getUser(widget.product.userId);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final productService = ProductService();
    final currentUserId = _authService.currentUser?.uid;
    final isFavorited = currentUserId != null &&
        widget.product.favoritedBy.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(product: widget.product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com informações do vendedor
            _buildSellerHeader(),
            // Imagem Principal
            if (widget.product.imageUrls.isNotEmpty)
              Image.network(
                widget.product.imageUrls.first,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            // Detalhes (Nome e Preço)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Ações (Favorito e Chat)
            if (currentUserId != null && widget.product.userId != currentUserId)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        productService.toggleFavoriteStatus(
                            widget.product.id!, isFavorited);
                      },
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.grey[700],
                      ),
                      label: Text(
                        'Favorito',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerHeader() {
    return FutureBuilder<UserModel?>(
      future: _sellerFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(),
            title: Text('A carregar...'),
          );
        }
        final seller = snapshot.data;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                seller?.photoUrl != null && seller!.photoUrl!.isNotEmpty
                    ? NetworkImage(seller.photoUrl!)
                    : null,
            child: seller?.photoUrl == null || seller!.photoUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(seller?.name ?? 'Vendedor',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(timeago.format(widget.product.createdAt.toDate(),
              locale: 'pt_BR')),
        );
      },
    );
  }
}
