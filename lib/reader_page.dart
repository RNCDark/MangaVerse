import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'header_widget.dart';
import 'heroimage_widget.dart';

var readerList = [];
List<dynamic> bookmarked = [];
List<String> pageUrls = [];

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
  bool useMock = false;
  bool isLoading = true;
  List<dynamic> chapters = [];
  List<dynamic> mangaData = [];
  List<String> pageUrls = [];

  @override
  void initState() {
    super.initState();
    if(useMock){
      setState(() {
        mangaData = [
          {
            'id' : 'mock-id',
            'attributes' : {
              'title': 'Mock Manga',
              'updated' : '30 sec',
              'altTitle': 'ja',
              'description': 'Mock description',
              'content': 'Mock rating - Safe',
              'tags': 'Action, Adventure',
            },
            'relationships': {
              'coverUrl' : 'https//via.placeholder.com/150',
              'artist': 'Mock artist',
              'author': 'Mock author',

            }
          }
        ];
      });
      isLoading = false;
    } else {
      fetchChapters();
    }
    //fetchPages('');
  }

  Future<void> fetchChapters() async{
    const int limit = 100; //default limit
    int offset = 0; //skips n of chapters
    bool more = true;
    String uLang = "en";
    List<dynamic> allChapters = [];

    var url2 = Uri.parse('https://api.mangadex.org/manga/${widget.mangaId}?includes[]=cover_art&includes[]=author&includes[]=artist');
    var accessToken = widget.accessToken;

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
        var attributes = manga['attributes'];
        var relationships = manga['relationships'] ?? [];
        var des = attributes['description']?['en'];
        var altTitle = attributes['altTitles'];
        var year = attributes['year'];
        var stat = attributes['status'];
        var content = attributes['contentRating'];
        var tags = attributes['tags'];
        List tagNames = [];
        for(var tag in tags){ //tags is a list not a map
          var name = tag['attributes']?['name']?['en'];
          if(name != null){
            tagNames.add(name);
          }
        }
        var artist = relationships.firstWhere(
              (rel) => rel['type'] == 'artist',
          orElse: () => null,
        );
        var author = relationships.firstWhere(
              (rel) => rel['type'] == 'author',
          orElse: () => null,
        );
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
            'altTitles': altTitle,
            'description': des,
            'author': author['attributes']?['name'],
            'artist': artist['attributes']?['name'],
            'tags': tagNames,
            'year': year,
            'status':stat,
            'rating':content,
            'coverUrl': coverUrl,
            'id' : manga['id'],
          }
        ];
      });
      isLoading = false;
    }

    while(more) {
      var url = Uri.parse('https://api.mangadex.org/manga/${widget
          .mangaId}/feed?limit=$limit&offset=$offset&order[chapter]=desc');

      var response = await http.get(url, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200) {
        print('Chapter fetch Success!');
        var data = jsonDecode(response.body);
        var total = data['total'];
        //print(data);
          var chapFeed = data['data'].map((feed) {
            var title = feed['attributes']['title'] ?? 'No Title';
            var chp = feed['attributes']['chapter'];
            var lang = feed['attributes']['translatedLanguage'];
            var external = feed['attributes']['externalUrl'];
            var chpId = feed['id'];
            return {
              'attributes': {
                'title': title,
                'chapter': chp,
                'lang': lang,
                'externalUrl': external,
              },
              'chapterId': chpId,
            };
          }).toList();
          allChapters.addAll(chapFeed);
          offset += limit;
          more = allChapters.length < total;

      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to load chapters: ${response.statusCode}');
        break;
      }
    }
    allChapters.sort((a, b) {
      double chpA = double.tryParse(a['attributes']['chapter'] ?? '0') ??
          0;
      double chpB = double.tryParse(b['attributes']['chapter'] ?? '0') ??
          0;
      //return chpA.compareTo(chpB); //ascending order
      return chpB.compareTo(chpA); //descending order
    });

    setState(() {
      chapters = allChapters;
      isLoading = false;
    });
  }

  Future<List<String>> fetchPages(String chapterId) async{
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
        body: isLoading
          ? Center(child: CircularProgressIndicator()
        )
          : SingleChildScrollView(
          child: Column(
            children: <Widget> [
                Header(access: widget.accessToken,),
                HeroImage(title: mangaData[0]['title'],
                    author: mangaData[0]['author'],
                    coverUrl: mangaData[0]['coverUrl'],
                    onAddToLibrary: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Library')),
                      );
                      readerList.add(reader(mangaData[0]));
                    },
                  onRead: () async{
                    if (chapters.isEmpty) return;

                    final firstChapter = chapters.firstWhere(
                          (ch) {
                        final chapterNum = ch['attributes']?['chapter']?.toString();
                        return chapterNum != null && chapterNum == ('1');
                      },
                      orElse: () => chapters.last,
                    );
                    final firstChapterId = firstChapter['chapterId'] ?? firstChapter['id'];
                    final pageUrls = await fetchPages(firstChapterId);

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: NestedScrollView(
                            headerSliverBuilder: (context, _) => [
                              SliverAppBar(title: Text('Chp. ${firstChapter['attributes']['chapter']}')),
                            ],
                            floatHeaderSlivers: true,
                            body: ListView.builder(
                              itemCount: pageUrls.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Image.network(
                                  pageUrls[index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Text('❌ Failed to load image'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Column (
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                                child: Text(mangaData[0]['description'] ?? 'No description',
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 5,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontFamily: 'Noto Sans',
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: (){

                              },
                              child: Text(mangaData[0]['rating'])),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: mangaData[0]['tags'].map<Widget>((tag) {
                              return TextButton(
                                onPressed: () {

                                },
                                child: Text(tag),
                              );
                            }).toList(),
                          )//placement
                        ],
                      ),
                      const SizedBox(height: 15,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Publication:',
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontFamily: 'Noto Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 10,),
                          Text('${mangaData[0]['year']}, ${mangaData[0]['status']}',
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontFamily: 'Noto Sans',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: 30,),
                Text('Chapters',
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
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                var chapter = chapters[index];
                var attributes = chapter['attributes'] ?? {};
                var chpId = chapter['chapterId'] ?? chapter['id'];
                var chp = attributes['chapter'];
                var lang = attributes['lang'];
                var ext = attributes['externalUrl'];
                var chapterTitle = attributes['title'] ?? 'No Title';
                return ListTile(
                  subtitle: Text(lang),
                  title: Text('Chapter.$chp $chapterTitle'),
                  onTap: () async{
                    if(ext != null) {
                      final Uri external = Uri.parse(ext);
                      if (await canLaunchUrl(external)) {
                        await launchUrl(external);
                      } else {
                        SnackBar(content: Text('❌ Could not launch $ext'));
                      }
                    }
                    final pageU = await fetchPages(chpId);
                    if(!context.mounted)return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChpPages(
                          chapterIndex: index,
                          chapters: chapters,
                          accessToken: widget.accessToken,
                          pages: pageU,
                        ),
                      ),
                    );// Navigate to chapter details or display chapter content
                  },
                );
              },
            ),
          ]
        )
      )
    );
  }
}

class ChpPages extends StatelessWidget {
  final int chapterIndex;
  final List chapters;
  final String? accessToken;
  final List pages;

  const ChpPages({
    super.key,
    required this.chapterIndex,
    required this.chapters,
    this.accessToken,
    required this.pages,
  });

  Future<List<String>> fetchPages(String chapterId) async{
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
    final currentChapter = chapters[chapterIndex];
    final chp = currentChapter['attributes']['chapter'];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            title: Text('Chp. $chp'),
            floating: true,
            snap: true,
          ),
        ],
        floatHeaderSlivers: true,
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Image.network(
                      pages[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Text('❌ Failed to load image'),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (chapterIndex > 0)
                  TextButton(
                    onPressed: () async {
                      final next = chapters[chapterIndex + 1];
                      final nextId = next['chapterId'] ?? next['id'];
                      final nextPages = await fetchPages(nextId);
                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChpPages(
                            chapterIndex: chapterIndex - 1,
                            chapters: chapters,
                            accessToken: accessToken,
                            pages: nextPages,
                          ),
                        ),
                      );
                    },
                    child: const Text('← Next Chapter'),
                  ),
                if (chapterIndex < chapters.length - 1)
                  TextButton(
                    onPressed: () async {
                      final prev = chapters[chapterIndex - 1];
                      final prevId = prev['chapterId'] ?? prev['id'];
                      final prevPages = await fetchPages(prevId);
                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChpPages(
                            chapterIndex: chapterIndex + 1,
                            chapters: chapters,
                            accessToken: accessToken,
                            pages: prevPages,
                          ),
                        ),
                      );
                    },
                    child: const Text('Previous Chapter →'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
