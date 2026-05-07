import 'package:ejemploia/services/firestore_service.dart';

// Importamos los modelos
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';

/// Estado global de la aplicación
class AppState {
  static final _service = FirestoreService();

  /// Inventario de productos
  static List<Product> inventory = [];

  /// Lista de clientes
  static List<Customer> customers = [];

  /// Historial de ventas
  static List<Sale> sales = [];

  /// Guarda los datos (Aunque con Firestore .set() ya se guardan al crearlos)
  static Future<void> saveAll() async {
    for (var p in inventory) {
      await _service.addProduct(p);
    }
    for (var c in customers) {
      await _service.addCustomer(c);
    }
  }

  /// 🔹 CORRECCIÓN: Escucha los cambios en tiempo real
  static void initListeners() {
    // Escuchar Productos
    _service.getProductsStream().listen((updatedProducts) {
      inventory = updatedProducts;
    });

    // Escuchar Clientes
    _service.getCustomersStream().listen((updatedCustomers) {
      customers = updatedCustomers;
    });

    // Escuchar Ventas de Hoy
    _service.getTodaySalesStream().listen((updatedSales) {
      sales = updatedSales;
    });
  }

  /// Mantenemos loadAll por compatibilidad, pero actualizado con los nuevos nombres
  static Future<void> loadAll() async {
    // .first obtiene la lista actual una sola vez
    inventory = await _service.getProductsStream().first;
    customers = await _service.getCustomersStream().first;
    sales = await _service.getTodaySalesStream().first;
  }
}