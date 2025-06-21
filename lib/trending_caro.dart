import 'dart:convert';
import 'reader_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Trending extends StatelessWidget{
  const Trending({super.key, required this.accessToken});
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TrendingList(accessToken: accessToken),
    );
  }
}

class TrendingList extends StatefulWidget {
  final String accessToken;

  const TrendingList({super.key, required this.accessToken});

  @override
  State<TrendingList> createState() => _TrendingListState();
}

class _TrendingListState extends State<TrendingList> {
  bool isLoading = true;
  List <dynamic> trendList = [];

  @override
  void initState() {
    super.initState();
    trendingFeed();
  }

  Future<void> trendingFeed() async {
    var accessToken = widget.accessToken;
    var url = Uri.parse('https://api.mangadex.org/manga?includes[]=cover_art&order[updatedAt]=desc&limit=5');
    var trendResponse = await http.get(url, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if(trendResponse.statusCode == 200){
      var data = jsonDecode(trendResponse.body);
      setState(() {
        trendList = data['data'].map((manga){
          var title = manga['attributes']?['title']?['en'] ?? 'No Title';
          var dis = manga['attributes']?['description']?['en'];
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
            'desc': dis,
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
          items: trendList.map((manga){
            return Builder(
                builder: (context){
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReaderPage(
                            accessToken: widget.accessToken,
                            mangaId: manga['mangaId'],
                          ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.network(
                          '${manga['coverArt']}.512.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          manga['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(manga['desc'].toString(),
                        style: TextStyle(fontSize: 14),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
          options: CarouselOptions(
            height: 300,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.6,
          )
      ),
    );
  }
}