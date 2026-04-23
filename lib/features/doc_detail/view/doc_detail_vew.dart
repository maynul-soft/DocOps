import 'package:doc_scanner/core/export_path/export_path.dart';

class DocDetailVew extends StatefulWidget {
  const DocDetailVew({super.key});

  static const name = 'Doc detail view';

  @override
  State<DocDetailVew> createState() => _DocDetailVewState();
}

class _DocDetailVewState extends State<DocDetailVew> {
  final TextEditingController _nameController = TextEditingController();

  // @override
  // void initState() {
  //   super.initState();
  //
  // }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List tempItemList = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarSection(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: tempItemList.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            childAspectRatio: 0.60,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (BuildContext context, int index) {
            return index < tempItemList.length
                ? buildDocImageCard(index)
                : buildAddNewPageCard();
          },
        ),
      ),
    );
  }

  Widget buildDocImageCard(int index) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, EditDocView.name);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: .circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 10,
                child: Text('${index + 1}', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddNewPageCard() {
    return GestureDetector(
      onTap: () {
        debugPrint('add new');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: .circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.camera_outlined,
                  size: 80,
                  color: ColorScheme.of(context).primary,
                ),
              ),
              Gap.height(10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: .circular(10),
                  color: Colors.grey.shade100,
                ),
                padding: EdgeInsets.all(10),
                child: Text(
                  'Add New',
                  style: CustomTextTheme.fontSize20bold(
                    context,
                  ).copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBarSection(BuildContext context) {
    return AppBar(
      title: Text(
        'Q3 Tax Report 2025',
        style: CustomTextTheme.fontSize20bold(context),
      ),
      actions: [
        IconButton(
          onPressed: () {
            editDocNameWidget();
          },
          icon: Icon(Icons.drive_file_rename_outline),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(onPressed: () {}, icon: Icon(Icons.share)),
        ),
      ],
    );
  }

  Future<dynamic> editDocNameWidget() {
    _nameController.text = 'Q3 Tax Report 2025';
    return showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: .min,
            children: [
              Gap.height(20),
              TextFormField(
                controller: _nameController,
                style: CustomTextTheme.fontSize20bold(context),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ColorScheme.of(context).primary,
                    ),
                  ),
                ),
              ),
              Gap.height(20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.withAlpha(10),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        'Cancel',
                        style: CustomTextTheme.fontSize20bold(context),
                      ),
                    ),
                  ),
                  Gap.width(15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        //TODO: Implement the rename
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorScheme.of(context).primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Ok',
                        style: CustomTextTheme.fontSize20bold(
                          context,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Gap.height(20),
            ],
          ),
        );
      },
    );
  }
}
