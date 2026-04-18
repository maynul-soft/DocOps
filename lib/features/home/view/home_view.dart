import 'dart:ffi';

import 'package:doc_scanner/core/export_path/export_path.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  static const name = 'Home view';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'My Documents',
          style: CustomTextTheme.fontSize20bold(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildToolSection(),
              const SizedBox(height: 20),
              Text(
                'Recent Scans',
                style: CustomTextTheme.fontSize20bold(context),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return buildDocCard(
                    title: 'Q3 Tax Report 2023',
                    page: 3,
                    date: DateTime.now(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDocCard({
    required String title,
    required int page,
    required DateTime date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: .circular(10),
                color: Colors.grey.withAlpha(100),
              ),
              height: 100,
              width: 80,
              child: Icon(Icons.image),
            ),
            Gap.width(10),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: CustomTextTheme.fontSize18bold(context),
                  ),
                  Gap.height(8),
                  Row(
                    mainAxisAlignment: .start,
                    children: [
                      Icon(Icons.contact_page_outlined, size: 12),
                      Text(' $page pages'),
                      Gap.width(10),
                      CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                      Gap.width(10),
                      Text(DateFormat('dd MMM yyyy').format(date)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert_outlined, size: 30),
          ],
        ),
      ),
    );
  }

  Row buildToolSection() {
    return Row(
      mainAxisAlignment: .spaceAround,
      children: [
        buildToolsCard(
          title: 'Import\nImages',
          subtitle: 'from gallery',
          icon: Icons.image,
          color: ColorScheme.of(context).primary,
        ),
        Gap.width(30),
        buildToolsCard(
          title: 'Import PDF\nFiles',
          subtitle: 'from storage',
          icon: Icons.picture_as_pdf,
          color: Color(0xffA06900),
        ),
      ],
    );
  }

  Widget buildToolsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        // margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: .circular(20),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                borderRadius: .circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            Gap.height(10),
            Text(title, style: CustomTextTheme.fontSize18bold(context)),
            Text(
              subtitle,
              style: CustomTextTheme.fontSize10(
                context,
              ).copyWith(fontFamily: 'Manrope'),
            ),
          ],
        ),
      ),
    );
  }
}
