import 'dart:convert';
import 'reader_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Popular extends StatelessWidget{
  const Popular({super.key, required this.accessToken});
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopularList(accessToken: accessToken),
    );
  }
}

class PopularList extends StatefulWidget {
  final String accessToken;

  const PopularList({super.key, required this.accessToken});

  @override
  State<PopularList> createState() => _PopularListState();
}

class _PopularListState extends State<PopularList> {
  bool useMock = true; //front end dev
  bool isLoading = true;
  List <dynamic> popList = [];

  @override
  void initState() {
    super.initState();
    if(useMock){
      setState(() {
        popList = [
          {
            'id' : 'mock-id',
            'title': 'Mock Manga',
            'attributes' : {
              'updated' : '30 sec',
            },
            'coverUrl' : 'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
          }
        ];
      });
      isLoading = false;
    } else {
      popularFeed();
    }
  }

  Future<void> popularFeed() async {
    var accessToken = widget.accessToken;
    var url = Uri.parse('https://api.mangadex.org/manga?includes[]=cover_art&order[followedCount]=desc&limit=10');
    var popResponse = await http.get(url, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if(popResponse.statusCode == 200){
      var data = jsonDecode(popResponse.body);
      setState(() {
        popList = data['data'].map((manga){
          var title = manga['attributes']?['title']?['en'] ?? 'No Title';
          var mangaId = manga['id'];
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
            'coverArt': coverUrl,
            'mangaId' : mangaId,
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CarouselSlider(
        items: popList.map((manga) {
          return Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderPage(
                        accessToken: widget.accessToken,
                        mangaId: manga['mangaId'],
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Remove Expanded and use fixed height
                      SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            '${manga['coverArt']}',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          manga['title'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
        options: CarouselOptions(
          height: 300, // Make sure this fits the content
          autoPlay: false,
          enlargeCenterPage: false,
          viewportFraction: 0.55,
          aspectRatio: 2.0,
        ),
      ),
    );
  }
}