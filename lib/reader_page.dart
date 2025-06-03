import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReaderPage extends StatelessWidget{
  const ReaderPage({super.key, required this.accessToken, required this.mangaId});
  final String accessToken;
  final String mangaId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChapterList(accessToken: accessToken, mangaId: mangaId),
    );
  }
}

class ChapterList extends StatefulWidget {
  final String accessToken;
  final String mangaId;

  const ChapterList({super.key, required this.accessToken, required this.mangaId});

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList>{
  bool isLoading = true;
  List<dynamic> chapters = [];
  List<String> pageUrls = [];

  @override
  void initState() {
    super.initState();
    fetchChapters();
    fetchPages();
  }

  Future<List<String>> fetchChapters() async{
    var url = Uri.parse('https://api.mangadex.org/manga/${widget.mangaId}/feed');
    var accessToken = widget.accessToken;
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $accessToken',
    });
    if (response.statusCode == 200) {
      print('Chapter fetch Success!');
      var data = jsonDecode(response.body);
      setState(() {
        chapters = data['data'].map((feed){
          var title = feed['attributes']['title'] ?? 'No Title';
          var chp = feed['attributes']['chapter'];
          var chpId = feed['id'];
          var description = feed['attributes']['description'];
          //print(feed['attributes']);
          return {
            'attributes':{
              'title': title,
              'chapter': chp,
              'description' : description,
            },
            'chapterId' : chpId,
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to load chapters: ${response.statusCode}');
    }
    List<String> chapterIds = chapters.map<String>((chapter){
      return chapter['chapterId'];
    }).toList();
    return chapterIds;
  }

  Future<void> fetchPages() async{
    //var accessToken = widget.accessToken;
    var chapterIds = await fetchChapters();

    if (chapterIds.isEmpty) {
      print('No chapters found.');
      return;
    }

    String chapterId = chapterIds[0];

    var url = Uri.parse('https://api.mangadex.org/at-home/server/$chapterId');
    var response = await http.get(url);

    if(response.statusCode == 200){
      print('Page fetch Success');
      var data = jsonDecode(response.body);
      String baseUrl = data['baseUrl'];
      String hash = data['chapter']['hash'];
      //print(baseUrl);
      List<dynamic> pages = data['chapter']['data']; //png
      pageUrls = pages.map<String>((file){
        return '$baseUrl/data/$hash/$file';
      }).toList();
    }else{
      print('Page fetch failed : ${response.statusCode}');
      return; //stops on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chapters'),
      ),
        floatingActionButton: TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states){
                  if(states.contains(WidgetState.hovered)) {
                    return Colors.blue.withAlpha(40);
                  }
                  if (states.contains(WidgetState.focused) ||
                      states.contains(WidgetState.pressed)) {
                    return Colors.blue.withAlpha(120);
                  }
                  return null;
                }
            ),
          ),
            onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added to Library')),
            );
            },
            child: Text('Bookmark')
        ),
        body: isLoading
          ? Center(child: CircularProgressIndicator()
        )
          : ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          var chapter = chapters[index];
          var attributes = chapter['attributes'] ?? {};
          var chp = attributes['chapter'];
          var chapterTitle = attributes['title'] ?? 'No Title';
          //print('Chapter.$chp : $chapterTitle');
          return ListTile(
            //subtitle: Text(chp),
            title: Text('Chapter.$chp $chapterTitle'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Chapter $chp'),),
                    body: ListView.builder(
                      itemCount: pageUrls.length,
                      itemBuilder: (context, index){
                        var pages = pageUrls[index];
                        return Padding(padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    pages,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ],
                            )
                        );
                      },
                    ),
                  ))
              );// Navigate to chapter details or display chapter content
            },
          );
        },
      ),
    );
  }
}