import 'package:doc_scanner/core/services/document_storage/document_storage_service.dart';
import 'package:doc_scanner/core/services/pdf/pdf_service.dart';
import 'package:doc_scanner/features/home/model/document_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class HomeController extends GetxController {
  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final RxBool isLoading = false.obs;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    try {
      isLoading.value = true;
      final list = await DocumentStorageService.getAllDocuments();
      documents.assignAll(list);
    } catch (e) {
      Logger().e('Error loading documents: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await DocumentStorageService.deleteDocument(id);
      documents.removeWhere((d) => d.id == id);
      Get.snackbar('Deleted', 'Document removed successfully');
    } catch (e) {
      Logger().e('Error deleting document: $e');
    }
  }

  Future<void> renameDocument(String id, String newName) async {
    try {
      await DocumentStorageService.renameDocument(id, newName);
      final index = documents.indexWhere((d) => d.id == id);
      if (index != -1) {
        documents[index].name = newName.trim();
        documents.refresh();
      }
    } catch (e) {
      Logger().e('Error renaming document: $e');
    }
  }

  Future<void> shareDocument(DocumentModel doc, bool asPdf) async {
    await PdfService.shareDocument(doc: doc, asPdf: asPdf);
  }

  Future<void> importFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      final now = DateTime.now();
      final defaultName = 'Imported ${now.day}/${now.month} ${now.hour}:${now.minute}';
      final tempPaths = pickedFiles.map((x) => x.path).toList();

      final newDoc = await DocumentStorageService.createDocument(
        name: defaultName,
        tempImagePaths: tempPaths,
      );

      documents.insert(0, newDoc);
      Get.snackbar('Success', 'Imported ${pickedFiles.length} pages as new document');
    } catch (e) {
      Logger().e('Error importing from gallery: $e');
    }
  }
}
