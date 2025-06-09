import 'package:flutter/material.dart';
import 'reader_page.dart';

class UpdatePage extends StatelessWidget{
  const UpdatePage({super.key, required this.mangaUp});
  final List<dynamic> mangaUp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UpdateView(up: [mangaUp],),
    );
  }
}

class UpdateView extends StatefulWidget {
  const UpdateView({super.key, required this.up});

  final List<dynamic> up;

  @override
  State<UpdateView> createState() => UpdateViewState();
}

class UpdateViewState extends State<UpdateView>{
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> mangaList = widget.up[0][0];
    return Scaffold(
      appBar: AppBar(
        title: Text('Updated'),
      ),
      body: ListView.builder(
          itemCount: mangaList.length,
          itemBuilder: (context, index){
            var mangaUpdate = mangaList[index];
            var title = mangaUpdate['title'];
            var libCover = mangaUpdate['coverUrl'];
            var upId = mangaUpdate['id'];
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
                MaterialPageRoute(builder: (context) => ReaderPage(accessToken: accessToken, mangaId: upId),
                )
              );*/
              },
            );
          }
      ),
    );
  }
}