import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/products_list.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  String? _selectedCity;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;
  final ProductService _productService = ProductService();
  final GlobalKey<ProductsListState> _productListKey =
      GlobalKey<ProductsListState>();

  @override
  void initState() {
    super.initState();
    // Mostra o pop-up uma única vez, depois de a tela ser construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFeaturedAdDialogIfNeeded();
    });
  }

  Future<void> _refreshProducts() async {
    _productListKey.currentState?.refresh();
  }

  // Função que mostra o pop-up de anúncios fixados
  void _showFeaturedAdDialogIfNeeded() async {
    final featuredAds = await _productService.getFeaturedProductsOnce();
    if (featuredAds.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: Container(
              width: double.maxFinite,
              height: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: featuredAds.length,
                    itemBuilder: (context, index) {
                      final product = featuredAds[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // Fecha o pop-up
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (product.imageUrls.isNotEmpty)
                                Image.network(product.imageUrls.first,
                                    fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 20,
                                right: 20,
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Botão para fechar o pop-up
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20.0),
              child: Wrap(
                runSpacing: 16,
                children: [
                  const Text('Filtrar e Ordenar Anúncios',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('Todas as Categorias'),
                    onChanged: (String? newValue) {
                      setModalState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    items: productCategories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    hint: const Text('Todas as Cidades'),
                    onChanged: (String? newValue) {
                      setModalState(() {
                        _selectedCity = newValue;
                      });
                    },
                    items: cityOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const Text('Ordenar por',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Mais Recentes'),
                        value: 'createdAt',
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setModalState(() {
                            _sortBy = value!;
                            _sortDescending = true;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Preço: Menor para Maior'),
                        value: 'price',
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setModalState(() {
                            _sortBy = value!;
                            _sortDescending = false;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Preço: Maior para Menor'),
                        value: 'price_desc',
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setModalState(() {
                            _sortBy = value!;
                            _sortDescending = true;
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedCity = null;
                            _sortBy = 'createdAt';
                            _sortDescending = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Limpar Tudo'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Prado Negócios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Pesquisar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: _showFilterPanel,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: ProductsList(
          key: _productListKey,
          selectedCategory: _selectedCategory,
          selectedCity: _selectedCity,
          sortBy: _sortBy == 'price_desc' ? 'price' : _sortBy,
          sortDescending: _sortDescending,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        tooltip: 'Adicionar Produto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
