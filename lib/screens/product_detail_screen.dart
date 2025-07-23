import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AuthService _authService = AuthService();
  late Future<UserModel?> _sellerFuture;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _sellerFuture = _authService.getUser(widget.product.userId);
  }

  void _startChat(BuildContext context) async {
    final chatService = ChatService();
    final authService = AuthService();
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == widget.product.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Você não pode iniciar uma conversa sobre o seu próprio produto.')),
      );
      return;
    }

    try {
      final chatRoomId = await chatService.getOrCreateChatRoom(widget.product);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              productName: widget.product.name,
            ),
          ),
        );
      }
    } catch (e) {
      print("Erro ao iniciar chat: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível iniciar a conversa.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormatter = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.imageUrls.isNotEmpty)
              _buildImageCarousel(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Publicado em: ${dateFormatter.format(widget.product.createdAt.toDate())}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  _buildSellerInfo(context),
                  const Divider(height: 32),
                  const Text(
                    'Descrição',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startChat(context),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Contactar Vendedor'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GalleryScreen(
            imageUrls: widget.product.imageUrls,
            initialIndex: _currentImageIndex,
          ),
        ));
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: widget.product.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Hero(
                  tag: 'product_image_${widget.product.id}_$index',
                  child: Image.network(
                    widget.product.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Icon(Icons.broken_image,
                              size: 100, color: Colors.grey));
                    },
                  ),
                );
              },
            ),
          ),
          if (widget.product.imageUrls.length > 1)
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.product.imageUrls.map((url) {
                  int index = widget.product.imageUrls.indexOf(url);
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _sellerFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final seller = snapshot.data;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage:
                seller?.photoUrl != null && seller!.photoUrl!.isNotEmpty
                    ? NetworkImage(seller.photoUrl!)
                    : null,
            child: seller?.photoUrl == null || seller!.photoUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title:
              const Text('Vendido por', style: TextStyle(color: Colors.grey)),
          subtitle: Text(
            seller?.name ?? 'Vendedor desconhecido',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            if (seller != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: seller.id),
                ),
              );
            }
          },
        );
      },
    );
  }
}
