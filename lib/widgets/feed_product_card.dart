import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: widget.product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSellerHeader(),
            const SizedBox(height: 12),
            if (widget.product.imageUrls.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.product.imageUrls.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (currentUserId != null &&
                      widget.product.userId != currentUserId)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: IconButton(
                          icon: Icon(
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : Colors.white,
                            size: 20,
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
            const SizedBox(height: 12),
            Text(
              widget.product.name,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormatter.format(widget.product.price),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF34A853),
              ),
            )
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
          return const Row(children: [
            CircleAvatar(radius: 20),
            SizedBox(width: 8),
            Text('A carregar...')
          ]);
        }
        final seller = snapshot.data;
        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  seller?.photoUrl != null && seller!.photoUrl!.isNotEmpty
                      ? NetworkImage(seller.photoUrl!)
                      : null,
              child: seller?.photoUrl == null || seller!.photoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 22)
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller?.name ?? 'Vendedor',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeago.format(widget.product.createdAt.toDate(),
                      locale: 'pt_BR'),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
            const Spacer(),
            FutureBuilder<bool>(
              future: _isAdminFuture,
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
          ],
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
                }
              },
            ),
          ],
        );
      },
    );
  }
}
