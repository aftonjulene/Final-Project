import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

class PhotoJournalScreen extends StatefulWidget {
  const PhotoJournalScreen({super.key});

  @override
  State<PhotoJournalScreen> createState() => _PhotoJournalScreenState();
}

class _PhotoJournalScreenState extends State<PhotoJournalScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _photosStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _photosStream = FirebaseFirestore.instance
          .collection('photo_journal')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .snapshots();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add photos.')),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upload to Firebase Storage
      final String fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('photo_journal')
          .child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        // For web, read bytes and upload
        final Uint8List imageBytes = await image.readAsBytes();
        uploadTask = storageRef.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile, use file path
        File imageFile = File(image.path);
        uploadTask = storageRef.putFile(imageFile);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('photo_journal').add({
        'userId': user.uid,
        'imageUrl': downloadUrl,
        'date': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: ${e.toString()}')),
      );
    }
  }

  Future<void> _deletePhoto(String docId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Photo'),
          content: const Text('Are you sure you want to delete this photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('photo_journal')
          .doc(docId)
          .delete();

      // Delete from Storage
      try {
        final Reference storageRef = FirebaseStorage.instance.refFromURL(
          imageUrl,
        );
        await storageRef.delete();
      } catch (_) {
        
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting photo: ${e.toString()}')),
      );
    }
  }

  void _showAddPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!kIsWeb) // Camera only works on mobile, not web
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ListTile(
                  leading: Icon(kIsWeb ? Icons.folder : Icons.photo_library),
                  title: Text(
                    kIsWeb ? 'Choose from Files' : 'Choose from Gallery',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Photo Journal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Please log in to view your photo journal.'),
        ),
      );
    }

    if (_photosStream == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Photo Journal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Photo Journal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _photosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final photos = snapshot.data?.docs ?? [];

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photos yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first photo',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final doc = photos[index];
                final data = doc.data();
                final imageUrl = data['imageUrl'] as String?;
                final date = data['date'] as Timestamp?;

                return _buildPhotoCard(
                  context,
                  imageUrl,
                  date?.toDate(),
                  doc.id,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPhotoOptions(context);
        },
        backgroundColor: const Color(0xFF1a1d2e),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    String? imageUrl,
    DateTime? date,
    String docId,
  ) {
    return _PhotoCard(
      imageUrl: imageUrl,
      date: date,
      docId: docId,
      onDelete: _deletePhoto,
    );
  }
}

class _PhotoCard extends StatefulWidget {
  final String? imageUrl;
  final DateTime? date;
  final String docId;
  final Future<void> Function(String docId, String imageUrl) onDelete;

  const _PhotoCard({
    required this.imageUrl,
    required this.date,
    required this.docId,
    required this.onDelete,
  });

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  bool _isBlurred = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (widget.imageUrl != null) {
          widget.onDelete(widget.docId, widget.imageUrl!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: widget.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _isBlurred ? 8.0 : 0.0,
                        sigmaY: _isBlurred ? 8.0 : 0.0,
                      ),
                      child: Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    ),
                    if (widget.date != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${widget.date!.month}/${widget.date!.day}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _isBlurred ? Icons.blur_off : Icons.blur_on,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _isBlurred = !_isBlurred;
                              });
                            },
                          ),
                          IconButton(
                            padding: const EdgeInsets.only(left: 4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            onPressed: () {
                              if (widget.imageUrl != null) {
                                widget.onDelete(widget.docId, widget.imageUrl!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  'Image',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ),
      ),
    );
  }
}

//photo journal
