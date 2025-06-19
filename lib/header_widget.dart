import 'package:flutter/material.dart';
import 'library.dart';
import 'update_page.dart';
import 'reader_page.dart';
import 'main.dart';

class Header extends StatelessWidget {
  const Header({super.key, this.access});
  final String? access;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1B3A4B), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('MangaVerse',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Inter',
            color: Colors.black,
            ),
          ),
          const SizedBox(width: 50,),
          // Navigation buttons
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _navButton(context, 'Home', MyApp() , selected: true),
                _navButton(context, 'Updates', UpdatePage(access: access == null ? accessToken : '')),
                _navButton(context, 'Library', LibraryPage(mangaLib: readerList)),
                //_navButton(context, 'Popular', ),
                //_navButton(context, 'Community', ),
              ],
            ),
          ),

          // Search box
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: Color(0xFF1B3A4B)),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.search, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Auth buttons
          Row(
            children: [
              _actionButton('Sign in', bgColor: Color(0xFF6E44FF),
                  borderColor: Color(0xFF0B0C2A),
                  textColor: Colors.black),
              const SizedBox(width: 8),
              _actionButton('Sign Up', bgColor: Color(0xFF2C2C2C),
                  borderColor: Color(0xFF1B3A4B),
                  textColor: Color(0xFFFF3CAC)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, String label, Widget page , {bool selected = false}) {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF6E44FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
      child: TextButton(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states){
                if(states.contains(WidgetState.hovered)) {
                  return Colors.grey.withAlpha(40);
                }
                if (states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return Colors.grey.withAlpha(120);
                }
                return null;
              }
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            color: Colors.black,
          )
        )
      ),
    );
  }

  Widget _actionButton(String label,
      {required Color bgColor, required Color borderColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Inter',
          color: textColor,
        ),
      ),
    );
  }
}