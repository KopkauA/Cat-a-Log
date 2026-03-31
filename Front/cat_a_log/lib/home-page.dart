import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'paw_dropdown.dart';
import 'colors.dart';
import 'map_page.dart';
import 'comments.dart';
import 'bookmarks_page.dart';
import 'filter.dart';
import 'post_options.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:intl/intl.dart';

class CatFeedPage extends StatefulWidget {
  const CatFeedPage({super.key});

  @override
  State<CatFeedPage> createState() => _CatFeedPageState();
}
int _bottomNavIndex = 0;

final List<IconData> iconList = [
  Icons.home_rounded,
  Icons.campaign,
  Icons.bookmark_border,
  Icons.public,
];

class _CatFeedPageState extends State<CatFeedPage> {
  final CollectionReference _catPosts =
      FirebaseFirestore.instance.collection('cat_posts');

  Map<String, String?> _selectedFilters = {
    'color': null,
    'fur_length': null,
    'location': null,
    'sort': 'recent',
  };

  void _openFilterSheet() async {
    final updatedFilters = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => CatFilterSheet(filters: _selectedFilters),
    );

    if (updatedFilters != null) {
      setState(() {
        _selectedFilters = updatedFilters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: offwhite,
      extendBody: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: gray),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                        ),
                      ),
                      const PawDropdown(),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Cats Near You bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // LEFT: Cats Near You box
                      Expanded(
                        child: Container(
                          height: 48, // controls height (match button)
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Report Feed",
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "ZTNature",
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10), // spacing between them

                      // RIGHT: Filter button (separate)
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: ElevatedButton(
                          onPressed: _openFilterSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: grayblue,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Feed
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _catPosts.orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Center(child: Text("Error loading feed"));
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      final posts = snapshot.data!.docs;
                      if (posts.isEmpty) return const Center(child: Text("No posts yet!"));

                      final filteredPosts = CatFilter.applyFilters(posts, _selectedFilters);
                      if (filteredPosts.isEmpty) return const Center(child: Text("No posts match the filter!"));

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final data = filteredPosts[index].data() as Map<String, dynamic>;
                          return PostCard(
                            postId: filteredPosts[index].id,
                            imageUrl: data['image_url'] ?? '',
                            caption: data['caption'] ?? '',
                            description: data['description'] ?? '',
                            color: data['color'] ?? 'Unknown',
                            furLength: data['fur_length'] ?? 'Unknown',
                            location: data['location'] ?? 'Unknown',
                            username: data['username'] ?? 'Anonymous',
                            userId: data['userId'] ?? '',
                            timestamp: data['timestamp'],
                            currentUserId: currentUser?.uid ?? '',

                            latitude: data['latitude'],
                            longitude: data['longitude'],
                            city: data['city'],
                            state: data['state'],

                            commentCount: 0,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // navigation bar along bottom
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            PostOptionsSheet.show(context);

          },
          backgroundColor: grayblue,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white)
        ),
        floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: _bottomNavIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.smoothEdge,
          backgroundColor: Colors.white,
          activeColor: grayblue,
          inactiveColor: gray,
          onTap: (index) {
            setState(() => _bottomNavIndex = index);
            switch (index){
              case 0:
                break;
              case 1:
                break;
              case 2:
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookmarkedPage()),
                  );
                }
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (_) => const MapPage(showAllPosts: true),
                  ),
                );
                break;
            }
          },
        ),
    );
  }
}

// PostCard Widget
class PostCard extends StatefulWidget {
  final String postId;
  final String imageUrl;
  final String caption;
  final String description;
  final String color;
  final String furLength;
  final String location;
  final String username;
  final String userId;
  final dynamic timestamp;
  final String currentUserId;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final int commentCount;

  const PostCard({
    super.key,
    required this.postId,
    required this.imageUrl,
    required this.caption,
    required this.description,
    required this.color,
    required this.furLength,
    required this.location,
    required this.username,
    required this.userId,
    this.timestamp,
    required this.currentUserId,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.commentCount,

  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isExpanded = false;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
  }

  void _checkIfBookmarked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(widget.postId)
        .get();

    setState(() {
      isBookmarked = doc.exists;
    });
  }
  void _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(widget.postId);

    if (isBookmarked) {
      await ref.delete();
    } else {
      await ref.set({
        'postId': widget.postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.timestamp != null
                                ? DateFormat('EEE, d MMM • h:mm a')
                                .format((widget.timestamp as Timestamp).toDate())
                                : "No time",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),

                      GestureDetector(
                        onTap: () {
                          if (widget.latitude != null &&
                              widget.longitude != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapPage(
                                  lat: widget.latitude!,
                                  lng: widget.longitude!,
                                  showAllPosts: false,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          (widget.city != null && widget.state != null)
                              ? "${widget.city}, ${widget.state}"
                              : "Unknown location",
                          style: const TextStyle(color: gray),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= MENU =================
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    final currentUser = FirebaseAuth.instance.currentUser;

                    if (value == 'delete') {
                      await FirebaseFirestore.instance
                          .collection('cat_posts')
                          .doc(widget.postId)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post deleted')),
                      );
                    } else if (value == 'report' && currentUser != null) {
                      await FirebaseFirestore.instance
                          .collection('reports')
                          .add({
                        'postId': widget.postId,
                        'image_url': widget.imageUrl,
                        'username': widget.username,
                        'reporterId': currentUser.uid,
                        'reason': 'Inappropriate content',
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted')),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    if (widget.userId == widget.currentUserId) {
                      return const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ];
                    } else {
                      return const [
                        PopupMenuItem(
                          value: 'report',
                          child: Text('Report'),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),
          ),

          // ================= IMAGE =================
          if (widget.imageUrl.isNotEmpty)
            if (widget.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.network(
                  widget.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

          // ================= CONTENT =================
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT SIDE → Comments
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 22,
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () {
                            // open comments
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return CommentsSheet(postId: widget.postId);
                              },
                            );
                          },
                        ),

                        // Show count only if > 0
                        if ((widget.commentCount ?? 0) > 0)
                          Text(
                            '${widget.commentCount}',
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),

                    // RIGHT SIDE: Bookmark
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 22,
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      ),
                        onPressed: _toggleBookmark,

                    ),
                  ],
                ),
                // TITLE + MORE
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.caption,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Text(
                        isExpanded ? "less" : "...more",
                        style: const TextStyle(
                          color: gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // EXPANDED DETAILS
                if (isExpanded) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text("Color: ${widget.color}"),
                      const SizedBox(width: 16),
                      Text("Fur: ${widget.furLength}"),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Additional Information: ${widget.description}"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
