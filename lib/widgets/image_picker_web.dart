import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

class WebImagePicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final Function(Uint8List) onImageSelected;

  const WebImagePicker({
    super.key,
    required this.imageBytes,
    required this.onImageSelected,
  });

  Future<void> _selectImage(BuildContext context) async {
    final selected = await ImagePickerWeb.getImageAsBytes();
    if (selected != null) {
      onImageSelected(selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        imageBytes != null
            ? Image.memory(imageBytes!, height: 120)
            : const Text('No image selected'),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _selectImage(context),
          icon: const Icon(Icons.photo_library),
          label: const Text('Pick Image'),
        ),
      ],
    );
  }
}
