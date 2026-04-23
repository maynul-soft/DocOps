import 'package:doc_scanner/core/export_path/export_path.dart';

class ScanNewDocController {
  static const Set<DocumentFormat> _documentFormats = {DocumentFormat.jpeg};
  List<String> imagePath = [];

  bool isContinueScanning = true;

  final DocumentScannerOptions _documentOptions = DocumentScannerOptions(
    documentFormats: _documentFormats,

    mode: ScannerMode.full, // to control what features are enabled
    pageLimit: 300, // setting a limit to the number of pages scanned
    isGalleryImport: true, // importing from the photo gallery
  );

  Future<void> scanNewDocument() async {
    final documentScanner = DocumentScanner(options: _documentOptions);

    DocumentScanningResult result = await documentScanner.scanDocument();

    List<String>? x = result.images;

    debugPrint(x.toString());
  }

}
