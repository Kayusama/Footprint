import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footprint3/Feedback_page.dart';
import 'package:footprint3/Holdings_page.dart';
import 'package:footprint3/ProfilePage.dart';
import 'package:footprint3/RegisterDocument_page.dart';
import 'package:footprint3/ScanDocument_page.dart';
import 'package:footprint3/TrackDocumentPage.dart';
import 'package:footprint3/about_page.dart';
import 'package:footprint3/chatlist_page.dart';
import 'package:footprint3/login_page.dart';
import 'package:footprint3/utils.dart';
class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: mainOrange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: (curTracker.profilePicture.isNotEmpty)
                        ? MemoryImage(base64Decode(curTracker.profilePicture))
                        : null,
                    child: (curTracker.profilePicture.isEmpty)
                        ? Text(
                            curTracker.fullName[0],
                            style: TextStyle(
                              color: mainOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage(user: curTracker)),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  curTracker.fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.article, "Home", () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(Icons.qr_code_scanner, "Register Document", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterdocumentPage()),
            );
          }),
          _buildDrawerItem(Icons.chat, "Chat", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatList()),
            );
          }),
          _buildDrawerItem(Icons.notifications, "Holdings", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HoldingsPage()),
            );
          }),
          _buildDrawerItem(Icons.person_2, "Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage(user: curTracker)),
            );
          }),
          _buildDrawerItem(Icons.star, "Feedbacks", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FeedbackPage()),
            );
          }),
          _buildDrawerItem(Icons.info, "About us", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutPage()),
            );
          }),

          // Spacer to push logout to the bottom
          Spacer(),

          // Logout Button at the bottom
          _buildDrawerItem(Icons.logout, "Logout", () {
            _logout(context); // Call your logout method here
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: mainOrange),
      title: Text(title, style: TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }

 void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Logout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error logging out. Please try again."),
      ));
    }
  }
}