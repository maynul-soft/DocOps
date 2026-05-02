import 'package:doc_scanner/core/export_path/export_path.dart';
import 'dart:io';

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
    Get.find<CustomCameraController>().isCameraScreenOn = false;
    _pageController = PageController(
      initialPage: Get.find<CustomCameraController>().capturedImages.length - 1,
      viewportFraction: 0.85,
    );
    Get.find<CustomCameraController>().currentCapturedPage =
        Get.find<CustomCameraController>().capturedImages.length - 1;
  }

  @override
  void dispose() {
    Get.find<CustomCameraController>().isCameraScreenOn = true;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Icon(Icons.arrow_back_ios, color: Colors.blue),
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: GetBuilder<CustomCameraController>(
          builder: (controller) {
            return Column(
              mainAxisAlignment: .start,
              children: [
                Gap.height(MediaQuery.of(context).size.height * .07),
                controller.currentCapturedPage <
                        controller.capturedImages.length
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white.withAlpha(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_left_sharp),
                              Gap.width(4),

                              Text(
                                '${controller.currentCapturedPage + 1}/${controller.capturedImages.length}',
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(Icons.arrow_right_sharp),
                            ],
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
                Gap.height(10),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .550,
                  width: MediaQuery.of(context).size.width * 0.8,
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
                                vertical:
                                    controller.currentCapturedPage == index
                                    ? 30
                                    : 0,
                              ),
                              decoration: BoxDecoration(),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => EditDocView(
                                            imagePath: controller
                                                .capturedImages[index],
                                          ),
                                        );
                                      },
                                      child: Image.file(
                                        fit: BoxFit.fill,
                                        File(controller.capturedImages[index]),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.deleteAPage(index, context);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.withAlpha(50),
                                        ),
                                        child: Icon(Icons.delete),
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildAddNewPageSection(BuildContext context, controller, index) {
    return GestureDetector(
      onTap: () {
        Get.back();
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: controller.currentCapturedPage == index ? 30 : 0,
        ),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue.withAlpha(30),
        ),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.blue, size: 50),
            Gap.height(10),
            Text(
              'Add Photo',
              style: CustomTextTheme.fontSize14(
                context,
              ).copyWith(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
