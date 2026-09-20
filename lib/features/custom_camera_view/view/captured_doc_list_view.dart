import 'dart:io';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/core/services/document_storage/document_storage_service.dart';
import 'package:doc_scanner/features/home/controller/home_controller.dart';
import 'package:intl/intl.dart';

class CapturedDocListView extends StatefulWidget {
  const CapturedDocListView({super.key});

  static const name = 'doc_list_view';

  @override
  State<CapturedDocListView> createState() => _CapturedDocListViewState();
}

class _CapturedDocListViewState extends State<CapturedDocListView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CustomCameraController>();
    controller.isCameraScreenOn = false;
    _pageController = PageController(
      initialPage: controller.capturedImages.isNotEmpty
          ? controller.capturedImages.length - 1
          : 0,
      viewportFraction: 0.85,
    );
    controller.currentCapturedPage = controller.capturedImages.isNotEmpty
        ? controller.capturedImages.length - 1
        : 0;
  }

  @override
  void dispose() {
    if (Get.isRegistered<CustomCameraController>()) {
      Get.find<CustomCameraController>().isCameraScreenOn = true;
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onTapSaveDocument(CustomCameraController controller) {
    if (controller.capturedImages.isEmpty) {
      Get.snackbar('Error', 'No pages captured');
      return;
    }

    final now = DateTime.now();
    final defaultTitle = 'Scan ${DateFormat('dd MMM yyyy, h:mm a').format(now)}';
    final nameController = TextEditingController(text: defaultTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a title for your document:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final doc = await DocumentStorageService.createDocument(
                name: nameController.text.trim().isEmpty
                    ? defaultTitle
                    : nameController.text.trim(),
                tempImagePaths: controller.capturedImages,
              );

              // Refresh home controller if active
              if (Get.isRegistered<HomeController>()) {
                Get.find<HomeController>().loadDocuments();
              }

              controller.capturedImages.clear();

              // Close preview and camera, open detail view
              Get.until((route) => route.isFirst);
              Get.toNamed(DocDetailVew.name, arguments: doc);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Review Scans',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          GetBuilder<CustomCameraController>(
            builder: (controller) => TextButton.icon(
              onPressed: () => _onTapSaveDocument(controller),
              icon: const Icon(Icons.check_circle, color: Color(0xFF60A5FA), size: 20),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: GetBuilder<CustomCameraController>(
          builder: (controller) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (controller.currentCapturedPage < controller.capturedImages.length)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_left_sharp, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.currentCapturedPage + 1} / ${controller.capturedImages.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_right_sharp, color: Colors.white70),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int pageNumber) {
                      controller.updatePageNumber(pageNumber);
                    },
                    itemCount: controller.capturedImages.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      return index < controller.capturedImages.length
                          ? Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: controller.currentCapturedPage == index ? 10 : 30,
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Get.to(
                                            () => EditDocView(
                                              imagePath: controller.capturedImages[index],
                                            ),
                                          );
                                          setState(() {});
                                        },
                                        child: Image.file(
                                          File(controller.capturedImages[index]),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Delete button
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => controller.deleteAPage(index, context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(alpha: 0.6),
                                        ),
                                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                  // Tap to edit hint
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit, size: 14, color: Colors.white70),
                                            SizedBox(width: 6),
                                            Text(
                                              'Tap to Edit & Crop',
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : buildAddNewPageSection(context, controller, index);
                    },
                  ),
                ),
                // Bottom Save Action Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Add Page'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _onTapSaveDocument(controller),
                          icon: const Icon(Icons.done_all),
                          label: const Text('Done & Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildAddNewPageSection(BuildContext context, controller, index) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: const Color(0xFF2563EB).withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Color(0xFF60A5FA), size: 50),
            SizedBox(height: 12),
            Text(
              'Add More Pages',
              style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
