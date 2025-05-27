import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/database_helper.dart';

class ImageGalleryPage extends StatefulWidget {
  final DocumentRecord record;

  const ImageGalleryPage({Key? key, required this.record}) : super(key: key);

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.record.imageRefs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: widget.record.imageRefs.length,
                      onPageChanged: (index) {
                        // Handle page change if needed
                      },
                      itemBuilder: (context, index) {
                        return FutureBuilder<String?>(
                          future: getImage(widget.record.imageRefs[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasData && snapshot.data != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(snapshot.data!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            } else {
                              return const Center(child: Text('Image not available'));
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Swipe to view images', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ] else ...[
              const Center(child: Text('No images to display')),
            ]
          ],
        ),
      ),
    );
  }
}
