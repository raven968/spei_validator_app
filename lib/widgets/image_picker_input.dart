import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerInput extends StatelessWidget {
  final File? selectedImage;
  final ValueChanged<File?> onImageChanged;

  const ImagePickerInput({
    super.key,
    required this.selectedImage,
    required this.onImageChanged,
  });

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      onImageChanged(File(pickedFile.path));
    }
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2838),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF00E676)),
                ),
                title: const Text('Cámara',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Tomar una foto nueva',
                    style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF448AFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF448AFF)),
                ),
                title: const Text('Galería',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Elegir de tus fotos',
                    style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Captura de transferencia',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSourceSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedImage != null
                    ? const Color(0xFF00E676).withValues(alpha: 0.4)
                    : const Color(0xFF2A3F55),
                width: selectedImage != null ? 1.5 : 1,
              ),
            ),
            child: selectedImage != null
                ? _ImagePreview(
                    image: selectedImage!,
                    onClear: () => onImageChanged(null),
                  )
                : const _ImagePlaceholder(),
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File image;
  final VoidCallback onClear;

  const _ImagePreview({required this.image, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        children: [
          Image.file(image, width: double.infinity, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_a_photo_rounded,
              color: Color(0xFF00E676), size: 32),
        ),
        const SizedBox(height: 14),
        const Text('Toca para seleccionar imagen',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('Cámara o Galería',
            style: TextStyle(color: Colors.white30, fontSize: 12)),
        const SizedBox(height: 30),
      ],
    );
  }
}
