import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // PRODUCTS
  // ==========================================
  Future<void> addProduct(Product product) async {
    await _db.collection('products').doc(product.id).set(product.toJson());
  }

  Stream<List<Product>> getProductsStream() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ==========================================
  // CUSTOMERS
  // ==========================================
  Future<void> addCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).set(customer.toJson());
  }

  // 🔹 ESTA ES LA FUNCIÓN QUE TE DABA ERROR
  Future<void> updateCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).update({
      'balance': customer.balance,
      // Si en el futuro cambias nombre o celular, los agregas aquí
    });
  }

  Stream<List<Customer>> getCustomersStream() {
    return _db.collection('customers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> deleteCustomer(String id) async {
    await _db.collection('customers').doc(id).delete();
  }

  // ==========================================
  // SALES
  // ==========================================

  Future<void> addSale(Sale sale) async {
    final data = sale.toJson();
    // Usamos el Timestamp actual para Firebase
    data['date'] = Timestamp.fromDate(DateTime.now());
    await _db.collection('sales').add(data);
  }

  // 🔥 Historial por cliente (Completado para que funcione tu modal)
  Stream<List<Sale>> getSalesByCustomer(String customerId) {
    return _db
        .collection('sales')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Sale.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  // Cambia el estado de una venta de "Pendiente" a "Pagado"
  Future<void> markSaleAsPaid(String saleId) async {
    await _db.collection('sales').doc(saleId).update({'isPaid': true});
  }

  // Borrar una venta de la base de datos
  Future<void> deleteSale(String saleId) async {
    await _db.collection('sales').doc(saleId).delete();
  }

  Stream<List<Sale>> getTodaySalesStream() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Sale.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }
}
