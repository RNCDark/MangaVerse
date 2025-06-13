import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reader_page.dart';

List<dynamic> updates = [];

class UpdatePage extends StatelessWidget{
  const UpdatePage({super.key, required this.access});
  final String access;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UpdateView(access: access,),
    );
  }
}

class UpdateView extends StatefulWidget {
  const UpdateView({super.key, required this.access});

  final String access;

  @override
  State<UpdateView> createState() => UpdateViewState();
}

class UpdateViewState extends State<UpdateView>{
  bool isLoading = true;

  @override
  void initState(){
    super.initState();
    fetchUpdates();
  }

  Future<void> fetchUpdates()async {
    setState(() {
      isLoading = true;
    });

    var updateResponse = await http.get(
      Uri.parse('https://api.mangadex.org/manga?limit=30&offset=0&includes[]=cover_art'),
      headers: {
        'Authorization': 'Bearer $widget.access',
      },
    );

    if(updateResponse.statusCode == 200){
      print('Manga fetch Success!');
      var data = jsonDecode(updateResponse.body); //decoding manga data
      setState(() {
        updates = data['data'].map((manga){ //storing the manga data
          // Extracting the title and cover image URL
          var title = manga['attributes']?['title']?['en'] ?? 'No Title';
          var updated = manga['attributes']?['updatedAt'] ?? [];
          var relationships = manga['relationships'] ?? [];
          var coverArt = relationships.firstWhere(
                (rel) => rel['type'] == 'cover_art',
            orElse: () => null,
          );
          String coverUrl = 'twitter-cover.jpg';
          if(coverArt != null && coverArt['id'] != null){
            var fileName = coverArt['attributes']['fileName'];

            coverUrl = 'https://uploads.mangadex.org/covers/${manga['id']}/$fileName';
          }
          return {
            'title': title,
            'updated': updated,
            'status': manga['attributes']?['status'] ?? [],
            'coverUrl': coverUrl,
            'id' : manga['id'],
          };
        }).toList();
        isLoading = false; //stop loading spinner
      });
    } else {
      setState(() {
        isLoading = false; //stop loading spinner
      });
      print('Manga fetch failed : ${updateResponse.statusCode}');
      return; //stops on failure
    }

  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Updated'),
      ),
      body: ListView.builder(
          itemCount: updates.length,
          itemBuilder: (context, index){
            var mangaUpdate = updates[index];
            var title = mangaUpdate['title'];
            var updated = mangaUpdate['updated'];
            var stats = mangaUpdate['status'];
            var libCover = mangaUpdate['coverUrl'];
            var upId = mangaUpdate['id'];
            return ListTile(
              leading: Image.network(
                '$libCover.512.jpg',
                fit: BoxFit.fill,
              ),
              title: Text(title),
              subtitle: Text('$stats - $updated'),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReaderPage(mangaId: upId),
                )
              );
              },
            );
          }
      ),
    );
  }
}