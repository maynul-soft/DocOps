import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class EditDocView extends StatefulWidget {
  const EditDocView({super.key});

  static const name = 'EditDocView';

  @override
  State<EditDocView> createState() => _EditDocViewState();
}

class _EditDocViewState extends State<EditDocView> {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = ColorScheme.of(context);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: buildAppSection(colorScheme),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 20),
              height: size.height - 250,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.withAlpha(50)),
            ),
            Gap.height(10),
            Expanded(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: .spaceAround,
                      children: [
                        buildCustomButton(
                          icon: Icons.crop,
                          onTap: () {},
                          title: 'crop',
                        ),
                        buildCustomButton(
                          icon: Icons.edit,
                          onTap: () {},
                          title: 'draw',
                        ),
                        buildCustomButton(
                          icon: Icons.auto_fix_high_outlined,
                          onTap: () {},
                          title: 'erase',
                        ),
                        buildCustomButton(
                          icon: Icons.rotate_left,
                          onTap: () {},
                          title: 'rotate',
                        ),
                        buildCustomButton(
                          icon: Icons.settings_backup_restore_sharp,
                          onTap: () {},
                          title: 'retake',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector buildCustomButton({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    Color? color,
  }) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, color: color ?? Colors.white),
        Text(
          title,
          style: CustomTextTheme.fontSize9(context)
              .copyWith(fontWeight: FontWeight.bold)
              .copyWith(color: color ?? Colors.white),
        ),
      ],
    ),
  );

  AppBar buildAppSection(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.black,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Transform.flip(
              flipX: true,
              child: Icon(Icons.shortcut, color: Colors.white),
            ),
          ),
          Gap.width(16),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.shortcut, color: Colors.white),
          ),
          Spacer(),
          Text(
            'Edit Scan',
            style: CustomTextTheme.fontSize18bold(
              context,
            ).copyWith(color: Colors.white),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.close, color: Colors.white),
          ),
          Gap.width(16),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.done, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
