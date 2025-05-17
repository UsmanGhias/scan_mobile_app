import 'dart:io';
import 'package:app/widgets/snackbar.dart';
import 'package:flutter/material.dart';

Future<File?> pickImage(BuildContext context) async {
  File? image;
  try {
    //final ImageSource? source = ImageSource.camera;

    // if (source != null) {
    //   final pickedImage = await ImagePicker().pickImage(source: source);
    //   image = pickedImage != null ? File(pickedImage.path) : null;
    // }
  } catch (e) {
    showSnackbar(context: context, content: e.toString());
  }
  return image;
}
