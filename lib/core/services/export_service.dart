import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/kpi_history.dart';

class ExportService {
  static Future<String> exportToCSV(List<KpiHistory> records) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      "Timestamp",
      "Temperature (°C)",
      "Vibration (mm/s)",
      "Current (A)",
      "Health Index",
      "RUL (hrs)",
      "OEE (%)",
      "Availability (%)",
      "Efficiency (%)",
      "MTBF (hrs)",
      "MTTR (hrs)",
      "Maintenance Cost (\$)",
      "Alert Status",
      "Mode"
    ]);

    // Data
    for (var record in records) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp),
        record.temperature.toStringAsFixed(2),
        record.vibration.toStringAsFixed(2),
        record.current.toStringAsFixed(2),
        record.healthIndex.toStringAsFixed(1),
        record.rul.toStringAsFixed(1),
        record.oee.toStringAsFixed(1),
        record.availability.toStringAsFixed(1),
        record.efficiency.toStringAsFixed(1),
        record.mtbf.toStringAsFixed(1),
        record.mttr.toStringAsFixed(1),
        record.maintenanceCost.toStringAsFixed(2),
        record.alertStatus,
        record.mode
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/kpi_history_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  static Future<String> exportToPDF(List<KpiHistory> records) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Digital Twin KPI History Report", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}"),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                "Time",
                "Mode",
                "Temp",
                "Vib",
                "OEE",
                "Health",
                "Status"
              ],
              data: records.map((record) => [
                DateFormat('MM-dd HH:mm').format(record.timestamp),
                record.mode,
                record.temperature.toStringAsFixed(1),
                record.vibration.toStringAsFixed(2),
                record.oee.toStringAsFixed(1),
                record.healthIndex.toStringAsFixed(1),
                record.alertStatus
              ]).toList(),
              border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/kpi_history_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
