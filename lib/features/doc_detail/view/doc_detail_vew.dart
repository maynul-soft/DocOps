import 'dart:io';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/core/services/document_storage/document_storage_service.dart';
import 'package:doc_scanner/core/services/pdf/pdf_service.dart';
import 'package:doc_scanner/features/home/controller/home_controller.dart';
import 'package:doc_scanner/features/home/model/document_model.dart';

class DocDetailVew extends StatefulWidget {
  const DocDetailVew({super.key});

  static const name = 'Doc detail view';

  @override
  State<DocDetailVew> createState() => _DocDetailVewState();
}

class _DocDetailVewState extends State<DocDetailVew> {
  final TextEditingController _nameController = TextEditingController();
  DocumentModel? _document;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_document == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is DocumentModel) {
        _document = args;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _refreshDocument() async {
    if (_document == null) return;
    final updated = await DocumentStorageService.getDocument(_document!.id);
    if (updated != null && mounted) {
      setState(() {
        _document = updated;
      });
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadDocuments();
      }
    }
  }

  void _onTapShare() {
    if (_document == null || _document!.imagePaths.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share "${_document!.name}"',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how you want to export your document:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text('Share as PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Dynamic compiled multi-page A4 PDF file'),
                onTap: () {
                  Navigator.pop(ctx);
                  PdfService.shareDocument(doc: _document!, asPdf: true);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image, color: Colors.blue),
                ),
                title: const Text('Share as Images', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Individual full-resolution JPG page images'),
                onTap: () {
                  Navigator.pop(ctx);
                  PdfService.shareDocument(doc: _document!, asPdf: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapAddNewPage() async {
    if (_document == null) return;
    await Navigator.pushNamed(context, CustomCameraScreen.name);
    final camController = Get.find<CustomCameraController>();
    if (camController.capturedImages.isNotEmpty) {
      for (final newImg in camController.capturedImages) {
        await DocumentStorageService.addPageToDocument(_document!.id, newImg);
      }
      camController.capturedImages.clear();
      await _refreshDocument();
    }
  }

  void _onTapDeletePage(int index) async {
    if (_document == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Are you sure you want to delete page ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await DocumentStorageService.deletePageFromDocument(_document!.id, index);
              await _refreshDocument();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Details')),
        body: const Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          doc.name,
          overflow: TextOverflow.ellipsis,
          style: CustomTextTheme.fontSize18bold(context),
        ),
        actions: [
          IconButton(
            onPressed: editDocNameWidget,
            icon: const Icon(Icons.drive_file_rename_outline, color: Color(0xFF334155)),
          ),
          IconButton(
            onPressed: _onTapShare,
            icon: const Icon(Icons.share_outlined, color: Color(0xFF334155)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: doc.imagePaths.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            childAspectRatio: 0.70,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (BuildContext context, int index) {
            return index < doc.imagePaths.length
                ? buildDocImageCard(doc.imagePaths[index], index)
                : buildAddNewPageCard();
          },
        ),
      ),
    );
  }

  Widget buildDocImageCard(String imagePath, int index) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          EditDocView.name,
          arguments: imagePath,
        );
        await _refreshDocument();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              File(imagePath).existsSync()
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
              // Page badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Delete icon button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _onTapDeletePage(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAddNewPageCard() {
    return InkWell(
      onTap: _onTapAddNewPage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 32,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Page',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> editDocNameWidget() {
    if (_document == null) return Future.value();
    _nameController.text = _document!.name;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rename Document',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: CustomTextTheme.fontSize16(context),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = _nameController.text.trim();
                        if (newName.isNotEmpty && _document != null) {
                          await DocumentStorageService.renameDocument(_document!.id, newName);
                          await _refreshDocument();
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
