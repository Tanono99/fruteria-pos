import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/customer.dart';

class TicketHelper {
  static Future<void> compartirPDF(Sale sale, Customer? customer) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Formato tipo ticket de 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("FRUTERIA TREJO", 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.Center(child: pw.Text("Mazatlan, Sinaloa")),
              pw.Divider(),
              pw.Text("Fecha: ${DateFormat('dd/MM/yy HH:mm').format(sale.date)}"),
              pw.Text("Cliente: ${customer?.name ?? 'Publico General'}"),
              pw.Divider(),
              
              // Tabla de productos
              pw.Table(
                children: [
                  pw.TableRow(children: [
                    pw.Text("Prod.", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Cant.", textAlign: pw.TextAlign.right),
                    pw.Text("Total", textAlign: pw.TextAlign.right),
                  ]),
                  ...sale.items.map((item) => pw.TableRow(children: [
                    pw.Text(item.product.name),
                    pw.Text(item.quantity.toString(), textAlign: pw.TextAlign.right),
                    pw.Text(currency.format(item.total), textAlign: pw.TextAlign.right),
                  ])),
                ],
              ),
              
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(currency.format(sale.total), 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(sale.isPaid ? "PAGADO" : "PENDIENTE DE PAGO",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("¡Gracias por su compra!")),
            ],
          );
        },
      ),
    );

    // Guardar temporalmente y compartir
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/ticket_${sale.id}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Ticket de compra - Frutería Trejo');
  }
}