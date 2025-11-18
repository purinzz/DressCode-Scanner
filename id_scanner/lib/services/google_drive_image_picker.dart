import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:typed_data';

class GoogleDriveImagePicker extends StatefulWidget {
  final Function(GoogleDriveFile?) onImageSelected;

  const GoogleDriveImagePicker({
    super.key,
    required this.onImageSelected,
  });

  @override
  State<GoogleDriveImagePicker> createState() => _GoogleDriveImagePickerState();
}

class _GoogleDriveImagePickerState extends State<GoogleDriveImagePicker> {
  bool _isLoading = false;
  List<GoogleDriveFile> _images = [];
  GoogleDriveFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    // ✅ Automatically load images when dialog opens
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final images = await GoogleDriveService.getImageFiles();
      setState(() {
        _images = images;
        _isLoading = false;
      });

      if (images.isEmpty) {
        if (mounted) {
          print('⚠️ No images found - showing error message to user');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No PNG/JPG/WebP images found in the folder. Check your Google Drive folder has images and you signed in with the correct account.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e')),
        );
      }
    }
  }

  void _selectImage(GoogleDriveFile image) {
    setState(() => _selectedImage = image);
    widget.onImageSelected(image);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Select Image from Google Drive'),
            backgroundColor: const Color.fromRGBO(26, 24, 81, 1),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Debug Drive',
                icon: const Icon(Icons.bug_report),
                onPressed: () async {
                  // Run debug helper and show results
                  final results = await GoogleDriveService.debugListFiles();
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Drive debug'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, i) => Text(results[i]),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (_images.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No images found in the folder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure images are in the correct Google Drive folder and you\'re signed in with the right account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadImages,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(26, 24, 81, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        GoogleDriveService.openDriveFolderInBrowser();
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in Google Drive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading images from Google Drive...'),
                ],
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final image = _images[index];
                  return GestureDetector(
                    onTap: () => _selectImage(image),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              child: FutureBuilder<Uint8List?>(
                                future: GoogleDriveService.downloadFileBytes(image.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    );
                                  }
                                  // Fallback to public URL (may fail if file isn't shared)
                                  return ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    child: Image.network(
                                      image.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              image.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
