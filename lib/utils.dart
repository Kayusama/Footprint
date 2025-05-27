import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

HolderTracker curTracker = HolderTracker.empty();
TrackableDocument curDocument = TrackableDocument.empty();

Color mainOrange = const Color.fromARGB(255, 247, 91, 34);
Color backgroundColor= const Color.fromARGB(255, 249, 229, 222);

String generateUnique6DigitCode() {
  final random = Random();
  return List.generate(6, (_) => random.nextInt(6)).join();
}

void loseFocus() {
  FocusManager.instance.primaryFocus?.unfocus();
}

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool password;
  final String? errorText;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.password = false,
    this.errorText,
    this.keyboardType,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 40,
      margin: const EdgeInsets.all(15),
      child: TextFormField(
        style: TextStyle(color: mainOrange),
        controller: widget.controller,
        obscureText: widget.password && _obscureText,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          label: Text(
            widget.labelText,
            style: TextStyle(color: mainOrange),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: mainOrange),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: mainOrange,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          errorText: widget.errorText,
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: mainOrange,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null, // No icon for non-password fields
        ),
      ),
    );
  }
}

class CheckboxRow extends StatefulWidget {
  final String labelText;
  final Function onCheckboxChanged;

  const CheckboxRow({
    super.key,
    required this.labelText, required this.onCheckboxChanged,
  });
  @override
  _CheckboxRowState createState() => _CheckboxRowState();
}

class _CheckboxRowState extends State<CheckboxRow> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Checkbox(
            fillColor: WidgetStateProperty.all(mainOrange),
            value: isChecked,
            onChanged: (bool? value) {
              setState(() {
                isChecked = value ?? false;
                widget.onCheckboxChanged(value ?? false);
              });
            },
          ),
          Text(
            widget.labelText,
            style: TextStyle(fontSize: 20, color: mainOrange),
          ),
        ],
      ),
    );
  }
}


class AlertDialogHelper {
  /// Displays an alert dialog with the given message.
  static void showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Alert'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

String formatTimeDifference(DateTime timestamp) {
  Duration difference = DateTime.now().difference(timestamp);

  if (difference.inSeconds < 60) {
    return "${difference.inSeconds}s ago";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes}m ago";
  } else if (difference.inHours < 24) {
    return "${difference.inHours}h ago";
  } else if (difference.inDays < 7) {
    return "${difference.inDays}d ago";
  } else {
    return "${timestamp.month}/${timestamp.day}/${timestamp.year}";
  }
}


Uint8List? compressAndResizeImage(Uint8List bytes) {
  if (bytes.isNotEmpty) {
      try {
        img.Image image = img.decodeImage(bytes)!;
        // Resize the image to have the longer side be 800 pixels
        int width;
        int height;

        if (image.width > image.height) {
          width = 800;
          height = (image.height / image.width * 800).round();
        } else {
          height = 800;
          width = (image.width / image.height * 800).round();
        }

        img.Image resizedImage = img.copyResize(image, width: width, height: height);

        // Compress the image with JPEG format
        List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 85);  // Adjust quality as needed
        Uint8List uint8List = Uint8List.fromList(compressedBytes);

        return uint8List;
      } catch (e) {
        print("Error compressing and resizing image: $e");
        return null; // Handle error
      }
    }
    else {
      print("No image data provided.");
      return null; // Handle error
    }
  }