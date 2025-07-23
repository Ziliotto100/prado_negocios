import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/products_list.dart';
import 'add_product_screen.dart';
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

  final GlobalKey<ProductsListState> _productListKey =
      GlobalKey<ProductsListState>();

  Future<void> _refreshProducts() async {
    _productListKey.currentState?.refresh();
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
        title: const Text('Prado Negócios'), // <-- TEXTO ALTERADO AQUI
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
