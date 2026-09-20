import 'dart:io';
import 'dart:typed_data';
import 'package:doc_scanner/features/home/model/document_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class DocumentStorageService {
  static const String boxName = 'documents_box';
  static Box? _box;

  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(boxName);
    Logger().i('DocumentStorageService initialized with ${_box!.length} documents.');
  }

  static Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }
    return _box!;
  }

  /// Base directory for all documents: app_dir/documents/
  static Future<Directory> getBaseDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  /// Create a new document folder, copy images cleanly, and store metadata in Hive
  static Future<DocumentModel> createDocument({
    required String name,
    required List<String> tempImagePaths,
  }) async {
    final box = await _getBox();
    final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final baseDir = await getBaseDocumentsDirectory();
    final docDir = Directory('${baseDir.path}/$docId');
    await docDir.create(recursive: true);

    final List<String> finalImagePaths = [];

    for (int i = 0; i < tempImagePaths.length; i++) {
      final sourceFile = File(tempImagePaths[i]);
      if (await sourceFile.exists()) {
        final targetPath = '${docDir.path}/page_$i.jpg';
        await sourceFile.copy(targetPath);
        finalImagePaths.add(targetPath);
      }
    }

    final now = DateTime.now();
    final doc = DocumentModel(
      id: docId,
      name: name.trim().isEmpty ? 'Doc ${now.day}/${now.month}/${now.year}' : name.trim(),
      folderPath: docDir.path,
      imagePaths: finalImagePaths,
      createdAt: now,
      updatedAt: now,
    );

    await box.put(docId, doc.toJson());
    Logger().i('Created document $docId with ${finalImagePaths.length} pages.');
    return doc;
  }

  /// Retrieve all documents sorted by updatedAt descending
  static Future<List<DocumentModel>> getAllDocuments() async {
    final box = await _getBox();
    final List<DocumentModel> docs = [];

    for (var key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        try {
          docs.add(DocumentModel.fromJson(raw as String));
        } catch (e) {
          Logger().e('Error deserializing doc $key: $e');
        }
      }
    }

    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  /// Get a single document by ID
  static Future<DocumentModel?> getDocument(String id) async {
    final box = await _getBox();
    final raw = box.get(id);
    if (raw != null) {
      try {
        return DocumentModel.fromJson(raw as String);
      } catch (e) {
        Logger().e('Error getting doc $id: $e');
      }
    }
    return null;
  }

  /// Rename a document
  static Future<void> renameDocument(String id, String newName) async {
    final doc = await getDocument(id);
    if (doc != null) {
      doc.name = newName.trim();
      doc.updatedAt = DateTime.now();
      final box = await _getBox();
      await box.put(id, doc.toJson());
    }
  }

  /// Delete document folder from disk and entry from Hive
  static Future<void> deleteDocument(String id) async {
    final doc = await getDocument(id);
    if (doc != null) {
      try {
        final dir = Directory(doc.folderPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        Logger().e('Error deleting doc directory: $e');
      }
    }
    final box = await _getBox();
    await box.delete(id);
    Logger().i('Deleted document $id.');
  }

  /// Append a new page to an existing document
  static Future<DocumentModel?> addPageToDocument(String id, String tempImagePath) async {
    final doc = await getDocument(id);
    if (doc == null) return null;

    final sourceFile = File(tempImagePath);
    if (!await sourceFile.exists()) return doc;

    final targetPath = '${doc.folderPath}/page_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await sourceFile.copy(targetPath);

    doc.imagePaths.add(targetPath);
    doc.updatedAt = DateTime.now();

    final box = await _getBox();
    await box.put(id, doc.toJson());
    return doc;
  }

  /// Delete a single page from a document
  static Future<DocumentModel?> deletePageFromDocument(String id, int pageIndex) async {
    final doc = await getDocument(id);
    if (doc == null || pageIndex < 0 || pageIndex >= doc.imagePaths.length) return doc;

    final pathToRemove = doc.imagePaths[pageIndex];
    try {
      final file = File(pathToRemove);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Logger().e('Error deleting page file: $e');
    }

    doc.imagePaths.removeAt(pageIndex);
    doc.updatedAt = DateTime.now();

    final box = await _getBox();
    await box.put(id, doc.toJson());
    return doc;
  }

  /// Update a page's image bytes (e.g. after drawing or rotating)
  static Future<void> updatePageImageBytes(String id, int pageIndex, Uint8List bytes) async {
    final doc = await getDocument(id);
    if (doc == null || pageIndex < 0 || pageIndex >= doc.imagePaths.length) return;

    final filePath = doc.imagePaths[pageIndex];
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    doc.updatedAt = DateTime.now();
    final box = await _getBox();
    await box.put(id, doc.toJson());
  }
}
