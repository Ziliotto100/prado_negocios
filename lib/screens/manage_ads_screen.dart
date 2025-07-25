import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/advertisement_model.dart';
import '../services/advertisement_service.dart';
import 'add_advertisement_screen.dart';
import 'edit_advertisement_screen.dart';

class ManageAdsScreen extends StatefulWidget {
  const ManageAdsScreen({super.key});

  @override
  State<ManageAdsScreen> createState() => _ManageAdsScreenState();
}

class _ManageAdsScreenState extends State<ManageAdsScreen> {
  final AdvertisementService _advertisementService = AdvertisementService();

  void _deleteAd(String id, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            const Text('Você tem certeza que deseja excluir este anúncio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _advertisementService.deleteAdvertisement(id, imageUrl);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anúncio excluído com sucesso!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir anúncio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Anúncios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AddAdvertisementScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AdvertisementModel>>(
        stream: _advertisementService.getAdvertisements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum anúncio encontrado.'));
          }

          final ads = snapshot.data!;
          final popupAds = ads.where((ad) => ad.isPopup).toList();
          final bottomFixedAds = ads.where((ad) => ad.isBottomFixed).toList();

          return ListView(
            children: [
              _buildAdListSection(
                context,
                title: 'Anúncios Fixos (Inferior)',
                ads: bottomFixedAds,
              ),
              if (bottomFixedAds.isNotEmpty && popupAds.isNotEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(thickness: 1),
                ),
              _buildAdListSection(
                context,
                title: 'Anúncios Pop-up',
                ads: popupAds,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdListSection(BuildContext context,
      {required String title, required List<AdvertisementModel> ads}) {
    if (ads.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: ListTile(
                leading: CachedNetworkImage(
                  imageUrl: ad.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                title: Text(ad.title),
                subtitle: Text(ad.redirectUrl, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              EditAdvertisementScreen(advertisement: ad),
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAd(ad.id, ad.imageUrl),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
