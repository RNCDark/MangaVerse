import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangaVerse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'MangaVerse'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<dynamic> mangaList = [];
  bool isLoading = true;
  String accessToken = ''; //early declaration for usage later

  @override
  void initState() {
    super.initState();
    fetchAuth();
    fetchManga();
  }

  Future<void> fetchAuth() async {
    setState((){
      isLoading = true; //show loading spinner
    });
    var url = Uri.parse('https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/token');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body : {
        'grant_type': 'password',
        'username': 'RNCDark',
        'password': 'Mr@wesome24',
        'client_id': 'personal-client-ca4655e8-ad84-4134-8072-7cd65095c6a7-34050cb7',
        'client_secret': 'Uf9SQxhlenpoRSeUNnw7Cuumf410B3Jz',
      },
    );
    if (response.statusCode == 200) {
      print('Login success!');
      //print(response.body);  // Contains access_token and refresh_token
      var data = jsonDecode(response.body); //decodes the body
      accessToken = data['access_token']; // stores the access token
    } else {
      print('Login failed: ${response.statusCode}');
      //print(response.body);
      return; //stops on failure
    }
  }

  Future<void> fetchManga() async {
    setState((){
      isLoading = true; //show loading spinner
    });
    var mangaResponse = await http.get(
      Uri.parse('https://api.mangadex.org/manga?includes[]=cover_art'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    //check for manga response
    if(mangaResponse.statusCode == 200){
      print('Manga fetch Success!');
      var data = jsonDecode(mangaResponse.body); //decoding manga data
      setState(() {
        mangaList = data['data'].map((manga){ //storing the manga data
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
          //print(manga['id']); // Debugging print statements
          //print(coverArt['attributes']['fileName']);
          //print(manga);
          return {
            'title': title,
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
      print('Manga fetch failed : ${mangaResponse.statusCode}');
      return; //stops on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: isLoading
      ? Center(
        child: CircularProgressIndicator(),
      )
      : ListView(
        children: [
          Text('Recently Updated',
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
              var manga = mangaList[index];
              var mangaId = manga['id'];
              var title = manga['title'];
              var coverUrl = manga['coverUrl'];
              return ListTile(
                leading: Image.network(
                  '$coverUrl.512.jpg',
                  fit: BoxFit.fill,
                ),
                title: Text(title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReaderPage(accessToken: accessToken, mangaId: mangaId),
                    ),
                  );
                },
              );
            },
          )
        ],
      )
    );
  }
}

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
    var accessToken = widget.accessToken;
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