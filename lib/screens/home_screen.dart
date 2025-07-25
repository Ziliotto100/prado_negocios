import 'package:flutter/material.dart';
import 'package:prado_negocios/models/advertisement_model.dart';
import 'package:prado_negocios/services/advertisement_service.dart';
import 'package:prado_negocios/widgets/advertisement_banner.dart';
import 'package:prado_negocios/widgets/app_drawer.dart';
import 'package:prado_negocios/widgets/products_list.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdvertisementService _advertisementService = AdvertisementService();
  AdvertisementModel? _bottomAd;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  void _loadAds() {
    _advertisementService.getAdvertisements().listen((ads) {
      if (!mounted) return;

      final popupAds = ads.where((ad) => ad.isPopup).toList();
      final bottomAds = ads.where((ad) => ad.isBottomFixed).toList();

      if (popupAds.isNotEmpty) {
        _showPopupAd(popupAds.first);
      }

      if (bottomAds.isNotEmpty) {
        setState(() {
          _bottomAd = bottomAds.first;
        });
      } else {
        setState(() {
          _bottomAd = null;
        });
      }
    });
  }

  void _showPopupAd(AdvertisementModel ad) {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (context) {
            final screenSize = MediaQuery.of(context).size;
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              backgroundColor: Colors.transparent,
              child: AdvertisementBanner(
                advertisement: ad,
                height: screenSize.height * 0.6, // Ocupa 60% da altura da tela
                width: screenSize.width,
                showCloseButton: true, // Mostra o botão de fechar no pop-up
                onClose: () {
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prado Negócios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Ação de busca
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const Expanded(
            child: ProductsList(
              sortBy: 'createdAt',
              sortDescending: true,
            ),
          ),
          if (_bottomAd != null)
            AdvertisementBanner(
              advertisement: _bottomAd!,
              height: 60,
              showCloseButton:
                  false, // Não mostra o botão de fechar no banner fixo
            ),
        ],
      ),
    );
  }
}
