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
  final GlobalKey<ProductsListState> _productListKey =
      GlobalKey<ProductsListState>();

  Future<void> _refreshProducts() async {
    _productListKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Produtos'),
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
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtros
          _buildFilterChips(),
          // Lista de Produtos
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              child: ProductsList(
                key: _productListKey,
                selectedCategory: _selectedCategory,
                selectedCity: _selectedCity,
              ),
            ),
          ),
        ],
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

  // Widget que constrói as barras de filtro
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildChipRow(
            items: ['Todas', ...productCategories],
            selectedItem: _selectedCategory,
            onSelected: (item) {
              setState(() {
                _selectedCategory = (item == 'Todas') ? null : item;
              });
            },
          ),
          _buildChipRow(
            items: ['Todas', ...cityOptions],
            selectedItem: _selectedCity,
            onSelected: (item) {
              setState(() {
                _selectedCity = (item == 'Todas') ? null : item;
              });
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para criar uma linha de chips
  Widget _buildChipRow({
    required List<String> items,
    required String? selectedItem,
    required Function(String) onSelected,
  }) {
    // Adiciona "Todas" ao início da lista se não existir
    final displayItems = items.first == 'Todas' ? items : ['Todas', ...items];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          final isSelected =
              (selectedItem == null && item == 'Todas') || selectedItem == item;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) => onSelected(item),
            ),
          );
        },
      ),
    );
  }
}
