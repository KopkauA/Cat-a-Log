import 'package:flutter/material.dart';
import 'register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home-page.dart';
import 'colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _message = '';

  // Login function
  void login() async {
    try {
      String input = _usernameController.text.trim();
      String email = input;

      // If user typed a username, find the email
      if (!input.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          setState(() => _message = "Username not found");
          return;
        }

        email = query.docs.first['email'];
      }

      // Now sign in with email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _message = "Login successful!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CatFeedPage()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _message = "Login failed: ${e.message}");
    }
  }

  Widget buildLoginCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Username input
          Stack(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                  labelText: "Username / Email",
                  labelStyle: const TextStyle(color: Colors.white),

                  filled: true,
                  fillColor: accents,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: Container(
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Password input
          Stack(
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),

                  filled: true,
                  fillColor: accents,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              //underline
              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: Container(
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Login button with shadow underneath
          FractionallySizedBox(
            widthFactor: 0.5,
            child: SizedBox(
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: shad,
                      blurRadius: 10,
                      offset: const Offset(0, 4), // shadow only under
                    ),
                  ],
                ),

                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: login,
                      borderRadius: BorderRadius.circular(30),
                      splashColor: Colors.black26,
                      highlightColor: Colors.black12,
                      child: Ink(
                        height: 50,
                        decoration: BoxDecoration(
                          color: chart,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              fontSize: 20,
                              color: shad,
                              letterSpacing: 1.2,
                              fontFamily: 'ZTNature',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Feedback message
          Text(
            _message,
            style: const TextStyle(
              color: chart,
              fontFamily: 'ZTNature',
            ),
          ),

          // Register link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text(
                "Need an account? Sign up here",
                style: TextStyle(
                  color: offwhite,
                  fontFamily: 'ZTNature',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grayblue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 120),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60, width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Let's get started!",
                      style: TextStyle(
                        fontSize: 28,
                        color: offwhite,
                        fontFamily: 'ZTNature',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: buildLoginCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
