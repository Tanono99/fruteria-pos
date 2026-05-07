import 'package:flutter/material.dart';

// Core
import '../core/app_state.dart';

// Screens
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'inventory_screen.dart';
import 'customers_screen.dart';

/// Pantalla principal con navegación inferior
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Cargar datos al iniciar la app
  Future<void> _init() async {
    await AppState.loadAll();
    setState(() => _loading = false);
  }

  /// Se ejecuta cuando hay cambios en la app
  void _onUpdate() {
    AppState.saveAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Mientras carga datos
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Lista de pantallas
    final screens = [
      DashboardScreen(
        onUpdate: _onUpdate,
        goToSales: () => setState(() => _selectedIndex = 1),
      ),
      SalesScreen(onUpdate: _onUpdate),
      InventoryScreen(onUpdate: _onUpdate),
      CustomersScreen(onUpdate: _onUpdate),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),

      // Barra inferior
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: const Color(0xFFFFF3E0),

        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_rounded),
            label: 'Venta',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_rounded),
            label: 'Clientes',
          ),
        ],
      ),
    );
  }
}

