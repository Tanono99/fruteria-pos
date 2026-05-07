import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Core
import '../core/app_state.dart';

// Models
import '../models/sale.dart';
import '../models/customer.dart';

// Services
import '../services/firestore_service.dart';

/// Muestra el detalle de una venta en un modal
void showSaleDetail(
  BuildContext context,
  Sale sale,
  VoidCallback onUpdate,
) {
  final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
  // Instanciamos el servicio de Firebase
  final FirestoreService firestoreService = FirestoreService();

  final Customer? customer = AppState.customers
      .where((c) => c.id == sale.customerId)
      .isNotEmpty
      ? AppState.customers.firstWhere((c) => c.id == sale.customerId)
      : null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔘 Barra superior
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Detalle de Ticket',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              DateFormat('dd MMMM yyyy, HH:mm').format(sale.date),
              style: TextStyle(color: Colors.grey[600]),
            ),

            // 👤 Cliente
            if (customer != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Cliente: ${customer.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),

            // 🛒 Lista de productos
            if (sale.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No hay productos para mostrar en este ticket', style: TextStyle(color: Colors.grey)),
              )
            else
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${item.quantity.toStringAsFixed(item.product.isByWeight ? 2 : 0)}'
                            '${item.product.isByWeight ? "kg" : "pz"} x '
                            '${currency.format(item.product.price)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        currency.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),

            const Divider(height: 32),

            // 💰 Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  currency.format(sale.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ✅ Botón pagar
            if (!sale.isPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Marcar como pagado en Firebase
                    await firestoreService.markSaleAsPaid(sale.id);
                    sale.isPaid = true;

                    // 2. Descontar el saldo del cliente en Firebase
                    if (customer != null) {
                      customer.balance -= sale.total;
                      if (customer.balance < 0) {
                        customer.balance = 0;
                      }
                      await firestoreService.updateCustomer(customer);
                    }

                    onUpdate();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pago registrado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'MARCAR COMO PAGADO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}