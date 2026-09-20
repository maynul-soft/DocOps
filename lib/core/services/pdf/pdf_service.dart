import 'dart:io';
import 'dart:typed_data';
import 'package:doc_scanner/features/home/model/document_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfService {
  /// Generate an in-memory or temporary A4 PDF from a list of image paths, optionally password protected
  static Future<String?> generatePdfFromImages(
    List<String> imagePaths,
    String docName, {
    String? password,
  }) async {
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

      Uint8List pdfBytes = await pdfDoc.save();

      // Apply 256-bit AES encryption if password is provided
      final isLocked = password != null && password.trim().isNotEmpty;
      if (isLocked) {
        final sfDoc = sf.PdfDocument(inputBytes: pdfBytes);
        sfDoc.security.userPassword = password.trim();
        sfDoc.security.ownerPassword = password.trim();
        sfDoc.security.algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit;
        sfDoc.security.permissions.addAll([
          sf.PdfPermissionsFlags.print,
          sf.PdfPermissionsFlags.copyContent,
        ]);
        pdfBytes = Uint8List.fromList(await sfDoc.save());
        sfDoc.dispose();
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = docName.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final suffix = isLocked ? '_locked' : '';
      final outputPath =
          '${tempDir.path}/$sanitizedName${suffix}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(outputPath);
      await file.writeAsBytes(pdfBytes);

      Logger().i('Generated dynamic PDF for share: $outputPath (Protected: $isLocked)');
      return outputPath;
    } catch (e) {
      Logger().e('Failed to generate dynamic PDF: $e');
      return null;
    }
  }

  /// Share document either as a compiled PDF (with optional password) or as individual raw images
  static Future<void> shareDocument({
    required DocumentModel doc,
    required bool asPdf,
    String? password,
  }) async {
    try {
      if (doc.imagePaths.isEmpty) return;

      if (asPdf) {
        final pdfPath = await generatePdfFromImages(
          doc.imagePaths,
          doc.name,
          password: password,
        );
        if (pdfPath != null) {
          final isLocked = password != null && password.trim().isNotEmpty;
          await Share.shareXFiles(
            [XFile(pdfPath)],
            text: isLocked
                ? '${doc.name} (🔒 Password Protected).pdf'
                : '${doc.name}.pdf',
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
