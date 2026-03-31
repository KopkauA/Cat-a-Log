import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as loc;      // For getting GPS coordinates
import 'package:geocoding/geocoding.dart';    // For converting coordinates to address
import 'colors.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  double? _lat;
  double? _lng;
  String? _city;
  String? _state;
  XFile? _image;
  Uint8List? _webImage;

  final picker = ImagePicker();

  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedColor;
  String? _selectedFurLength;

  final List<String> colors = ['Black','White','Orange','Gray','Calico','Tabby','Tortoiseshell','Other'];
  final List<String> furLengths = ['Short', 'Medium', 'Long', 'Hairless'];
  final List<String> healthStatus = ['Healthy', 'Minor Injury', 'Major Injury'];
  bool _isUploading = false;

  // --- LOCATION ---
  loc.Location location = loc.Location();
  String? _address; // translated address

  // ---------------- IMAGE PICKER ----------------
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      if (kIsWeb) _webImage = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() => _image = pickedFile);
    }
  }

  void showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
  // ---------------- LOCATION FETCH -------------------

  Future<void> getCurrentAddress() async {


    if (kIsWeb) {
    _address = "Web location not available";
    return;
    }

    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return;
      }

      final locData = await location.getLocation();
      _lat = locData.latitude;
      _lng = locData.longitude;

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _lat!,
          _lng!);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        _city = place.locality; // city
        _state = place.administrativeArea; // state
      }
    } catch (e) {
      _address = "Unknown";
    }
  }


  // ---------------- UPLOAD ----------------
  Future<void> upload() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_selectedColor == null || _selectedFurLength == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select color and fur length')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (mounted) setState(() => _isUploading = true);

    // --- GET LOCATION BEFORE UPLOAD ---
    await getCurrentAddress();

    String? downloadUrl;
    String username = 'username';

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        username = data['username'] ?? 'Anonymous';
      }

      final fileName = 'cat_posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        contentDisposition: 'inline',
      );

      if (kIsWeb && _webImage != null) {
        uploadTask = ref.putData(_webImage!, metadata);
      } else {
        uploadTask = ref.putFile(File(_image!.path), metadata);
      }

      final snapshot = await uploadTask;
      downloadUrl = await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('cat_posts').add({
        'image_url': downloadUrl,
        'caption': _captionController.text,
        'description': _descriptionController.text,
        'color': _selectedColor,
        'fur_length': _selectedFurLength,
        'timestamp': FieldValue.serverTimestamp(),
        'username': username,
        'userId': currentUser.uid,

        'latitude': _lat,
        'longitude': _lng,
        'city': _city,
        'state': _state,

        'location': _address ?? "Unknown", // <--- LOCATION SAVED HERE
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload successful!')));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save post: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offwhite,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Center(
                      child: Text(
                        "Create Post",
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: "ZTNature",
                        fontWeight: FontWeight.w500,
                        color: shad,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 260, 24, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: _captionController,
                            style: const TextStyle(color: shad),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.edit, color: grayblue),
                              labelText: "Caption",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: shad),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.description, color: grayblue),
                              labelText: "Description",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedColor,
                            style: const TextStyle(color: shad),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.color_lens, color: grayblue),
                              labelText: 'Color',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                            items: colors
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedColor = val),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFurLength,
                            style: const TextStyle(color: grayblue),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.straighten, color: grayblue),
                              labelText: 'Fur Length',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                            items: furLengths
                                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedFurLength = val),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isUploading ? null : upload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: grayblue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Post", style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: showImageSourceOptions,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _image != null
                                ? kIsWeb
                                    ? Image.memory(
                                        _webImage!,
                                        height: 220,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_image!.path),
                                        height: 220,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                : Container(
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add_a_photo,
                                          size: 60, color: grayblue),
                                    ),
                                  ),
                          ),
                          if (_image != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _image = null;
                                  _webImage = null;
                                }),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: offwhite,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close,
                                      color: gray, size: 20),
                                ),
                              ),
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
      ),
    );
  }
}
