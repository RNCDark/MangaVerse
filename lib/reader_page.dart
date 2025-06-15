import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var readerList = [];
List<dynamic> bookmarked = [];

class ReaderPage extends StatelessWidget{
  const ReaderPage({super.key, this.accessToken, required this.mangaId});
  final String? accessToken;
  final String mangaId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChapterList(accessToken: accessToken, mangaId: mangaId),
    );
  }
}

void listReader(List<dynamic> red){
  reader(red[0]);
}

List<dynamic> reader(Map<String, dynamic> data){
  bookmarked.add(data);
  return bookmarked;
}

class ChapterList extends StatefulWidget {
  final String ? accessToken;
  final String mangaId;

  const ChapterList({super.key, this.accessToken, required this.mangaId});

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList>{
  bool isLoading = true;
  List<dynamic> chapters = [];
  List<dynamic> mangaData = [];
  List<String> pageUrls = [];

  @override
  void initState() {
    super.initState();
    fetchChapters();
    //fetchPages('');
  }

  Future<void> fetchChapters() async{
    var url = Uri.parse('https://api.mangadex.org/manga/${widget.mangaId}/feed');
    var url2 = Uri.parse('https://api.mangadex.org/manga/${widget.mangaId}?includes[]=cover_art');
    var accessToken = widget.accessToken;
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    var mangaResponse = await http.get(url2, headers: {
    'Authorization': 'Bearer $accessToken',
    });

    if(mangaResponse.statusCode == 200){
      print('Retrieved Manga data!');
      var data = jsonDecode(mangaResponse.body);
      setState(() {
        var manga = data['data']; //storing the manga data
        // Extracting the title and cover image URL
        var title = manga['attributes']?['title']?['en'] ?? 'No Title';
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
        mangaData = [
          {
            'title': title,
            'coverUrl': coverUrl,
            'id' : manga['id'],
          }
        ];
      });
      isLoading = false;
    }

    if (response.statusCode == 200) {
      print('Chapter fetch Success!');
      var data = jsonDecode(response.body);
      //print(data);
      setState(() {
        chapters = data['data'].map((feed){
          var title = feed['attributes']['title'] ?? 'No Title';
          var chp = feed['attributes']['chapter'];
          var chpId = feed['id'];
          var lang = feed['attributes']['translatedLanguage'];
          //print(feed['attributes']);
          return {
            'attributes':{
              'title': title,
              'chapter': chp,
              'lang' : lang,
            },
            'chapterId' : chpId,
          };
        }).toList();
        chapters.sort((a, b){
          double chpA = double.tryParse(a['attributes']['chapter'] ?? '0') ?? 0;
          double chpB = double.tryParse(b['attributes']['chapter'] ?? '0') ?? 0;
          //return chpA.compareTo(chpB); //ascending order
          return chpB.compareTo(chpA); //descending order
        });
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to load chapters: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchPages(String chapterId) async{
    //var accessToken = widget.accessToken;
    var url = Uri.parse('https://api.mangadex.org/at-home/server/$chapterId');
    var response = await http.get(url);

    if(response.statusCode == 200){
      print('Page fetch Success');
      var data = jsonDecode(response.body);
      //print(data);
      String baseUrl = data['baseUrl'];
      String hash = data['chapter']['hash'];
      //print(baseUrl);
      List<dynamic> pages = data['chapter']['data']; //png
      pageUrls = pages.map<String>((file){
        return '$baseUrl/data/$hash/$file';
      }).toList();
    }else{
      print('Page fetch failed : ${response.statusCode}');
      return []; //stops on failure
    }
    return pageUrls;
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
            readerList.add(reader(mangaData[0]));
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
          var chpId = chapter['chapterId'] ?? chapter['id'];
          var chp = attributes['chapter'];
          var lang = attributes['lang'];
          var chapterTitle = attributes['title'] ?? 'No Title';
          //print('Chapter.$chp : $chapterTitle');
          return ListTile(
            subtitle: Text(lang),
            title: Text('Chapter.$chp $chapterTitle'),
            onTap: () async{
              final pageU = await fetchPages(chpId);
              if(!context.mounted)return;
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Chapter $chp'),),
                    body: ListView.builder(
                      itemCount: pageU.length,
                      itemBuilder: (context, index){
                        var pages = pageU[index];
                        return Padding(padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    pages,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text('❌ Failed to load image');
                                    },
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