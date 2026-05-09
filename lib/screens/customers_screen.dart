import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Services
import '../services/firestore_service.dart';

// Core
import '../core/app_state.dart';

// Models
import '../models/customer.dart';
import '../models/sale.dart';

// Widgets
import '../widgets/sale_detail_modal.dart';

class CustomersScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const CustomersScreen({super.key, required this.onUpdate});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  // 🔹 Crear o editar cliente
  void _manageCustomer([Customer? c]) {
    final name = TextEditingController(text: c?.name ?? '');
    final phone = TextEditingController(text: c?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c == null ? 'Nuevo Cliente' : 'Editar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;

              if (c == null) {
                AppState.customers.add(
                  Customer(
                    id: DateTime.now().toString(),
                    name: name.text,
                    phone: phone.text,
                  ),
                );
              } else {
                c.name = name.text;
                c.phone = phone.text;
              }

              widget.onUpdate();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    c == null ? 'Cliente agregado' : 'Cliente actualizado',
                  ),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // 🔹 Eliminar cliente
  void _deleteCustomer(Customer c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Cliente?'),
        content: Text('Eliminar a ${c.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(c.id)
                  .delete();

              setState(() {
                AppState.customers.removeWhere((x) => x.id == c.id);
              });

              widget.onUpdate();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // 🔹 Historial de cliente (Con StreamBuilder hacia Firebase)
  void _showHistory(Customer c) {
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');

    showDialog(
      context: context,
      builder: (ctx) {
        final firestoreService = FirestoreService();

        return StreamBuilder<List<Sale>>(
          stream: firestoreService.getSalesByCustomer(c.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error de conexión'),
                content: Text('Revisa la consola: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final history = snapshot.data ?? [];

            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name),
                  Text(
                    'Adeudo: ${currency.format(c.balance)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: c.balance > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Sin movimientos',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (ctx, i) {
                          final sale = history[i];
                          return ListTile(
                            title: Text(
                              DateFormat('dd/MM/yy HH:mm').format(sale.date),
                            ),
                            subtitle: Text(
                              sale.isPaid ? 'PAGADO' : 'PENDIENTE',
                              style: TextStyle(
                                color: sale.isPaid ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // 🗑️ Agregamos el precio Y el botón de borrar
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currency.format(sale.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDeleteSale(
                                    c,
                                    sale,
                                  ), // Nueva función de borrado
                                ),
                              ],
                            ),
                            onTap: () =>
                                showSaleDetail(context, sale, widget.onUpdate),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                if (c.balance > 0)
                  ElevatedButton(
                    onPressed: () => _addPayment(c, () {
                      widget.onUpdate();
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Abonar'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSale(Customer c, Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar venta?'),
        content: Text(
          'Esta acción borrará el registro. Si es una deuda de ${sale.total}, el saldo del cliente se ajustará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final firestoreService = FirestoreService();

              // 1. Si la venta NO estaba pagada (era fiada), le restamos al balance
              if (!sale.isPaid) {
                c.balance -= sale.total;
                await firestoreService.updateCustomer(c);
              }

              // 2. Borramos la venta de Firebase
              await firestoreService.deleteSale(sale.id);

              if (!mounted) return;
              Navigator.pop(ctx); // Cerramos el aviso de confirmación

              // No necesitas cerrar el historial porque el StreamBuilder
              // detectará el cambio en Firebase y se refrescará solito.

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Venta eliminada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('BORRAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔹 Registrar abono inteligente (Liquida notas)
  void _addPayment(Customer c, VoidCallback onDone) {
    final ctrl = TextEditingController();
    final firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Abono'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Cantidad \$'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              double amount = double.tryParse(ctrl.text) ?? 0;

              if (amount > 0) {
                final navigator = Navigator.of(ctx);
                final scaffold = ScaffoldMessenger.of(context);

                c.balance -= amount;
                if (c.balance < 0) c.balance = 0;
                await firestoreService.updateCustomer(c);

                final snapshot = await FirebaseFirestore.instance
                    .collection('sales')
                    .where('customerId', isEqualTo: c.id)
                    .where('isPaid', isEqualTo: false)
                    .get();

                List<Sale> unpaidSales = snapshot.docs.map((doc) {
                  return Sale.fromJson(doc.data(), doc.id);
                }).toList();

                unpaidSales.sort((a, b) => a.date.compareTo(b.date));

                double totalDeudaEnNotas = 0;
                for (var s in unpaidSales) {
                  totalDeudaEnNotas += s.total;
                }

                double dineroDisponibleParaLiquidar =
                    totalDeudaEnNotas - c.balance;

                for (var s in unpaidSales) {
                  if (dineroDisponibleParaLiquidar >= s.total) {
                    await firestoreService.markSaleAsPaid(s.id);
                    dineroDisponibleParaLiquidar -= s.total;
                  } else {
                    break;
                  }
                }

                onDone();
                navigator.pop();

                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Abono registrado y notas liquidadas'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
    AppState.customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CLIENTES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFF9800)],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // 🟢 BUSCADOR DE CLIENTES (Autocompletado, idéntico al de ventas, sin escáner)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Autocomplete<Customer>(
                displayStringForOption: (c) => c.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<Customer>.empty();
                  }
                  return AppState.customers.where((Customer option) {
                    return option.name.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ) ||
                        option.phone.contains(textEditingValue.text);
                  });
                },
                onSelected: (Customer selection) {
                  _showHistory(selection); // Abre el historial al seleccionarlo
                  FocusScope.of(context).unfocus();
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o teléfono...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Colors.orange),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              textController.clear();
                              focusNode.unfocus();
                            },
                          ),
                        ),
                      );
                    },
              ),
            ),
          ),

          // 🟢 LISTA COMPLETA DE CLIENTES ABAJO
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: AppState.customers.length,
              itemBuilder: (ctx, i) {
                final c = AppState.customers[i];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c.phone),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Saldo', style: TextStyle(fontSize: 10)),
                            Text(
                              currency.format(c.balance),
                              style: TextStyle(
                                color: c.balance > 0
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _manageCustomer(c),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteCustomer(c),
                        ),
                      ],
                    ),

                    onTap: () => _showHistory(c),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _manageCustomer(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
