import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Core
import '../core/app_state.dart';

// Models
import '../models/product.dart';

// Widgets
import '../widgets/barcode_scanner_widget.dart';

class InventoryScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const InventoryScreen({super.key, required this.onUpdate});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // 🔹 Crear o editar producto
  void _editProduct([Product? p]) {
    final name = TextEditingController(text: p?.name ?? '');
    final price = TextEditingController(text: p?.price.toString() ?? '');
    final id = TextEditingController(text: p?.id ?? '');
    bool isByWeight = p?.isByWeight ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(p == null ? 'Nuevo Producto' : 'Editar Producto'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Código + scanner
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: id,
                        decoration:
                            const InputDecoration(labelText: 'Código / SKU'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: Colors.orange),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BarcodeScannerWidget(
                              onDetect: (code) {
                                setStateDialog(() {
                                  id.text = code;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
                const SizedBox(height: 20,),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                      labelText: 'Nombre del Producto'),
                ),
                const SizedBox(height: 20,),
                TextField(
                  controller: price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Precio \$'),
                ),

                SwitchListTile(
                  title: const Text('Se vende por peso (kg)'),
                  value: isByWeight,
                  onChanged: (v) => setStateDialog(() => isByWeight = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),

            ElevatedButton(
              onPressed: () {
                final newId = id.text.trim();
                final newName = name.text.trim();

                if (newId.isEmpty || newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nombre y Código son obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validar duplicados
                final existingId = AppState.inventory
                    .where((x) => x.id == newId && x != p)
                    .isNotEmpty;

                final existingName = AppState.inventory
                    .where((x) =>
                        x.name.toLowerCase() ==
                            newName.toLowerCase() &&
                        x != p)
                    .isNotEmpty;

                if (existingId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El código "$newId" ya existe'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (existingName) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ya existe "$newName"'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (p == null) {
                  AppState.inventory.add(
                    Product(
                      id: newId,
                      name: newName,
                      price: double.tryParse(price.text) ?? 0,
                      stock: 0,
                      isByWeight: isByWeight,
                    ),
                  );
                } else {
                  p.id = newId;
                  p.name = newName;
                  p.price = double.tryParse(price.text) ?? 0;
                  p.isByWeight = isByWeight;
                }

                widget.onUpdate();
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }

  // 🔹 Eliminar producto
  void _deleteProduct(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Producto?'),
        content: Text('¿Eliminar "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async{
              await FirebaseFirestore.instance
              .collection('products')
              .doc(p.id)
              .delete();
              
              setState(() {
                AppState.inventory.removeWhere((x) => x.id == p.id);
              });

              widget.onUpdate();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          )
        ],
      ),
    );
  }

  // 🔹 Buscar por Escáner
  void _scanBarcode() async {
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) => BarcodeScannerWidget(onDetect: (code) {
      final p = AppState.inventory.where((x) => x.id == code).firstOrNull;
      if (p != null) {
        _editProduct(p);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Producto $code no encontrado')));
      }
    })));
  }

  @override
  Widget build(BuildContext context) {
    AppState.inventory.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INVENTARIO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2
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
          // 🟢 BUSCADOR REUTILIZADO DE VENTAS (Autocomplete + Escáner)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(15), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                  ),
                  child: Autocomplete<Product>(
                    displayStringForOption: (p) => p.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') return const Iterable<Product>.empty();
                      return AppState.inventory.where((Product option) {
                        return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                               option.id.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (Product selection) {
                      _editProduct(selection); // Abre la edición directamente
                      FocusScope.of(context).unfocus();
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...', 
                          border: InputBorder.none, 
                          icon: const Icon(Icons.search, color: Colors.orange),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
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
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _scanBarcode, 
                icon: const Icon(Icons.qr_code_scanner), 
                style: IconButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(15))
              ),
            ]),
          ),

          // 🟢 LISTA COMPLETA DE INVENTARIO ABAJO
          Expanded(
            child: AppState.inventory.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos registrados',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 80),
                    itemCount: AppState.inventory.length,
                    itemBuilder: (ctx, i) {
                      final p = AppState.inventory[i];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '\$${p.price.toStringAsFixed(2)} ${p.isByWeight ? "/ kg" : "/ pz"}'),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editProduct(p),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteProduct(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _editProduct(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}