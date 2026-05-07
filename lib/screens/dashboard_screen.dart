import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para manejar QuerySnapshot

// Core & Models
import '../core/app_state.dart';
import '../services/firestore_service.dart'; // Tu nuevo servicio
import '../models/sale.dart';
import '../models/customer.dart';

// Widgets
import '../widgets/sale_detail_modal.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onUpdate;
  final VoidCallback goToSales;

  const DashboardScreen({
    super.key,
    required this.onUpdate,
    required this.goToSales,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat currency = NumberFormat.simpleCurrency(locale: 'es_MX');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos StreamBuilder para que el Dashboard "viva" por sí solo
      body: StreamBuilder<List<Sale>>(
        stream: _firestoreService.getTodaySalesStream(),
        builder: (context, snapshot) {
          // Si no hay datos aún, mostramos tu diseño base con 0
          List<Sale> todaySales = snapshot.data ?? [];
          double total = todaySales
              .where((s) => s.isPaid)
              .fold(0.0, (sum, s) => sum + s.total);

          return CustomScrollView(
            slivers: [
              // 🔶 Header con resumen (Tu diseño original)
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          'FRUTERÍA TREJO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ), 
                        const SizedBox(height: 20),
                        const Text(
                          'Ventas Pagadas de Hoy',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          currency.format(total),
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: widget.goToSales,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('NUEVA VENTA'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 50),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔹 Título actividad
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: const [
                      Icon(Icons.history, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        'ACTIVIDAD RECIENTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 📋 Lista de ventas recientes (Desde Firebase Stream)
              if (todaySales.isEmpty && snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (todaySales.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: Text('No hay ventas hoy')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final s = todaySales[i];

                      // Buscamos el nombre del cliente en el AppState local
                      final customer = AppState.customers
                          .where((c) => c.id == s.customerId)
                          .firstOrNull;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: s.isPaid
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            child: Icon(
                              s.isPaid ? Icons.check_circle : Icons.timer,
                              color: s.isPaid ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(
                            customer?.name ?? 'Venta General',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(s.date)} • ${s.items.length} productos',
                          ),
                          trailing: Text(
                            currency.format(s.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () => showSaleDetail(
                            context,
                            s,
                            widget.onUpdate,
                          ),
                        ),
                      );
                    },
                    childCount: todaySales.length > 10 ? 10 : todaySales.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}