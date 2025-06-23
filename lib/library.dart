import 'package:flutter/material.dart';
import 'reader_page.dart';
import 'header_widget.dart';

class LibraryPage extends StatelessWidget{
  const LibraryPage({super.key, required this.mangaLib});
  final List<dynamic> mangaLib;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LibraryView(lib: [mangaLib],),
    );
  }
}

class LibraryView extends StatefulWidget {
  const LibraryView({super.key, required this.lib});

  final List<dynamic> lib;

  @override
  State<LibraryView> createState() => LibraryViewState();
}

class LibraryViewState extends State<LibraryView>{
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> mangaList =
    widget.lib.isNotEmpty && widget.lib[0].isNotEmpty
        ? widget.lib[0][0]
        : [];
    return Scaffold(
      body: mangaList.isEmpty
        ? SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Header(),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3, // gives Center space to work with
        ),
              Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded,
            size: 64,
            color: Colors.deepPurpleAccent,),
            const SizedBox(height: 16,), //spacing
            Text('Looks like your Universe is empty',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18,),
            Text('Lets add some manga to it',
            textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter'
              ),
            ),
          ],
        ),
      ),
      ],
    ),
      )
        : SingleChildScrollView(
    child: Column (
    children: <Widget> [
            Header(),
            Text('Library',
              textAlign: TextAlign.left,
              style : TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.20,
                letterSpacing: -0.48,
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              itemCount: mangaList.length,
                itemBuilder: (context, index){
                var mangaLib = mangaList[index];
                var title = mangaLib['title'];
                var libCover = mangaLib['coverUrl'];
                var libId = mangaLib['id'];
                return ListTile(
                  leading: Image.network(
                    '$libCover.512.jpg',
                    fit: BoxFit.fill,
                  ),
                  title: Text(title),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReaderPage( mangaId: libId),
                      )
                    );
                  },
                );
                }
            ),
          ]
        )
      )
    );
  }
}