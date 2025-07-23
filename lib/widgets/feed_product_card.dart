import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../screens/product_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';

// MUDANÇA: Convertido de volta para um StatelessWidget
class FeedProductCard extends StatelessWidget {
  final ProductModel product;
  const FeedProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final authService = AuthService();
    final productService = ProductService();
    final currentUserId = authService.currentUser?.uid;
    // A verificação é feita diretamente aqui, sem estado local
    final isFavorited =
        currentUserId != null && product.favoritedBy.contains(currentUserId);

    // Define a localização para o pacote timeago
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // O cabeçalho agora obtém os dados diretamente
            _buildSellerHeader(context, authService),
            if (product.imageUrls.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    product.imageUrls.first,
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
                  if (currentUserId != null && product.userId != currentUserId)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited ? Colors.red : Colors.white,
                          ),
                          // A ação agora é direta, sem setState
                          onPressed: () {
                            productService.toggleFavoriteStatus(
                                product.id!, isFavorited);
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
                    product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormatter.format(product.price),
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

  Widget _buildSellerHeader(BuildContext context, AuthService authService) {
    return FutureBuilder<UserModel?>(
      future: authService.getUser(product.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
            leading: CircleAvatar(radius: 20),
            title: Text('A carregar...'),
          );
        }
        final seller = snapshot.data;
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
            timeago.format(product.createdAt.toDate(), locale: 'pt_BR'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: FutureBuilder<bool>(
            future: authService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showAdminMenu(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  void _showAdminMenu(BuildContext context) {
    final productService = ProductService();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Apagar Anúncio (Admin)'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();
                final success = await productService.deleteProduct(product);

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
