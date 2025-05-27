import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  final HolderTracker user;
  
  const EditProfile({super.key, required this.user});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _campusController;
  late TextEditingController _positionController;
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _addressController;
  late TextEditingController _numberController;
  late TextEditingController _birthdayController;
  DateTime? _selectedBirthday;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _campusController = TextEditingController(text: widget.user.campus);
    _positionController = TextEditingController(text: widget.user.position);
    _firstnameController = TextEditingController(text: widget.user.firstname ?? '');
    _lastnameController = TextEditingController(text: widget.user.lastname ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _numberController = TextEditingController(text: widget.user.number ?? '');
    _selectedBirthday = widget.user.birthday;
    _birthdayController = TextEditingController(
      text: _selectedBirthday != null ? _selectedBirthday!.toIso8601String().split("T").first : '',
    );
    _imageBase64 = widget.user.profilePicture;

    print("Image Base64: ${_imageBase64?.length ?? 0} bytes");
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
        print("Image Base64: ${_imageBase64!.length} bytes");
      });
    }
  }

  Future<void> _pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = picked.toIso8601String().split("T").first;
      });
    }
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        widget.user.setUsername = _usernameController.text;
        widget.user.setEmail = _emailController.text;
        widget.user.setCampus = _campusController.text;
        widget.user.setPosition = _positionController.text;
        widget.user.firstname = _firstnameController.text;
        widget.user.lastname = _lastnameController.text;
        widget.user.address = _addressController.text;
        widget.user.number = _numberController.text;
        widget.user.birthday = _selectedBirthday!;
        if (_imageBase64 != null) {
          widget.user.profilePicture = _imageBase64!;
        }
        updateTracker(widget.user);
        curTracker = widget.user;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageBase64 != null
                      ? MemoryImage(base64Decode(_imageBase64!))
                      : null,
                  child: _imageBase64 == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstnameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter first name' : null,
              ),
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter last name' : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Enter username' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value!.isEmpty || !value.contains('@') ? 'Enter valid email' : null,
              ),
              TextFormField(
                controller: _campusController,
                decoration: const InputDecoration(labelText: 'Campus'),
              ),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Birthday',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickBirthday,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
