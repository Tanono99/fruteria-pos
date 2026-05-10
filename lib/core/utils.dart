import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Importante usar esta
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/customer.dart';

class TicketHelper {
  static Future<void> compartirPDF(Sale sale, Customer? customer) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');

    // 1. DIBUJAR EL PDF (Mismo diseño de ticket)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, 
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
              
              pw.Table(
                children: [
                  pw.TableRow(children: [
                    pw.Text("Prod.", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Cant.", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
                  ...sale.items.map((item) => pw.TableRow(children: [
                    pw.Text(item.product.name),
                    pw.Text(item.quantity.toStringAsFixed(1), textAlign: pw.TextAlign.right),
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

    // 2. COMPARTIR (COMPATIBLE CON WEB)
    // Convertimos el documento a "bytes" (información pura)
    final bytes = await pdf.save();

    // La librería Printing se encarga de todo dependiendo de si es Web o Celular
    await Printing.sharePdf(
      bytes: bytes, 
      filename: 'ticket_trejo_${sale.id}.pdf'
    );
  }
}