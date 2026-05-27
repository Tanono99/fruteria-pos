import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejemploia/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Core
import '../core/app_state.dart';

// Models
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

// Widgets
import '../widgets/barcode_scanner_widget.dart';

class SalesScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const SalesScreen({super.key, required this.onUpdate});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<SaleItem> cart = [];
  Customer? selectedCustomer;
  bool _isProcessing = false;

  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  // 🔹 Agregar producto al carrito CORREGIDO (Separación de memoria para Mayoreo)
  void _addItem(Product p) {
    final index = cart.indexWhere((x) => x.product.id == p.id);

    if (p.isByWeight) {
      final ctrl = TextEditingController();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ingresar peso: ${p.name}'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              suffixText: 'kg',
              hintText: '0.00',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(ctrl.text);
                if (w != null && w > 0) {
                  setState(() {
                    if (index >= 0) {
                      // 🟢 Si ya existe, mantenemos la instancia que ya estaba en el carrito
                      // (Así si ya le habías cambiado el precio a mayoreo, no se pierde)
                      final itemExistente = cart[index];
                      final nuevaCant = itemExistente.quantity + w;
                      
                      cart[index] = SaleItem(
                        product: itemExistente.product, // 👈 Mantiene el producto modificado
                        quantity: nuevaCant,
                        total: itemExistente.product.price * nuevaCant,
                      );
                    } else {
                      // 🟢 Si es nuevo, usamos p.copy() para clonarlo e independizarlo
                      final productoClonado = p.copy();
                      cart.add(
                        SaleItem(
                          product: productoClonado, 
                          quantity: w, 
                          total: productoClonado.price * w,
                        ),
                      );
                    }
                    _searchController.clear();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      );
    } else {
      // 🍎 Lógica para productos por PIEZA
      setState(() {
        if (index >= 0) {
          // 🟢 Si ya existe, mantenemos el producto del carrito para respetar su precio de mayoreo
          final itemExistente = cart[index];
          final nuevaCant = itemExistente.quantity + 1;
          
          cart[index] = SaleItem(
            product: itemExistente.product, // 👈 Mantiene el producto modificado
            quantity: nuevaCant,
            total: itemExistente.product.price * nuevaCant,
          );
        } else {
          // 🟢 Si es nuevo en el carrito, usamos p.copy() para aislar su precio
          final productoClonado = p.copy();
          cart.add(
            SaleItem(
              product: productoClonado, 
              quantity: 1, 
              total: productoClonado.price,
            ),
          );
        }
        _searchController.clear();
      });
    }
  }

  // 🔹 Quitar producto
  void _removeItem(int index) {
    setState(() {
      if (cart[index].product.isByWeight) {
        cart.removeAt(index);
      } else {
        if (cart[index].quantity > 1) {
          cart[index].quantity--;
        } else {
          cart.removeAt(index);
        }
      }
    });
  }

  // 🔹 Escanear código
  void _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BarcodeScannerWidget(
          onDetect: (code) {
            final p = AppState.inventory.where((x) => x.id == code).firstOrNull;

            if (p != null) {
              _addItem(p);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Producto $code no encontrado')),
              );
            }
          },
        ),
      ),
    );
  }

  // 🔹 Snackbar bonito
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _updateProductPrice(BuildContext context, dynamic item) async {
    final TextEditingController priceController = TextEditingController(
      text: item.product.price.toString(),
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar precio de ${item.product.name}'),
          content: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nuevo Precio',
              prefixText: '\$ ',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                double? newPrice = double.tryParse(priceController.text);

                if (newPrice != null && newPrice >= 0) {
                  try {
                    // 1. ACTUALIZAR EN TU COLECCIÓN REAL: 'products'
                    await FirebaseFirestore.instance
                        .collection('products') // 🟢 Corregido según tu imagen
                        .doc(
                          item.product.id.toString().trim(),
                        ) // Aseguramos que el ID vaya limpio como String (ej: "1")
                        .update({
                          'price':
                              newPrice, // Mapea directo al campo price de tu Firebase
                        });

                    // 2. ACTUALIZAR LOCALMENTE EN LA PANTALLA
                    setState(() {
                      item.product.price = newPrice;
                    });

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Precio de ${item.product.name} actualizado en Firebase',
                        ),
                      ),
                    );
                  } catch (e) {
                    // Esto te imprimirá en la consola de tu computadora el motivo exacto si vuelve a fallar
                    print("ERROR DETECTADO AL ACTUALIZAR: $e");

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyWholesalePrice(BuildContext context, dynamic item) async {
    // El control de texto inicia con el precio actual que tiene en el carrito
    final TextEditingController wholesalePriceController =
        TextEditingController(text: item.product.price.toString());

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Precio especial para ${item.product.name}'),
          content: TextField(
            controller: wholesalePriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio de Mayoreo (Solo esta venta)',
              prefixText: '\$ ',
              helperText: 'No modificará el precio base del inventario.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Aplicar'),
              onPressed: () {
                double? newPrice = double.tryParse(
                  wholesalePriceController.text,
                );

                if (newPrice != null && newPrice >= 0) {
                  // 🟢 Actualizamos únicamente el estado en memoria de esta pantalla
                  setState(() {
                    item.product.price = newPrice;
                    // Si tu clase 'item' no calcula el total automáticamente,
                    // puedes forzarlo aquí (ej: item.total = newPrice * item.quantity;)
                  });

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
    final total = cart.fold(0.0, (s, it) => s + it.total);
    final TextEditingController _customerController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PUNTO DE VENTA',
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
          // 🔍 BUSCADOR
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Autocomplete<Product>(
                      displayStringForOption: (p) => p.name,
                      optionsBuilder: (text) {
                        if (text.text == '') {
                          return const Iterable<Product>.empty();
                        }
                        return AppState.inventory.where(
                          (p) => p.name.toLowerCase().contains(
                            text.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (p) {
                        _addItem(p);
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder:
                          (context, textController, focusNode, _) {
                            textController.addListener(() {
                              if (textController.text !=
                                  _searchController.text) {
                                _searchController.text = textController.text;
                              }
                            });

                            _searchController.addListener(() {
                              if (textController.text !=
                                  _searchController.text) {
                                textController.text = _searchController.text;
                              }
                            });

                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                hintText: 'Buscar producto...',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.orange),
                              ),
                            );
                          },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ],
            ),
          ),

          // 🛒 LISTA
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      'Carrito vacío',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (ctx, i) {
                      final item = cart[i];

                      return ListTile(
                        // AGREGADO: Al picar el nombre del producto, se abre el editor
                        title: InkWell(
                          onTap: () => _updateProductPrice(context, item),
                          child: Text(
                            item.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration
                                  .underline, // Opcional: una línea abajo sutil para notar que es clicable
                              decorationStyle: TextDecorationStyle.dashed,
                            ),
                          ),
                        ),
                        subtitle: Text(
                          '${currency.format(item.product.price)} x ${item.quantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currency.format(item.total)),
                            const SizedBox(width: 8), // Espacio sutil
                            // 🟢 BOTÓN NUEVO: Para aplicar precio de mayoreo / especial en esta venta
                            IconButton(
                              icon: const Icon(
                                Icons.label_outline,
                                color: Colors.green,
                              ),
                              tooltip: 'Precio especial',
                              onPressed: () =>
                                  _applyWholesalePrice(context, item),
                            ),

                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _removeItem(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addItem(item.product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 🔍 Buscador de cliente PRO (igual que productos)
          Autocomplete<Customer>(
            displayStringForOption: (c) => c.name,

            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Customer>.empty();
              }

              return AppState.customers.where((c) {
                return c.name.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },

            onSelected: (Customer selection) {
              setState(() {
                selectedCustomer = selection;
                _customerController.clear(); // 🔥 limpia input
              });

              FocusScope.of(context).unfocus();
            },

            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
                  // 🔁 sincronización EXACTA como productos
                  textController.addListener(() {
                    if (textController.text != _customerController.text) {
                      _customerController.text = textController.text;
                    }
                  });

                  _customerController.addListener(() {
                    if (textController.text != _customerController.text) {
                      textController.text = _customerController.text;
                    }
                  });

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: selectedCustomer == null
                            ? 'Buscar cliente...'
                            : 'Cliente seleccionado',
                        prefixIcon: const Icon(Icons.person_search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  );
                },
          ),

          const SizedBox(height: 10),

          // 👤 Cliente seleccionado (card visual PRO)
          if (selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.orange),
                    const SizedBox(width: 10),

                    // Nombre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCustomer!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            selectedCustomer!.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Saldo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Saldo', style: TextStyle(fontSize: 10)),
                        Text(
                          '\$${selectedCustomer!.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: selectedCustomer!.balance > 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // ❌ Quitar cliente
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          selectedCustomer = null;
                          _customerController.clear(); // 🔥 limpia también aquí
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 15),

          // 💳 TOTAL Y BOTONES
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'TOTAL: ${currency.format(total)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 🟢 BOTÓN COBRAR
                    Expanded(
                      child: ElevatedButton(
                        // 🔥 1. CANDADO AQUÍ: Si el carrito está vacío o ESTÁ PROCESANDO, se bloquea (null)
                        onPressed: (cart.isEmpty || _isProcessing)
                            ? null
                            : () async {
                                // 🔥 2. PONEMOS EL CANDADO
                                setState(() {
                                  _isProcessing = true;
                                });

                                final sale = Sale(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  items: List.from(cart),
                                  date: DateTime.now(),
                                  isPaid: true,
                                  total: total,
                                  customerId: selectedCustomer?.id,
                                );

                                // Guardar en Firebase
                                await _firestoreService.addSale(sale);

                                // Protección para la pantalla
                                if (!mounted) return;

                                _showMessage('¡VENTA REALIZADA!', Colors.green);

                                setState(() {
                                  cart.clear();
                                  selectedCustomer = null;
                                  // 🔥 3. QUITAMOS EL CANDADO
                                  _isProcessing = false;
                                });

                                widget.onUpdate();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        // 🔥 4. EFECTO VISUAL: Si está procesando, muestra la bolita dando vueltas
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('COBRAR'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 🧾 BOTÓN FIAR
                    if (selectedCustomer != null)
                      Expanded(
                        child: ElevatedButton(
                          // 🔥 1. CANDADO AQUÍ TAMBIÉN
                          onPressed: (cart.isEmpty || _isProcessing)
                              ? null
                              : () async {
                                  // 🔥 2. PONEMOS EL CANDADO
                                  setState(() {
                                    _isProcessing = true;
                                  });

                                  final sale = Sale(
                                    id: DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    items: List.from(cart),
                                    date: DateTime.now(),
                                    isPaid: false, // Es deuda
                                    total: total,
                                    customerId: selectedCustomer!.id,
                                  );

                                  // Guardar en Firebase
                                  await _firestoreService.addSale(sale);

                                  // Actualizar adeudo
                                  selectedCustomer!.balance += total;
                                  await _firestoreService.updateCustomer(
                                    selectedCustomer!,
                                  );

                                  // Protección para la pantalla
                                  if (!mounted) return;

                                  _showMessage(
                                    'FIADO A ${selectedCustomer!.name.toUpperCase()}',
                                    Colors.orange,
                                  );

                                  setState(() {
                                    cart.clear();
                                    selectedCustomer = null;
                                    // 🔥 3. QUITAMOS EL CANDADO
                                    _isProcessing = false;
                                  });

                                  widget.onUpdate();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          // 🔥 4. EFECTO VISUAL AQUÍ TAMBIÉN
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('FIAR'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
