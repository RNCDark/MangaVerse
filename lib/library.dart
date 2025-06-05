import 'package:flutter/material.dart';
import 'dart:convert';
import 'reader_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
      ),
      body: ListView.builder(
        itemCount: widget.lib.length,
          itemBuilder: (context, index){
          var mangaLib = widget.lib[index];
          var libCover = mangaLib['coverUrl'];
          var title = mangaLib['title'];
          var libId = mangaLib['id'];
          return ListTile(
            leading: Image.network(
              '$libCover.512.jpg',
              fit: BoxFit.fill,
            ),
            title: Text(title),
            onTap: () {
              throw UnimplementedError();
              /*Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReaderPage(accessToken: accessToken, mangaId: libId),
                )
              );*/
            },
          );
          }
      ),
    );
  }
}