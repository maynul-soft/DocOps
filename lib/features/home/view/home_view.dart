import 'dart:io';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/features/home/controller/home_controller.dart';
import 'package:doc_scanner/features/home/model/document_model.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  static const name = 'Home view';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController homeController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    homeController.loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Documents',
          style: CustomTextTheme.fontSize20bold(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => homeController.loadDocuments(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildToolSection(),
              const SizedBox(height: 24),
              Text(
                'Recent Scans',
                style: CustomTextTheme.fontSize20bold(context),
              ),
              const SizedBox(height: 16),
              buildDocListSection(),
              const SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 4,
        onPressed: () async {
          await Navigator.pushNamed(context, CustomCameraScreen.name);
          homeController.loadDocuments();
        },
        icon: const Icon(Icons.document_scanner, color: Colors.white),
        label: const Text(
          'Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildDocListSection() {
    return Obx(() {
      if (homeController.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (homeController.documents.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_open,
                    size: 56,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No documents scanned yet',
                  style: CustomTextTheme.fontSize16(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap the Scan button to capture your first document',
                  textAlign: TextAlign.center,
                  style: CustomTextTheme.fontSize12(context).copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: homeController.documents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doc = homeController.documents[index];
          return buildDocCard(doc);
        },
      );
    });
  }

  Widget buildDocCard(DocumentModel doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.pushNamed(
              context,
              DocDetailVew.name,
              arguments: doc,
            );
            homeController.loadDocuments();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 85,
                    width: 65,
                    color: const Color(0xFFF1F5F9),
                    child: doc.firstPageThumbnail != null &&
                            File(doc.firstPageThumbnail!).existsSync()
                        ? Image.file(
                            File(doc.firstPageThumbnail!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.description,
                            size: 32,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: CustomTextTheme.fontSize16(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.pages_outlined,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${doc.pageCount} ${doc.pageCount == 1 ? "page" : "pages"}',
                            style: CustomTextTheme.fontSize12(context).copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const CircleAvatar(
                            radius: 2,
                            backgroundColor: Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMM yyyy').format(doc.updatedAt),
                            style: CustomTextTheme.fontSize12(context).copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 3-dots Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (action) {
                    if (action == 'rename') {
                      _showRenameDialog(doc);
                    } else if (action == 'share_pdf') {
                      homeController.shareDocument(doc, true);
                    } else if (action == 'share_images') {
                      homeController.shareDocument(doc, false);
                    } else if (action == 'delete') {
                      _showDeleteDialog(doc);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.drive_file_rename_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share_pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Share as PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share_images',
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Share as Images'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(DocumentModel doc) {
    final controller = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter document name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                homeController.renameDocument(doc.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.name}"? All scanned pages in this folder will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              homeController.deleteDocument(doc.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Row buildToolSection() {
    return Row(
      children: [
        buildToolsCard(
          title: 'Import\nImages',
          subtitle: 'from gallery',
          icon: Icons.image,
          color: const Color(0xFF2563EB),
          onTap: () => homeController.importFromGallery(),
        ),
        const SizedBox(width: 16),
        buildToolsCard(
          title: 'Import\nFiles',
          subtitle: 'from storage',
          icon: Icons.folder_open,
          color: const Color(0xFFA06900),
          onTap: () => homeController.importFromGallery(),
        ),
      ],
    );
  }

  Widget buildToolsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: CustomTextTheme.fontSize16(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: CustomTextTheme.fontSize10(context).copyWith(
                  fontFamily: 'Manrope',
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
