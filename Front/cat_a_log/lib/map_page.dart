import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  final double? lat;
  final double? lng;

  // NEW: controls behavior
  final bool showAllPosts;

  const MapPage({
    super.key,
    this.lat,
    this.lng,
    this.showAllPosts = true, // default = navbar mode
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
  }

  // -----------------------------
  // MAP READY
  // -----------------------------
  Future<void> _onMapCreated() async {
    if (_mapReady) return;
    _mapReady = true;

    await _loadMarkers();
    _moveCameraSmart();
  }

  // -----------------------------
  // CAMERA LOGIC
  // -----------------------------
  Future<void> _moveCameraSmart() async {
    try {
      // PRIORITY: post-specific view
      if (!widget.showAllPosts &&
          widget.lat != null &&
          widget.lng != null) {
        final target = LatLng(widget.lat!, widget.lng!);

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 16),
        );
        return;
      }

      // NAVBAR MODE → user location or last known
      Position? last = await Geolocator.getLastKnownPosition();

      if (last != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(last.latitude, last.longitude),
            13,
          ),
        );
      }
    } catch (_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          const LatLng(27.9506, -82.4572),
          12,
        ),
      );
    }
  }

  // -----------------------------
  // MARKERS LOGIC (KEY FIX)
  // -----------------------------
  Future<void> _loadMarkers() async {
    final Set<Marker> markers = {};

    // CASE 1: POST MODE → ONLY ONE PIN
    if (!widget.showAllPosts &&
        widget.lat != null &&
        widget.lng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('single_post'),
          position: LatLng(widget.lat!, widget.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    // CASE 2: NAVBAR MODE → ALL POSTS
    if (widget.showAllPosts) {
      final snapshot =
      await FirebaseFirestore.instance.collection('cat_posts').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final lat = data['lat'];
        final lng = data['lng'];

        if (lat == null || lng == null) continue;

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
          ),
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _markers = markers;
    });
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(27.9506, -82.4572),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _onMapCreated();
            },
            myLocationEnabled: true,
            markers: _markers,
          ),

          // BACK BUTTON
          SafeArea(
            child: Positioned(
              top: 25,
              left: 25,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}