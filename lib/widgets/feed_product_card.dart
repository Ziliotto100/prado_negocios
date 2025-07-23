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
  final ProductService _productService = ProductService();
  late Future<UserModel?> _sellerFuture;
  late Future<bool> _isAdminFuture;
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _sellerFuture = _authService.getUser(widget.product.userId);
    _isAdminFuture = _authService.isAdmin();
    _isFavorited = _authService.currentUser != null &&
        widget.product.favoritedBy.contains(_authService.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final currentUserId = _authService.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
            _buildSellerHeader(),
            if (widget.product.imageUrls.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    widget.product.imageUrls.first,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 50),
                    ),
                  ),
                  if (currentUserId != null &&
                      widget.product.userId != currentUserId)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: Icon(
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFavorited = !_isFavorited;
                            });
                            _productService.toggleFavoriteStatus(
                                widget.product.id!, !_isFavorited);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
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
    return FutureBuilder(
      future: Future.wait([_sellerFuture, _isAdminFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
            leading: CircleAvatar(radius: 20),
            title: Text('A carregar...'),
          );
        }

        final UserModel? seller = snapshot.data?[0];
        final bool isAdmin = snapshot.data?[1] ?? false;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          leading: CircleAvatar(
            radius: 20,
            backgroundImage:
                seller?.photoUrl != null && seller!.photoUrl!.isNotEmpty
                    ? NetworkImage(seller.photoUrl!)
                    : null,
            child: seller?.photoUrl == null || seller!.photoUrl!.isEmpty
                ? const Icon(Icons.person, size: 22)
                : null,
          ),
          title: Text(seller?.name ?? 'Vendedor',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            timeago.format(widget.product.createdAt.toDate(), locale: 'pt_BR'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: isAdmin
              ? IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showAdminMenu(context),
                )
              : null,
        );
      },
    );
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            // Lógica para Fixar/Remover dos Fixados
            ListTile(
              leading: Icon(
                widget.product.isFeatured
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                color: Colors.blue,
              ),
              title: Text(widget.product.isFeatured
                  ? 'Remover dos Fixados'
                  : 'Fixar Anúncio'),
              onTap: () async {
                Navigator.pop(context);
                await _productService.toggleFeaturedStatus(
                    widget.product.id!, widget.product.isFeatured);
              },
            ),
            // Lógica para Apagar o Anúncio
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Apagar Anúncio (Admin)'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();
                final success =
                    await _productService.deleteProduct(widget.product);

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                        content: Text('Anúncio apagado pelo administrador.')),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                        content: Text('Erro ao apagar o anúncio.'),
                        backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
