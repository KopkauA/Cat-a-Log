import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import 'comments.dart';

import 'colors.dart';
import 'map_page.dart';
import 'post_options.dart';
import 'home-page.dart';

int _bottomNavIndex = 2;

final List<IconData> iconList = [
  Icons.home_rounded,
  Icons.campaign,
  Icons.bookmark_border,
  Icons.public,
];

class BookmarkedPage extends StatefulWidget {
  const BookmarkedPage({super.key});

  @override
  State<BookmarkedPage> createState() => _BookmarkedPageState();
}

class _BookmarkedPageState extends State<BookmarkedPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: offwhite,
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP BAR =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: const [
                  Text(
                    "Bookmarked Posts",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ================= BOOKMARK FEED =================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('bookmarks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading bookmarks"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookmarks = snapshot.data!.docs;

                  if (bookmarks.isEmpty) {
                    return const Center(
                      child: Text("No bookmarked posts yet"),
                    );
                  }

                  // get post IDs
                  final postIds = bookmarks.map((e) => e.id).toList();

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cat_posts')
                        .where(FieldPath.documentId, whereIn: postIds)
                        .snapshots(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.hasError) {
                        return const Center(child: Text("Error loading posts"));
                      }

                      if (!postSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = postSnapshot.data!.docs;

                      if (posts.isEmpty) {
                        return const Center(
                          child: Text("No saved posts found"),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final data =
                          posts[index].data() as Map<String, dynamic>;

                          return PostCard(
                            postId: posts[index].id,
                            imageUrl: data['image_url'] ?? '',
                            caption: data['caption'] ?? '',
                            description: data['description'] ?? '',
                            color: data['color'] ?? 'Unknown',
                            furLength: data['fur_length'] ?? 'Unknown',
                            location: data['location'] ?? 'Unknown',
                            username: data['username'] ?? 'Anonymous',
                            userId: data['userId'] ?? '',
                            timestamp: data['timestamp'],
                            currentUserId: user!.uid,
                            latitude: data['latitude'],
                            longitude: data['longitude'],
                            city: data['city'],
                            state: data['state'],
                            commentCount: 0,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
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
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CatFeedPage()),
                );
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

