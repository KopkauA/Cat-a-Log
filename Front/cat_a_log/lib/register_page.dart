import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home-page.dart';
import 'colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  String _message = '';

  // Register logic
  void register() async {
  final username = _usernameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (username.isEmpty || email.isEmpty || password.isEmpty) {
    setState(() => _message = "All fields are required");
    return;
  }

  try {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() => _message = "Username already taken");
      return;
    }
// Create user with email and password
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    String uid = userCredential.user!.uid;
// Store additional user info in Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _message = "Registration successful!");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CatFeedPage()),
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    setState(() => _message = "Registration failed: ${e.message}");
  } catch (e) {
    if (!mounted) return;
    setState(() => _message = "An unexpected error occurred: $e");
  }
}


  // Registration card widget
  Widget buildRegisterCard() {
    return Container(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Username input
          Stack(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                  labelText: "Username",
                  labelStyle: const TextStyle(color: Colors.white, fontFamily: 'ZTNature'),
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
            ]
          ),

          const SizedBox(height: 16),

          // Email input
          Stack(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Colors.white),
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white, fontFamily: 'ZTNature'),
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
            ]
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
                  labelStyle: const TextStyle(color: Colors.white, fontFamily: 'ZTNature'),
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
            ]
          ),
          const SizedBox(height: 20),

          // Register Button with shadow
          Center(
            child: FractionallySizedBox(
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
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: register,
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
                            "REGISTER",
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
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Feedback message
          Align(
            alignment: Alignment.center,
            child: Text(
              _message,
              style: const TextStyle(
                color: chart,
                fontFamily: 'ZTNature',
              ),
            ),
          ),

          // Login link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },

              child: const Text(
                "Already have an account? Log in here...",
                style: TextStyle(
                  color: Colors.white,
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 120),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(width: 30),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [

                      Text(
                        "Welcome to Cat-a-Log,",
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontFamily: 'ZTNature',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "create your account to get started!",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontFamily: 'ZTNature',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: buildRegisterCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}