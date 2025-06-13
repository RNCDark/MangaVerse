import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reader_page.dart';
import 'library.dart';
import 'update_page.dart';

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
      debugShowCheckedModeBanner: false, //gets rid of debug sash
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
      print(data);
      setState(() {
        mangaList = data['data'].map((manga){ //storing the manga data
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
      print('Manga fetch failed : ${mangaResponse.statusCode}');
      return; //stops on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
          child: Text(widget.title),),
        actions: <Widget> [
          TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => LibraryPage(mangaLib: [readerList],)),
              );
            },
            child: Text('Library'),
          ),
          TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => UpdatePage(access: accessToken,)),
              );
            },
            child: Text('Updates'),
          ),
        ]
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
              var updated = manga['updated'];
              var stats = manga['status'];
              var coverUrl = manga['coverUrl'];
              return ListTile(
                leading: Image.network(
                  '$coverUrl.512.jpg',
                  fit: BoxFit.fill,
                ),
                title: Text(title),
                subtitle: Text('$stats - $updated'),
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