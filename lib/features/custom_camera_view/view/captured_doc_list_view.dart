import 'dart:io';
import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:doc_scanner/core/services/document_storage/document_storage_service.dart';
import 'package:doc_scanner/features/home/controller/home_controller.dart';
import 'package:doc_scanner/features/custom_camera_view/utils/id_card_stitcher.dart';
import 'package:intl/intl.dart';

class CapturedDocListView extends StatefulWidget {
  final String? targetDocId;

  const CapturedDocListView({super.key, this.targetDocId});

  static const name = 'doc_list_view';

  @override
  State<CapturedDocListView> createState() => _CapturedDocListViewState();
}

class _CapturedDocListViewState extends State<CapturedDocListView> {
  late PageController _pageController;
  List<String>? _uncombinedImages;

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

  Future<void> _openEditPage(int index) async {
    final controller = Get.find<CustomCameraController>();
    if (index < 0 || index >= controller.capturedImages.length) return;

    final path = controller.capturedImages[index];
    await Navigator.pushNamed(
      context,
      EditDocView.name,
      arguments: path,
    );
    if (mounted) {
      PaintingBinding.instance.imageCache.evict(FileImage(File(path)));
      setState(() {});
    }
  }

  Future<void> _onTapCombineIdCard(CustomCameraController controller) async {
    if (controller.capturedImages.length != 2) return;

    _uncombinedImages = List<String>.from(controller.capturedImages);

    final stitchedPath = await IdCardStitcher.stitchIdCard(
      frontPath: controller.capturedImages[0],
      backPath: controller.capturedImages[1],
    );

    if (stitchedPath != null) {
      controller.capturedImages.clear();
      controller.capturedImages.add(stitchedPath);
      controller.updatePageNumber(0);
      _pageController.jumpToPage(0);
      controller.update();
      if (mounted) {
        PaintingBinding.instance.imageCache.evict(FileImage(File(stitchedPath)));
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Card stitched into 1 page! Tap "Separate" to edit sides individually.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onTapSeparateIdCard(CustomCameraController controller) {
    if (_uncombinedImages == null || _uncombinedImages!.length != 2) return;

    controller.capturedImages.clear();
    controller.capturedImages.addAll(_uncombinedImages!);
    _uncombinedImages = null;
    controller.updatePageNumber(0);
    _pageController.jumpToPage(0);
    controller.update();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Front and Back separated! You can now edit and rotate each side.'),
          backgroundColor: Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onTapSaveDocument(CustomCameraController controller) async {
    if (controller.capturedImages.isEmpty) {
      Get.snackbar('Error', 'No pages captured');
      return;
    }

    if (widget.targetDocId != null) {
      // User is adding pages to an existing document
      for (final imagePath in controller.capturedImages) {
        await DocumentStorageService.addPageToDocument(widget.targetDocId!, imagePath);
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadDocuments();
      }

      controller.capturedImages.clear();

      if (mounted) {
        Navigator.popUntil(context, (route) => route.settings.name == DocDetailVew.name);
      }
      return;
    }

    final now = DateTime.now();
    final defaultTitle = 'Scan ${DateFormat('dd MMM yyyy, h:mm a').format(now)}';
    final nameController = TextEditingController(text: defaultTitle);
    bool combineIdCard = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              if (controller.capturedImages.length == 2) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                  ),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    value: combineIdCard,
                    onChanged: (val) {
                      setDialogState(() {
                        combineIdCard = val ?? true;
                      });
                    },
                    title: const Text(
                      'Combine onto 1 Page (A4)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Stitches Front and Back onto a clean sheet',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ),
              ],
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
                final nav = Navigator.of(context);

                List<String> pathsToSave = List.from(controller.capturedImages);
                if (controller.capturedImages.length == 2 && combineIdCard) {
                  final stitched = await IdCardStitcher.stitchIdCard(
                    frontPath: controller.capturedImages[0],
                    backPath: controller.capturedImages[1],
                  );
                  if (stitched != null) {
                    pathsToSave = [stitched];
                  }
                }
                final doc = await DocumentStorageService.createDocument(
                  name: nameController.text.trim().isEmpty
                      ? defaultTitle
                      : nameController.text.trim(),
                  tempImagePaths: pathsToSave,
                );

                // Refresh home controller if active
                if (Get.isRegistered<HomeController>()) {
                  Get.find<HomeController>().loadDocuments();
                }

                controller.capturedImages.clear();

                // Close preview and camera, reset backstack to Home and push detail view
                if (!mounted) return;
                nav.pushNamedAndRemoveUntil(HomeView.name, (route) => false);
                nav.pushNamed(DocDetailVew.name, arguments: doc);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
            builder: (controller) => Row(
              children: [
                if (controller.capturedImages.length == 2)
                  TextButton.icon(
                    onPressed: () => _onTapCombineIdCard(controller),
                    icon: const Icon(Icons.auto_awesome_mosaic_outlined, color: Colors.white, size: 18),
                    label: const Text(
                      'Combine',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (_uncombinedImages != null && controller.capturedImages.length == 1)
                  TextButton.icon(
                    onPressed: () => _onTapSeparateIdCard(controller),
                    icon: const Icon(Icons.splitscreen_outlined, color: Colors.white70, size: 18),
                    label: const Text(
                      'Separate',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (controller.capturedImages.isNotEmpty &&
                    controller.currentCapturedPage < controller.capturedImages.length)
                  IconButton(
                    tooltip: 'Edit Current Page',
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _openEditPage(controller.currentCapturedPage),
                  ),
                TextButton.icon(
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
              ],
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
                const SizedBox(height: 12),
                if (controller.currentCapturedPage < controller.capturedImages.length)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.capturedImages.length > 1)
                          const Icon(Icons.arrow_left_sharp, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          controller.capturedImages.length == 2
                              ? (controller.currentCapturedPage == 0
                                  ? 'Page 1 of 2 (Front Side)'
                                  : 'Page 2 of 2 (Back Side)')
                              : '${controller.currentCapturedPage + 1} / ${controller.capturedImages.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        if (controller.capturedImages.length > 1)
                          const Icon(Icons.arrow_right_sharp, color: Colors.white70),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
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
                                vertical: controller.currentCapturedPage == index ? 8 : 26,
                              ),
                              child: Stack(
                                children: [
                                  // Whole Card is fully clickable to Edit
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _openEditPage(index),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          File(controller.capturedImages[index]),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Delete button (top right)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => controller.deleteAPage(index, context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(alpha: 0.65),
                                        ),
                                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                  // Prominent, explicitly clickable Edit Badge (bottom center)
                                  Positioned(
                                    bottom: 14,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _openEditPage(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB),
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit, size: 16, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text(
                                                'Tap to Edit & Crop',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
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
                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // Add Page Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: const Text('Add Page'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Edit Page Button
                      if (controller.capturedImages.isNotEmpty &&
                          controller.currentCapturedPage < controller.capturedImages.length)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF60A5FA),
                              side: const BorderSide(color: Color(0xFF60A5FA)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _openEditPage(controller.currentCapturedPage),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Page'),
                          ),
                        ),
                      if (controller.capturedImages.isNotEmpty &&
                          controller.currentCapturedPage < controller.capturedImages.length)
                        const SizedBox(width: 10),
                      // Save Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _onTapSaveDocument(controller),
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Save Doc'),
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
