import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/advertisement_service.dart';

class AddAdvertisementScreen extends StatefulWidget {
  const AddAdvertisementScreen({Key? key}) : super(key: key);

  @override
  _AddAdvertisementScreenState createState() => _AddAdvertisementScreenState();
}

class _AddAdvertisementScreenState extends State<AddAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _advertisementService = AdvertisementService();
  final _titleController = TextEditingController();
  final _redirectUrlController = TextEditingController();
  File? _image;
  bool _isPopup = true; // Default to Pop-up
  bool _isBottomFixed = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitAdvertisement() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione uma imagem.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageUrl =
            await _advertisementService.uploadAdImage(_image!, fileName);

        final adData = {
          'title': _titleController.text,
          'imageUrl': imageUrl,
          'redirectUrl': _redirectUrlController.text,
          'isPopup': _isPopup,
          'isBottomFixed': _isBottomFixed,
          'createdAt': DateTime.now(),
        };

        await _advertisementService.addAdvertisement(adData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anúncio adicionado com sucesso!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar anúncio: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
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
        title: const Text('Adicionar Novo Anúncio'),
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
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 50),
                                    Text('Clique para selecionar uma imagem'),
                                  ],
                                ),
                              ),
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

                    // --- SELEÇÃO DE TIPO DE ANÚNCIO ATUALIZADA ---
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
                      groupValue: _isPopup, // Agrupado pela mesma variável
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _isPopup = value;
                            _isBottomFixed = !value;
                          });
                        }
                      },
                    ),
                    // --- FIM DA SELEÇÃO ATUALIZADA ---

                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitAdvertisement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Salvar Anúncio'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
