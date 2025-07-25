import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement_model.dart';
import 'dart:developer' as developer;

class AdvertisementBanner extends StatelessWidget {
  final AdvertisementModel advertisement;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final double? height;
  final double? width;

  const AdvertisementBanner({
    super.key,
    required this.advertisement,
    this.onClose,
    this.showCloseButton = true,
    this.height,
    this.width,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      developer.log('Could not launch $urlString', name: 'AdvertisementBanner');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (advertisement.redirectUrl.isNotEmpty) {
          _launchURL(advertisement.redirectUrl);
        }
      },
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(showCloseButton ? 8.0 : 0.0),
                child: CachedNetworkImage(
                  imageUrl: advertisement.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            if (showCloseButton)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: onClose,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        const Color.fromRGBO(0, 0, 0, 0.5)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
