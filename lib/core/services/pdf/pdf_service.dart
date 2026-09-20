import 'dart:io';
import 'package:doc_scanner/features/home/model/document_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';

class PdfService {
  /// Generate an in-memory or temporary A4 PDF from a list of image paths
  static Future<String?> generatePdfFromImages(
    List<String> imagePaths,
    String docName,
  ) async {
    try {
      if (imagePaths.isEmpty) return null;

      final pdfDoc = pw.Document();

      for (final path in imagePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final pdfImage = pw.MemoryImage(bytes);

        pdfDoc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = docName.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final outputPath =
          '${tempDir.path}/${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(outputPath);
      await file.writeAsBytes(await pdfDoc.save());

      Logger().i('Generated dynamic PDF for share: $outputPath');
      return outputPath;
    } catch (e) {
      Logger().e('Failed to generate dynamic PDF: $e');
      return null;
    }
  }

  /// Share document either as a compiled PDF or as individual raw images
  static Future<void> shareDocument({
    required DocumentModel doc,
    required bool asPdf,
  }) async {
    try {
      if (doc.imagePaths.isEmpty) return;

      if (asPdf) {
        final pdfPath = await generatePdfFromImages(doc.imagePaths, doc.name);
        if (pdfPath != null) {
          await Share.shareXFiles(
            [XFile(pdfPath)],
            text: '${doc.name}.pdf',
            subject: doc.name,
          );
        }
      } else {
        final validFiles = doc.imagePaths
            .where((p) => File(p).existsSync())
            .map((p) => XFile(p))
            .toList();
        if (validFiles.isNotEmpty) {
          await Share.shareXFiles(
            validFiles,
            text: doc.name,
            subject: doc.name,
          );
        }
      }
    } catch (e) {
      Logger().e('Error sharing document: $e');
    }
  }
}
