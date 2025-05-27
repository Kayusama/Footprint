import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/homepage.dart';
import 'package:footprint3/login_page.dart';
import 'package:footprint3/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:footprint3/editProfile.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final HolderTracker user;

  const ProfilePage({super.key, required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _campusController;
  late TextEditingController _positionController;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _imageBase64 = widget.user.profilePicture;

    print("Image Base64: ${_imageBase64?.length ?? 0} bytes");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Profile",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight * 0.2,
                      color: const Color.fromARGB(255, 204, 120, 71),
                      child: ClipRect(
                        child: Image.asset(
                          'images/psu.jfif',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight * 0.8,
                      color: const Color.fromARGB(255, 243, 240, 238),
                    ),
                  ],
                ),
                
                Positioned(
                  top: constraints.maxHeight * 0.10,
                  left: constraints.maxWidth * 0.01,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundImage: _imageBase64 != null
                                  ? MemoryImage(base64Decode(_imageBase64!))
                                  : null,
                              child: _imageBase64 == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    )
                                  : null,
                              backgroundColor:
                                  const Color.fromARGB(255, 231, 228, 228),
                            ),
                          ),
                          curTracker.key == widget.user.key ? Positioned(
                            bottom: 0, // Position at the bottom of the avatar
                            right: 0, // Position at the right of the avatar
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 243, 126, 72),
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                // Background color for the icon
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(
                                  4), // Padding around the icon
                              child: const Icon(
                                Icons.edit, // Edit icon
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ) : const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.fullName,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 17, 17, 17),
                                ),
                              ),
                              const SizedBox(height: 0.5),
                              Text(
                                widget.user.email,
                                style: const TextStyle(
                                  fontSize: 24 / 1.618,
                                  fontWeight: FontWeight.w400,
                                  color: Color.fromARGB(255, 17, 17, 17),
                                ),
                              ),
                              SizedBox(height: 20,),
                              Column(
                                children: [
                                  curTracker.key == widget.user.key ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfile(user: widget.user),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: constraints.maxWidth * 0.9,
                                      height: 25,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 247, 91, 63),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(255, 243, 243, 243),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ) : const SizedBox.shrink(),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: constraints.maxWidth * 0.9,
                                    height: 35,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 16.0),
                                          child: Text(
                                          'Birthday( ${DateFormat('MMMM d, y').format(widget.user.birthday)})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: constraints.maxWidth * 0.9,
                                    height: 180,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Contact Information',
                                          style: TextStyle(
                                            fontSize: 24 / 1.618,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0),
                                          child: Text(
                                            widget.user.email,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0),
                                          child: Text(
                                            widget.user.number,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('Address',
                                            style: TextStyle(
                                              fontSize: 24 / 1.618,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            )),
                                        Padding(
                                          padding: EdgeInsets.only(left: 16.0),
                                          child: Text(
                                            widget.user.address,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    child: Container(
                                      width: constraints.maxWidth * 0.9,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () => _logout(context),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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