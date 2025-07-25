import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/advertisement_model.dart';
import '../services/advertisement_service.dart';

class EditAdvertisementScreen extends StatefulWidget {
  final AdvertisementModel advertisement;

  const EditAdvertisementScreen({super.key, required this.advertisement});

  @override
  State<EditAdvertisementScreen> createState() =>
      _EditAdvertisementScreenState();
}

class _EditAdvertisementScreenState extends State<EditAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _advertisementService = AdvertisementService();
  late TextEditingController _titleController;
  late TextEditingController _redirectUrlController;
  File? _image;
  String? _networkImage;
  bool _isPopup = true;
  bool _isBottomFixed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.advertisement.title);
    _redirectUrlController =
        TextEditingController(text: widget.advertisement.redirectUrl);
    _isPopup = widget.advertisement.isPopup;
    _isBottomFixed = widget.advertisement.isBottomFixed;
    _networkImage = widget.advertisement.imageUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _networkImage =
            null; // Limpa a imagem da rede se uma nova imagem local for escolhida
      });
    }
  }

  Future<void> _updateAdvertisement() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _advertisementService.uploadAdImage(
              _image!, DateTime.now().toIso8601String());
        } else {
          imageUrl = _networkImage;
        }

        if (imageUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao carregar a imagem.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        Map<String, dynamic> adData = {
          'title': _titleController.text,
          'redirectUrl': _redirectUrlController.text,
          'imageUrl': imageUrl,
          'isPopup': _isPopup,
          'isBottomFixed': _isBottomFixed,
        };

        await _advertisementService.updateAdvertisement(
            widget.advertisement.id, adData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anúncio atualizado com sucesso!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar anúncio: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _redirectUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Anúncio'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: _image != null
                            ? Image.file(_image!, fit: BoxFit.cover)
                            : (_networkImage != null &&
                                    _networkImage!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _networkImage!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, size: 50),
                                        Text(
                                            'Clique para selecionar uma imagem'),
                                      ],
                                    ),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Anúncio',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um título.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _redirectUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de Redirecionamento',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma URL.';
                        }
                        if (!Uri.parse(value).isAbsolute) {
                          return 'Por favor, insira uma URL válida.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Tipo de Anúncio:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    RadioListTile<bool>(
                      title: const Text('Anúncio Pop-up'),
                      value: true,
                      groupValue: _isPopup,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _isPopup = value;
                            _isBottomFixed = !value;
                          });
                        }
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Anúncio Fixo Inferior'),
                      value: false,
                      groupValue: _isPopup,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _isPopup = value;
                            _isBottomFixed = !value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _updateAdvertisement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Atualizar Anúncio'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
