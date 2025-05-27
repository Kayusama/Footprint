import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/ProfilePage.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Image.asset(
                    'images/logo/iconOfficial1.png',
                    width: 75,
                    height: 75,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4), // space around the icon
                      decoration: BoxDecoration(
                        color: Colors.white, // background color
                        shape: BoxShape.circle,
                        
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'App Name: Footprint',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Version: 1.1.7',
              style: TextStyle(fontSize: 16),
            ),
            Card(
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            final controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted);

            final loadingNotifier = ValueNotifier<bool>(true);

            controller.setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) {
                  loadingNotifier.value = true;
                },
                onPageFinished: (String url) {
                  loadingNotifier.value = false;
                },
                onHttpError: (HttpResponseError error) {
                  loadingNotifier.value = false;
                },
                onWebResourceError: (WebResourceError error) {
                  loadingNotifier.value = false;
                },
              ),
            );

            controller.loadRequest(
              Uri.parse('https://www.termsfeed.com/live/05ed6286-5473-4867-b08a-b36d2b16d578'),
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              content: SizedBox(
                height: 400,
                width: 300,
                child: Stack(
                  children: [
                    WebViewWidget(controller: controller),
                    ValueListenableBuilder<bool>(
                      valueListenable: loadingNotifier,
                      builder: (context, loading, child) {
                        if (loading) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
      child: const Text(
        'Terms and Conditions',
        style: TextStyle(
          fontSize: 16,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),
            const SizedBox(height: 20),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'The Footprint document tracking system is utilized at Palawan State University – Taytay Campus to efficiently track documents sent or received. It assigns carriers and recipients, recording unique identifications and essential information. The system also provides automatic notifications, prevents unauthorized access, and ensures document security. Its comprehensive audit trail logging helps in accountability and post-event analysis.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Developers:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<HolderTracker?>(
            future: getTrackerUsingKey("os9YSuxVtDNTYieFJIBE"),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text("Loading...", style: TextStyle(color: Colors.white)),
                );
              }

              if (!userSnapshot.hasData) {
                return const ListTile(
                  title: Text("Error loading user", style: TextStyle(color: Colors.white)),
                );
              }

              final tracker = userSnapshot.data!;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: (tracker.profilePicture.isNotEmpty)
                          ? MemoryImage(base64Decode(tracker.profilePicture))
                          : null,
                      child: (tracker.profilePicture.isEmpty)
                          ? Text(
                              tracker.fullName[0],
                              style: TextStyle(
                                color: mainOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                  title: Text(tracker.fullName, style: TextStyle(color: mainOrange)),
                  subtitle: Text("Developer", style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(user: tracker),
                          ),
                        );
                  },
                ),
              );
            },
          ),
          FutureBuilder<HolderTracker?>(
            future: getTrackerUsingKey("EisA91WLTqvKOTL4lskr"),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text("Loading...", style: TextStyle(color: Colors.white)),
                );
              }

              if (!userSnapshot.hasData) {
                return const ListTile(
                  title: Text("Error loading user", style: TextStyle(color: Colors.white)),
                );
              }

              final tracker = userSnapshot.data!;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: (tracker.profilePicture.isNotEmpty)
                          ? MemoryImage(base64Decode(tracker.profilePicture))
                          : null,
                      child: (tracker.profilePicture.isEmpty)
                          ? Text(
                              tracker.fullName[0],
                              style: TextStyle(
                                color: mainOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                  title: Text(tracker.fullName, style: TextStyle(color: mainOrange)),
                  subtitle: Text("Designer", style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(user: tracker),
                          ),
                        );
                  },
                ),
              );
            },
          ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
