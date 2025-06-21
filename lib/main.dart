import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reader_page.dart';
import 'header_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

String accessToken = ''; //early declaration for usage later

String timeFormat(String time){
  DateTime parsed = DateTime.parse(time);
  return timeago.format(parsed);
}

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

  bool useMock = false; //front end dev
  List<dynamic> mangaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if(useMock){
      setState(() {
        mangaList = [
          {
            'id' : 'mock-id',
            'attributes' : {
              'title': 'Mock Manga',
              'updated' : '30 sec',
            },
            'relationships': {
              'coverUrl' : 'https//via.placeholder.com/150',

            }
          }
        ];
      });
      isLoading = false;
    } else {
      fetchAuth();
      fetchManga();
    }
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
      Uri.parse('https://api.mangadex.org/manga?includes[]=cover_art&order[latestUploadedChapter]=desc'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    //check for manga response
    if(mangaResponse.statusCode == 200){
      print('Manga fetch Success!');
      var data = jsonDecode(mangaResponse.body); //decoding manga data
      //print(data);
      setState(() {
        mangaList = data['data'].map((manga) { //storing the manga data
          // Extracting the title and cover image URL
          var title = manga['attributes']?['title']?['en'] ?? 'No Title';
          var updated = manga['attributes']?['updatedAt'] ?? [];
          //var latestChpId = manga['attributes']['latestUploadedChapter'] ?? 'Unknown';
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
          String recentChp = '';
          /*if(latestChpId != null){
            final chapterUrl = Uri.parse('https://api.mangadex.org/chapter/$latestChpId');
            final chapterResponse = await http.get(chapterUrl);
            if (chapterResponse.statusCode == 200) {
              final chapterData = jsonDecode(chapterResponse.body)['data'];
              recentChp = chapterData['attributes']['chapter'] ?? 'Unknown';
            }
          }*/
          return {
            'title': title,
            'updated': timeFormat(updated),
            //'recentChp' : recentChp,
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
      body: isLoading
      ? Center(
        child: CircularProgressIndicator(),
      )
      : SingleChildScrollView(
      child: Column(
        children: <Widget>[
            Header(access: accessToken,),
            SizedBox(height: 24,),
            Text('Recently Updated',
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3,
                ),
                itemCount: mangaList.length,
                itemBuilder: (context, index){
                  var manga = mangaList[index];
                  var mangaId = manga['id'];
                  var title = manga['title'];
                  var updated = manga['updated'];
                  //var recent = manga['recentChp'];
                  var stats = manga['status'];
                  var coverUrl = manga['coverUrl'];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReaderPage(accessToken: accessToken, mangaId: mangaId),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      child: Padding(
                          padding: EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                            aspectRatio: 0.75,
                            child: Image.network(
                                '$coverUrl.512.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 40,),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(title,
                                  maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4,),
                                  Text('$stats - $updated',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ),
          ],
        ),
      ),
    );
  }
}