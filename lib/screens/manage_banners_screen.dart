import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';
import '../services/advertisement_service.dart';
import 'add_advertisement_screen.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  final AdvertisementService _adService = AdvertisementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerir Publicidade'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('advertisements').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty)
            return const Center(
                child: Text('Nenhum banner publicitário ativo.'));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final banner =
                  BannerModel.fromFirestore(snapshot.data!.docs[index]);
              return Card(
                child: ListTile(
                  leading: Image.network(banner.imageUrl,
                      width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(banner.name), // <-- CORRIGIDO AQUI
                  subtitle: Text(banner.bannerType == 'popup'
                      ? 'Tipo: Pop-up'
                      : 'Tipo: Fixo Inferior'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _adService.deleteAdvertisement(
                        banner.id, banner.imageUrl),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const AddAdvertisementScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
