import 'package:flutter/material.dart';

class HeroImage extends StatelessWidget {
  final String title;
  final String author;
  final String coverUrl;
  final VoidCallback onAddToLibrary;
  final VoidCallback onRead;

  const HeroImage({
    super.key,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.onAddToLibrary,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background cover image
        Container(
          width: double.infinity,
          height: 580,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.5,
              repeat: ImageRepeat.repeat,
              image: NetworkImage(coverUrl),
              fit: BoxFit.fitHeight,
              colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(20),
                BlendMode.darken,
              ),
            ),
          ),
        ),
        // Foreground content
        Container(
          width: double.infinity,
          height: 280,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: Colors.black,
                        letterSpacing: -0.48,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      author,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: onAddToLibrary,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("ADD TO LIBRARY",
                      style: TextStyle(
                        color: Color(0xFF6E44FF),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onRead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E44FF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("READ",
                      style: TextStyle(
                        color: Colors.black /* Void-Black */,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

